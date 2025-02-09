// ContentView.swift
import SwiftUI


struct ContentView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @StateObject private var viewModel: PracticeSessionViewModel
    @State private var selectedBagType: String? = UserDefaults.standard.lastSelectedBagType
    
    private var bagTypes: [String] {
        UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
    }
    
    init() {
        let context = PersistenceController.shared.container.viewContext
        _viewModel = StateObject(wrappedValue: PracticeSessionViewModel(context: context))
    }
    
    var body: some View {
        VStack(spacing: 20) {
            if viewModel.sessionState == .ready {
                // New Session View
                VStack(spacing: 20) {
                    Text("Ready to Practice?")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    // Bag Type Picker
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Default Bag:")
                            .font(.headline)
                        
                        Picker("Default Bag", selection: $selectedBagType) {
                            Text(UserDefaults.standard.string(forKey: "DefaultBagType") ?? "No Default Bag")
                                .tag(UserDefaults.standard.string(forKey: "DefaultBagType"))
                            
                            ForEach(bagTypes, id: \.self) { bagType in
                                Text(bagType).tag(bagType)
                            }
                        }
                        .pickerStyle(MenuPickerStyle())
                        .padding(.vertical, 8)
                        .onChange(of: selectedBagType) { _, newValue in
                            // Update the default bag type in UserDefaults when selection changes
                            UserDefaults.standard.set(newValue, forKey: "DefaultBagType")
                        }
                        .onAppear {
                            selectedBagType = UserDefaults.standard.string(forKey: "DefaultBagType")
                        }
                    }
                    .padding()
                    .background(Color.blue.opacity(0.1))
                    .cornerRadius(10)
                    
                    Button(action: {
                        if let bagType = selectedBagType {
                            UserDefaults.standard.lastSelectedBagType = bagType
                            viewModel.setupNewSession()  // Only setup new session, don't save
                        }
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Start New Session")
                        }
                        .foregroundColor(.white)
                        .padding()
                        .background(selectedBagType == nil ? Color.gray : Color.blue)
                        .cornerRadius(10)
                    }
                    .disabled(selectedBagType == nil)
                }
            } else {
                    // Active or Completed Session View
                    VStack(spacing: 20) {
                        // PPR Display
                        PPRCard(ppr: viewModel.currentPPR)
                        
                        if viewModel.sessionState == .inProgress {
                            // Current Round Display
                            RoundTracker(
                                currentRound: viewModel.currentRound,
                                currentThrow: viewModel.currentThrow,
                                onThrow: viewModel.recordThrow,
                                onUndo: viewModel.undoLastThrow    // Add this line
                            )
                        }
                        
                        // Rounds Summary
                        RoundsSummary(rounds: viewModel.rounds)
                        
                        // Session Complete Actions
                        // Session Complete Actions
                        if viewModel.sessionState == .completed {
                            SessionCompleteButtons(
                                onSave: { _ in viewModel.saveSession(bagType: selectedBagType ?? "") },
                                onDiscard: { viewModel.setupNewSession() },
                                bagType: selectedBagType ?? ""
                            )
                        }
                                                
                        Spacer()
                                            } // Close VStack
                                        } // Close else
                                    } // Close outer VStack
                                    .padding()
                                    .navigationTitle("Practice Session")
                                    .toolbar {
                                        ToolbarItem(placement: .principal) {
                                            VStack(spacing: 4) {
                                                Text("Practice Session")
                                                    .font(.headline)
                                                
                                                Text(UserDefaults.standard.string(forKey: "DefaultBagType") ?? "No Default Bag")
                                                    .font(.subheadline)
                                                    .fontWeight(.semibold)
                                                    .foregroundColor(.blue)
                                                    .padding(4)
                                                    .background(Color.blue.opacity(0.1))
                                                    .cornerRadius(5)
                                            }
                                        }
                                    }
                            } // Close body
                        } // Close ContentView

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
