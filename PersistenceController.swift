// PersistenceController.swift - Create this new file
import CoreData

struct PersistenceController {
    static let shared = PersistenceController()
    
    let container: NSPersistentContainer
    
    init() {
        container = NSPersistentContainer(name: "CornholePractice")
        
        container.loadPersistentStores { description, error in
            if let error = error {
                // More detailed error logging
                fatalError("Core Data store failed to load with error: \(error.localizedDescription)")
            }
        }
        
        // Add these configurations
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }
    
    // Add a helper method to save context
    func save() {
        let context = container.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

