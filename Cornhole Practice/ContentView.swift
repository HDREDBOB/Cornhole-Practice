// ContentView.swift
import SwiftUI


// Constants to centralize configuration
enum AppConstants {
    enum UserDefaultsKeys {
        static let bagTypes = "CornholeBagTypes"
        static let defaultBagType = "DefaultBagType"
    }
}

// Custom View Modifiers
struct BlueSoftBackground: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
    }
}

extension View {
    func blueSoftBackground() -> some View {
        modifier(BlueSoftBackground())
    }
}

struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: PracticeSessionViewModel
    @State private var selectedBagType: String = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultBagType) ?? ""
    @State private var toolbarRefresh: Bool = false
    
    private var bagTypes: [String] {
        UserDefaults.standard.stringArray(forKey: AppConstants.UserDefaultsKeys.bagTypes) ?? []
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeSessionViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            switch viewModel.sessionState {
            case .ready:
                readySessionView
            case .inProgress:
                if viewModel.currentRound > 10 {
                    finalReviewView
                        .navigationTitle("Session Summary")
                } else {
                    inProgressSessionView
                }
            case .completed:
                completedSessionView
            }
        }
        .padding()
        .navigationTitle(viewModel.currentRound > 10 ? "Session Summary" : "Practice Session")
        .toolbar { sessionToolbar }
    }
    private var finalReviewView: some View {
        VStack(spacing: 20) {
            PPRCard(ppr: viewModel.currentPPR)
            RoundsSummary(rounds: viewModel.rounds)
            
            HStack(spacing: 20) {
                Button(action: { viewModel.undoLastThrow() }) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                }
                
                Button(action: { viewModel.saveSession(bagType: defaultBagType) }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Button(action: { viewModel.setupNewSession() }) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
    }

    private var readySessionView: some View {
        VStack(spacing: 20) {
            Text("Ready to Practice?")
                .font(.title)
                .fontWeight(.bold)
            
            bagSelectionView
            
            startSessionButton
        }
    }
    
    private var bagSelectionView: some View {
            VStack(alignment: .leading, spacing: 10) {
                Text("Default Bag:")
                    .font(.headline)
                
                Picker("Default Bag", selection: $selectedBagType) {
                    ForEach(bagTypes, id: \.self) { bagType in
                        Text(bagType).tag(bagType)
                    }
                }
                .onChange(of: selectedBagType) { oldValue, newValue in
                    UserDefaults.standard.set(newValue, forKey: AppConstants.UserDefaultsKeys.defaultBagType)
                    toolbarRefresh.toggle()  // Add this line
                }
                .pickerStyle(MenuPickerStyle())
                .padding(.vertical, 8)
            }
            .blueSoftBackground()
            .onAppear {
                selectedBagType = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultBagType) ?? ""
            }
        }
    
    private var startSessionButton: some View {
        Button(action: {
            viewModel.setupNewSession()
        }) {
            HStack {
                Image(systemName: "plus.circle.fill")
                Text("Start New Session")
            }
            .foregroundColor(.white)
            .padding()
            .background(defaultBagSelected ? Color.blue : Color.gray)
            .cornerRadius(10)
        }
        .disabled(!defaultBagSelected)
    }
    
    private var defaultBagSelected: Bool {
        UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultBagType) != nil
    }
    
    private var inProgressSessionView: some View {
        VStack(spacing: 20) {
            PPRCard(ppr: viewModel.currentPPR)
            
            RoundTracker(
                currentRound: viewModel.currentRound,
                currentThrow: viewModel.currentThrow,
                onThrow: viewModel.recordThrow,
                onUndo: viewModel.undoLastThrow
            )
            
            RoundsSummary(rounds: viewModel.rounds)
            
            Spacer()
        }
    }
    
    private var completedSessionView: some View {
        SessionCompleteButtons(
            onSave: { bagType in
                viewModel.saveSession(bagType: defaultBagType)
            },
            onDiscard: { viewModel.setupNewSession() },
            bagType: defaultBagType
        )
    }
    
    private var defaultBagType: String {
        UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultBagType) ?? "No Default Bags Selected"
    }
    
    private var sessionToolbar: some ToolbarContent {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 4) {
                    Text(viewModel.currentRound > 10 ? "Session Summary" : "Practice Session")
                        .font(.headline)
                    
                    Text(defaultBagType)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                        .foregroundColor(.blue)
                        .padding(4)
                        .background(Color.blue.opacity(0.1))
                        .cornerRadius(5)
                }
                .id(toolbarRefresh)  // Add this line
            }
        }
    }

// Existing other structs (PPRCard, RoundTracker, etc.) remain the same

struct PPRCard: View {
    let ppr: Double
    
