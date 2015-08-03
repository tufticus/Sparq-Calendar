//
//  Days.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/20/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation
import CoreData

@objc(Days)
class Days: NSManagedObject {

    @NSManaged var dayID: NSNumber
    @NSManaged var name: String
    @NSManaged var number: NSNumber
    @NSManaged var dayLink: ClassMeetings

}
