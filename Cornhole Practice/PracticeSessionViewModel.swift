import SwiftUI
import CoreData

class PracticeSessionViewModel: ObservableObject {
    enum SessionState {
        case inProgress
        case completed
        case review
        case ready
    }
    
    @Published var rounds: [Round] = []
    @Published var currentRound = 1
    @Published var currentThrow = 1
    @Published var sessionState: SessionState = .inProgress
    @Published var throwHistory: [(round: Int, throwNumber: Int, result: ThrowResult)] = []
    @Published var defaultBagType: String
    @Published var defaultThrowingStyle: String
    
    let viewContext: NSManagedObjectContext
    
    init(context: NSManagedObjectContext) {
        self.viewContext = context
        self.defaultBagType = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultBagType) ?? "Default"
        self.defaultThrowingStyle = UserDefaults.standard.string(forKey: AppConstants.UserDefaultsKeys.defaultThrowingStyle) ?? "Default"
        
        // Move setupNewSession() AFTER all properties are initialized
        setupNewSession()
    }
    
    var isSessionComplete: Bool { currentRound > 10 }
    
    var currentPPR: Double {
         let completedRounds = rounds.filter { $0.bagThrows.count == 4 }
         guard !completedRounds.isEmpty else { return 0 }
         let totalPoints = completedRounds.reduce(0) { $0 + $1.roundScore }
         return Double(totalPoints) / Double(completedRounds.count)
     }
    
    func setupNewSession() {
        rounds = (1...10).map { Round(id: UUID(), roundNumber: $0, bagThrows: []) }
        currentRound = 1
        currentThrow = 1
        sessionState = .inProgress
    }
    
    func recordThrow(_ result: ThrowResult) {
        guard currentRound <= 10 && currentThrow <= 4 else { return }
        
        // Record the current state before making changes
        throwHistory.append((round: currentRound, throwNumber: currentThrow, result: result))
            
        let bagThrow = BagThrow(id: UUID(), throwNumber: currentThrow, result: result)
        rounds[currentRound - 1].bagThrows.append(bagThrow)
        
        if currentThrow == 4 {
            currentThrow = 1
            currentRound += 1
            
            if currentRound > 10 {
                sessionState = .review // Fixed from .inProgress
            }
        } else {
            currentThrow += 1
        }
        
        objectWillChange.send()
    }
    
    func undoLastThrow() {
        guard let lastThrow = throwHistory.last else { return }
        
        // Remove the last throw from history
        throwHistory.removeLast()
        
        // Remove the last throw from the rounds
        rounds[lastThrow.round - 1].bagThrows.removeLast()
        
        // Reset the current round and throw number
        currentRound = lastThrow.round
        currentThrow = lastThrow.throwNumber
        
        if sessionState == .review {
            sessionState = .inProgress
        }
        
        objectWillChange.send()
    }
    
    func saveSession() { // Updated to remove parameters
        let savedSession = SavedPracticeSession(context: viewContext)
        savedSession.iD = UUID()
        savedSession.date = Date()
        savedSession.pointsPerRound = currentPPR
        savedSession.totalBagsInHole = Int16(rounds.reduce(0) { $0 + $1.totalInHole })
        savedSession.bagsOnBoard = Int16(rounds.reduce(0) { $0 + $1.totalOnBoard })
        savedSession.bagsOffBoard = Int16(rounds.reduce(0) { $0 + $1.totalMiss })
        savedSession.bagType = defaultBagType // Use the view model's properties
        savedSession.throwingStyle = defaultThrowingStyle // Use the view model's properties
        print("Saving session with bag type: \(defaultBagType)")
        
        let fourBaggerRounds = rounds.filter { round in
            round.bagThrows.count == 4 && round.bagThrows.allSatisfy { $0.result == .inHole }
        }
        savedSession.fourBaggers = Int16(fourBaggerRounds.count)
        
        do {
            try viewContext.save()
            print("Session saved successfully")
        } catch {
            print("Error saving session: \(error)")
        }
        
        sessionState = .ready
    }
    
    func finalizeSession() {
        sessionState = .completed
    }
}
