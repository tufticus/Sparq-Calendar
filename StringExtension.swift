//
//  StringExtension.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 8/3/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation

func < (lhs: String, rhs: String) -> Bool {
    let result = compare(lhs,rhs)
    
    if result == -1 {
        return true
    }
    
        return false
}
    
func <= (lhs: String, rhs: String) -> Bool {
    let result = compare(lhs,rhs)
    
    if result == -1 || result == 0 {
        return true
    }
    
        return false
}
    
func > (lhs: String, rhs: String) -> Bool {
    let result = compare(lhs,rhs)
    
    if result == 1 {
        return true
    }
    
        return false
}
    
func >= (lhs: String, rhs:String) -> Bool {
    let result = compare(lhs,rhs)
    
    if result == 1 || result == 0 {
        return true
    }
    
        return false
}

func compare(lhs: String, rhs: String) -> Int {
    let lSize = count(lhs)
    let rSize = count(rhs)
    let len = lSize < rSize ? lSize : rSize
    
    for i in 0...len {
        if lhs[i] < rhs[i] {
            return -1
        } else if lhs[i] > rhs[i] {
            return 1
        }
    }
    
    return lSize - rSize
}

extension String {
    
    subscript (i: Int) -> Character {
        return self[advance(self.startIndex,i)] as Character
    }
    
//    subscript (i: Int) -> String {
//        return String(self[i] as Character)
//    }
    
    subscript (r: Range<Int>) -> String {
        return substringWithRange(Range(start: advance(startIndex, r.startIndex), end: advance(startIndex, r.endIndex)))
    }
}
