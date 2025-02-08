import SwiftUI
import CoreData

struct SessionHistoryView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \SavedPracticeSession.date, ascending: false)],
        animation: .default)
    private var sessions: FetchedResults<SavedPracticeSession>
    
    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MM/dd/yy"
        return formatter
    }()
    
    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("Date")
                        .frame(width: 70, alignment: .leading)
                    Text("PPR")
                        .frame(width: 50, alignment: .center)
                    Text("InH")
                        .frame(width: 40, alignment: .center)
                    Text("OnB")
                        .frame(width: 40, alignment: .center)
                    Text("Off")
                        .frame(width: 40, alignment: .center)
                    Text("4B")
                        .frame(width: 40, alignment: .center)
                }
                .font(.caption)
                .foregroundColor(.secondary)
            ) {
                ForEach(sessions, id: \.self) { session in
                    HStack {
                        if let sessionDate = session.date {
                            Text(dateFormatter.string(from: sessionDate))
                                .frame(width: 70, alignment: .leading)
                        } else {
                            Text("No Date")
                                .frame(width: 70, alignment: .leading)
                        }
                        
                        Text(String(format: "%.1f", session.pointsPerRound))
                            .frame(width: 50, alignment: .center)
                        
                        let total = session.totalBagsInHole + session.bagsOnBoard + session.bagsOffBoard
                        
                        Text(calculatePercentage(session.totalBagsInHole, total: total))
                            .frame(width: 40, alignment: .center)
                            .foregroundColor(.green)
                        
                        Text(calculatePercentage(session.bagsOnBoard, total: total))
                            .frame(width: 40, alignment: .center)
                            .foregroundColor(.blue)
                        
                        Text(calculatePercentage(session.bagsOffBoard, total: total))
                            .frame(width: 40, alignment: .center)
                            .foregroundColor(.red)
                        
                        Text("\(session.fourBaggers)")
                            .frame(width: 40, alignment: .center)
                    }
                    .font(.caption)
                }
                .onDelete(perform: deleteSessions)
            }
        }
        .navigationTitle("Practice History")
    }
    
    private func calculatePercentage(_ value: Int16, total: Int16) -> String {
        guard total > 0 else { return "0%" }
        let percentage = (Double(value) / Double(total)) * 100
        return String(format: "%.0f%%", percentage)
    }

    private func deleteSessions(offsets: IndexSet) {
        withAnimation {
            offsets.map { sessions[$0] }.forEach(viewContext.delete)
            
            do {
                try viewContext.save()
            } catch {
                print("Error saving session: \(error)")
            }
        }
    }
    } 
