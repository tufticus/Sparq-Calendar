//
//  ViewController.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 6/18/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    let gl = CAGradientLayer()

    @IBOutlet weak var errorText: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var troubleButton: UIButton!
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
    
        errorText.hidden = true
        
        // background setup
        // #3DFCBC
        let left = UIColor(red: 61/255.0, green: 252/255.0, blue: 189/255.0, alpha: 1.0)
        // #1279bd
        let right = UIColor(red: 18/255.0, green: 121/255.0, blue: 189/255.0, alpha: 1.0).CGColor as CGColorRef
        
        // 2
        gl.frame = self.view.bounds
        
        gl.colors = [left, right]
        gl.locations = [0.0,1.0]
    }

    @IBAction func loginPressed(sender: AnyObject) {
        
        let username = usernameField.text
        let password = passwordField.text
        
        if username != nil && !username.isEmpty {
            
        } else {
            
            return
        }
        
        if password != nil && !password.isEmpty {
            
        } else {
            
            return
        }
        
        // make login call
    }

    @IBAction func troublePressed(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(NSURL(string:"http://www.sparqcalendar.com/recover")!)
    }

}

