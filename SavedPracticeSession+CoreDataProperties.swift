//
//  SavedPracticeSession+CoreDataProperties.swift
//  Cornhole Practice
//
//  Created by Robert Thompson on 2/8/25.
//
//

import Foundation
import CoreData


extension SavedPracticeSession {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SavedPracticeSession> {
        return NSFetchRequest<SavedPracticeSession>(entityName: "SavedPracticeSession")
    }

    @NSManaged public var bagsOffBoard: Int16
    @NSManaged public var bagsOnBoard: Int16
    @NSManaged public var date: Date?
    @NSManaged public var fourBaggers: Int16
    @NSManaged public var iD: UUID?
    @NSManaged public var pointsPerRound: Double
    @NSManaged public var totalBagsInHole: Int16
    @NSManaged public var bagType: String?
    @NSManaged public var throwingStyle: String?

}

extension SavedPracticeSession : Identifiable {

}
