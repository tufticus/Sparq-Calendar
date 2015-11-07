//
//  RestApiManager.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/13/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import Foundation

typealias ServiceResponse = (JSON,NSError?) -> Void

class RestApiManager: NSObject {
    
    static let sharedInstance = RestApiManager();
    
    let baseURL = "http://dev-a.baconlove.club/Sparq"
    
    func login(email: String, password: String, onCompletion: (JSON) -> Void ) {
        let request = baseURL + "/user?email=" + email + "&password=" + password
        
        
        makeHTTPGetRequest(request, onCompletion: {json, error -> Void in
            onCompletion(json)
        })
    }
    
    func checkVersion(version: Int, scheduleID: Int, onCompletion: (JSON) -> Void ) {
        let request = baseURL + "/schedule/version/\(version)?scheduleID=\(scheduleID)"
        
        makeHTTPGetRequest(request, onCompletion: {json, error -> Void in
            onCompletion(json)
        })
    }
    
    func getSchedule(userID: Int, onCompletion: (JSON) -> Void ) {
        let request = baseURL + "/schedule/\(userID)"
        
        makeHTTPGetRequest(request, onCompletion: {json, error -> Void in
            onCompletion(json)
        })
    }
    
    func registerUser(email: String, password: String, onCompletion: (JSON) -> Void ) {
        let request = baseURL + "/user"
        let body = "email=" + email + "&password=" + password
        
        makeHTTPPostRequest(request, body: body, onCompletion: {json, error -> Void in
            onCompletion(json)
        })
    }
    
    func makeHTTPGetRequest(path: String, onCompletion: ServiceResponse) {
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error in
            let json:JSON  = JSON(data: data)
            
            onCompletion(json,error)
        })
        
        task.resume()
    }
    
    func makeHTTPPostRequest(path: String, body: String, onCompletion: ServiceResponse) {
        var err: NSError?
        let request = NSMutableURLRequest(URL: NSURL(string: path)!)
        
        // Set the method to POST
        request.HTTPMethod = "POST"
        
        // Set the POST body for the request
        request.HTTPBody = body.dataUsingEncoding(NSUTF8StringEncoding)
        let session = NSURLSession.sharedSession()
        
        let task = session.dataTaskWithRequest(request, completionHandler: {data, response, error -> Void in
            let json:JSON = JSON(data: data)
            onCompletion(json, err)
        })
        task.resume()
    }
}