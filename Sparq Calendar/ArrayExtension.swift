//
//  ArrayExtension.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 8/6/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation

extension Array {
    var last: T {
        return self[self.endIndex - 1]
    }
}