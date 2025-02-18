import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<SavedPracticeSession>
    
    enum PickerType {
        case bagType
        case throwingStyle
    }
    
    // New Identifiable struct to wrap session and picker type
    struct EditSession: Identifiable {
        let id: NSManagedObjectID // Unique identifier from Core Data
        let session: SavedPracticeSession
        let pickerType: PickerType
        
        init(session: SavedPracticeSession, pickerType: PickerType) {
            self.id = session.objectID
            self.session = session
            self.pickerType = pickerType
        }
    }
    
    @State private var editSession: EditSession? // Updated to use the new struct
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    
    var body: some View {
        ScrollView(.horizontal) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Date").frame(width: 52, alignment: .leading)
                    Text("PPR").frame(width: 42, alignment: .center).padding(.trailing, 6)
                    Text("InH").frame(width: 30, alignment: .center).padding(.trailing, 6)
                    Text("OnB").frame(width: 30, alignment: .center).padding(.trailing, 6)
                    Text("Off").frame(width: 30, alignment: .center).padding(.trailing, 6)
                    Text("4B").frame(width: 30, alignment: .center).padding(.trailing, 6)
                    Text("Bag").frame(width: 90, alignment: .leading)
                    Text("Style").frame(width: 90, alignment: .leading)
                }
                .font(.caption)
                .foregroundColor(.secondary)
                .padding(.horizontal)
                .background(Color(.systemGray6))
                
                Divider()
                
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 8) {
                        ForEach(sessions, id: \.self) { session in
                            SessionRow(session: session)
                                .contextMenu {
                                    Button("Delete") {
                                        deleteSession(session)
                                    }
                                    Button("Edit Bag Type") {
                                        editSession = EditSession(session: session, pickerType: .bagType)
                                    }
                                    Button("Edit Throwing Style") {
                                        editSession = EditSession(session: session, pickerType: .throwingStyle)
                                    }
                                }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
        .navigationTitle("Practice History")
        .sheet(item: $editSession) { editSession in
            PickerContainerView(
                session: editSession.session,
                pickerType: editSession.pickerType,
                viewContext: viewContext,
                onDismiss: { self.editSession = nil }
            )
        }
    }
    
    private func deleteSession(_ session: SavedPracticeSession) {
        viewContext.delete(session)
        do {
            try viewContext.save()
        } catch {
            print("Error deleting session: \(error)")
        }
    }
}

struct SessionRow: View {
    let session: SavedPracticeSession
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    
    var body: some View {
        HStack {
            if let sessionDate = session.date {
                Text(dateFormatter.string(from: sessionDate))
                    .frame(width: 52, alignment: .leading)
            } else {
                Text("No Date")
                    .frame(width: 70, alignment: .leading)
            }
            
            Text(String(format: "%.1f", session.pointsPerRound))
                .frame(width: 42, alignment: .center)
                .padding(.trailing, 6)
            
            let total = session.totalBagsInHole + session.bagsOnBoard + session.bagsOffBoard
            
            Text(calculatePercentage(session.totalBagsInHole, total: total))
                .frame(width: 30, alignment: .center)
                .foregroundColor(.green)
                .padding(.trailing, 6)
            
            Text(calculatePercentage(session.bagsOnBoard, total: total))
                .frame(width: 30, alignment: .center)
                .foregroundColor(.blue)
                .padding(.trailing, 6)
            
            Text(calculatePercentage(session.bagsOffBoard, total: total))
                .frame(width: 30, alignment: .center)
                .foregroundColor(.red)
                .padding(.trailing, 6)
            
            Text("\(session.fourBaggers)")
                .frame(width: 30, alignment: .center)
                .padding(.trailing, 6)
            
            Text(session.bagType ?? "N/A")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(.secondary)
            
            Text(session.throwingStyle ?? "N/A")
                .frame(width: 90, alignment: .leading)
                .foregroundColor(.secondary)
        }
        .font(.caption)
        .frame(height: 25)
    }
    
    private func calculatePercentage(_ value: Int16, total: Int16) -> String {
        guard total > 0 else { return "0%" }
        let percentage = (Double(value) / Double(total)) * 100
        return String(format: "%.0f%%", percentage)
    }
}

struct PickerContainerView: View {
    let session: SavedPracticeSession
    let pickerType: SessionHistoryView.PickerType
    let viewContext: NSManagedObjectContext
    let onDismiss: () -> Void
    
    var body: some View {
        switch pickerType {
        case .bagType:
            BagTypePickerView(
                session: session,
                onDismiss: onDismiss,
                viewContext: viewContext
            )
        case .throwingStyle:
            ThrowingStylePickerView(
                session: session,
                onDismiss: onDismiss,
                viewContext: viewContext
            )
        }
    }
}

struct BagTypePickerView: View {
    let session: SavedPracticeSession
    let onDismiss: () -> Void
    let viewContext: NSManagedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    private var bagTypes: [String] {
        UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(bagTypes, id: \.self) { bagType in
                    HStack {
                        Text(bagType)
                        Spacer()
                        if bagType == session.bagType {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        updateBagType(to: bagType)
                    }
                }
            }
            .navigationTitle("Select Bag Type")
            .navigationBarItems(
                trailing: Button("Done") {
                    onDismiss()
                    dismiss()
                }
            )
        }
    }
    
    private func updateBagType(to newType: String) {
        session.bagType = newType
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating bag type: \(error)")
        }
    }
}

struct ThrowingStylePickerView: View {
    let session: SavedPracticeSession
    let onDismiss: () -> Void
    let viewContext: NSManagedObjectContext
    @Environment(\.dismiss) private var dismiss
    
    private var throwingStyles: [String] {
        UserDefaults.standard.stringArray(forKey: "ThrowingStyles") ?? []
    }
    
    var body: some View {
        NavigationView {
            List {
                ForEach(throwingStyles, id: \.self) { style in
                    HStack {
                        Text(style)
                        Spacer()
                        if style == session.throwingStyle {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        updateThrowingStyle(to: style)
                    }
                }
            }
            .navigationTitle("Select Throwing Style")
            .navigationBarItems(
                trailing: Button("Done") {
                    onDismiss()
                    dismiss()
                }
            )
        }
    }
    
    private func updateThrowingStyle(to newStyle: String) {
        session.throwingStyle = newStyle
        
        do {
            try viewContext.save()
        } catch {
            print("Error updating throwing style: \(error)")
        }
    }
}
