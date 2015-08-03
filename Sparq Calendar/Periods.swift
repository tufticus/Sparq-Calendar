//
//  Periods.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/20/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation
import CoreData

@objc(Periods)
class Periods: NSManagedObject {

    @NSManaged var number: NSNumber
    @NSManaged var periodID: NSNumber
    @NSManaged var startTime: NSDate
    @NSManaged var stopTime: NSDate
    @NSManaged var periodLink: ClassMeetings

}