    var body: some View {
        VStack {
            Text("Points Per Round (PPR)")
                .font(.headline)
            Text(String(format: "%.2f", ppr))
                .font(.system(size: 36, weight: .bold))
                .foregroundColor(.blue)
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(10)
    }
}

struct RoundTracker: View {
    let currentRound: Int
    let currentThrow: Int
    let onThrow: (ThrowResult) -> Void
    let onUndo: () -> Void  // Add this line
    
    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Text("Round \(currentRound) - Throw \(currentThrow)")
                    .font(.headline)
                
                Spacer()
                
                Button(action: onUndo) {
                    HStack {
                        Image(systemName: "arrow.uturn.backward")
                        Text("Undo")
                    }
                    .foregroundColor(.orange)
                }
                .disabled(currentRound == 1 && currentThrow == 1)
            }
            
            HStack(spacing: 12) {
                ThrowButton(title: "In Hole (3pts)", color: .green, action: {
                    onThrow(.inHole)
                })
                
                ThrowButton(title: "On Board (1pt)", color: .blue, action: {
                    onThrow(.onBoard)
                })
                
                ThrowButton(title: "Miss (0pts)", color: .red, action: {
                    onThrow(.miss)
                })
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(radius: 2)
    }
}
struct ThrowButton: View {
    let title: String
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .foregroundColor(.white)
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(color)
                .cornerRadius(8)
        }
    }
}

struct RoundsSummary: View {
    let rounds: [Round]
    
    var body: some View {
        List {
            Section(header:
                HStack {
                    Text("Rnd")
                        .frame(width: 50, alignment: .leading)
                    Text("Pts")
                        .frame(width: 50, alignment: .center)
                    Text("InH")
                        .frame(width: 50, alignment: .center)
                    Text("OnB")
                        .frame(width: 50, alignment: .center)
                    Text("Off")
                        .frame(width: 50, alignment: .center)
                }
                .font(.system(size: 16))
                .foregroundColor(.secondary)
            ) {
                ForEach(rounds) { round in
                    HStack {
                        Text("\(round.roundNumber)")
                            .frame(width: 50, alignment: .leading)
                        
                        Text("\(round.roundScore)")
                            .frame(width: 50, alignment: .center)
                        
                        Text("\(round.totalInHole)")
                            .frame(width: 50, alignment: .center)
                            .foregroundColor(.green)
                        
                        Text("\(round.totalOnBoard)")
                            .frame(width: 50, alignment: .center)
                            .foregroundColor(.blue)
                        
                        Text("\(round.totalMiss)")
                            .frame(width: 50, alignment: .center)
                            .foregroundColor(.red)
                    }
                    .font(.system(size: 16))
                }
            }
        }
        .listStyle(PlainListStyle())
    }
}
struct StatView: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 4) {
            Text(label)
            Text("\(value)")
                .foregroundColor(color)
        }
    }
}

struct SessionCompleteButtons: View {
    let onSave: (String) -> Void
    let onDiscard: () -> Void
    let bagType: String  // Now we pass in the selected bag type
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Session Complete!")
                .font(.headline)
                .padding(.bottom)
            
            HStack(spacing: 20) {
                Button(action: { onSave(bagType) }) {
                    HStack {
                        Image(systemName: "square.and.arrow.down")
                        Text("Save Session")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 140)
                    .background(Color.blue)
                    .cornerRadius(10)
                }
                
                Button(action: onDiscard) {
                    HStack {
                        Image(systemName: "trash")
                        Text("Discard")
                    }
                    .foregroundColor(.white)
                    .padding()
                    .frame(minWidth: 140)
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(15)
        .shadow(radius: 2)
    }
}
// Model.swift
struct PracticeSession: Codable, Identifiable {
    let id: UUID
    let date: Date
    var rounds: [Round]
    var notes: String
    
    var pointsPerRound: Double {
        let totalPoints = rounds.reduce(0) { $0 + $1.roundScore }
        return Double(totalPoints) / Double(rounds.count)
    }
}

struct Round: Codable, Identifiable {
    let id: UUID
    let roundNumber: Int
    var bagThrows: [BagThrow]
    
    var totalInHole: Int { bagThrows.filter { $0.result == .inHole }.count }
    var totalOnBoard: Int { bagThrows.filter { $0.result == .onBoard }.count }
    var totalMiss: Int { bagThrows.filter { $0.result == .miss }.count }
    
    var roundScore: Int {
        (totalInHole * 3) + (totalOnBoard * 1)
    }
}

struct BagThrow: Codable, Identifiable {
    let id: UUID
    let throwNumber: Int
    let result: ThrowResult
}

enum ThrowResult: String, Codable {
    case inHole = "in_hole"
    case onBoard = "on_board"
    case miss = "miss"
}

// Preview Provider
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
