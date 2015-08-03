//
//  Classes.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/20/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation
import CoreData

@objc(Classes)
class Classes: NSManagedObject {

    @NSManaged var classID: NSNumber
    @NSManaged var grade: NSNumber
    @NSManaged var section: String
    @NSManaged var subject: String
    @NSManaged var teacherEmail: String
    @NSManaged var teacherName: String
    @NSManaged var classLInk: ClassMeetings

}
