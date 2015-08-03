

import UIKit
import Foundation




var dateFormatter = NSDateFormatter()
var timeFormatter = NSDateFormatter()
var todFormatter = NSDateFormatter()

var user  = User()
var classes = [ClassMeetings]()
var days = [String]()
var holidays = Dictionary<String,String>()
var schedule = Schedule()

var databasePath = ""


class LoginViewController: UIViewController, UIApplicationDelegate {
    let gl = CAGradientLayer()
    
    @IBOutlet weak var errorText: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var troubleButton: UIButton!
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorText.hidden = true
        
        // Do any additional setup after loading the view, typically from a nib.
        let filemgr = NSFileManager.defaultManager()
        let dirPaths =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
            .UserDomainMask, true)
        
        let docsDir = dirPaths[0] as! String
        
        databasePath = docsDir.stringByAppendingPathComponent(
            "sparq.db")
        
        let loginStored = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
        
        // check server version to sync the data
        if loginStored {
            
            let sparqDB = FMDatabase(path: databasePath as String)
            
            if sparqDB == nil {
                println("Error: \(sparqDB.lastErrorMessage())")
            }
            
            var version = 0
            if sparqDB.open() {
                var stmt = "SELECT version from Schedules LIMIT 1"
                
                // put into DB
                let results:FMResultSet? = sparqDB.executeQuery(stmt,
                    withArgumentsInArray: nil)
                
                if results?.next() == true {
                    version = Int(results!.intForColumn("version"))
                } else {
                    println("error getting schedules")
                }
             
                sparqDB.close()
            }
            
            
            RestApiManager.sharedInstance.checkVersion(version, onCompletion: { json -> Void in
                
                if json["version"] == "current" {
                    self.loginSegue()
                } else { // grab the schedule again
                    
                    let sparqDB = FMDatabase(path: databasePath as String)
                    
                    if sparqDB == nil {
                        println("Error: \(sparqDB.lastErrorMessage())")
                    }
                    
                    var userID = 0
                    if sparqDB.open() {
                        var stmt = "SELECT userID from Users LIMIT 1"
                        
                        // delete old data first!
                        // TODO
                        
                        // put into DB
                        let results:FMResultSet? = sparqDB.executeQuery(stmt,
                            withArgumentsInArray: nil)
                        
                        if results?.next() == true {
                            userID = Int(results!.intForColumn("userID"))
                            
                            RestApiManager.sharedInstance.getSchedule(userID, onCompletion: { json -> Void in
                                
                                let dayCount = self.processSchedule(json)
                                NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
                                NSUserDefaults.standardUserDefaults().synchronize()

                                self.loginSegue()
                            })
                        } else {
                            println("error getting schedules")
                        }
                    }
                    
                    sparqDB.close()
                }
            })
        }
        
            let sparqDB = FMDatabase(path: databasePath as String)
            
            if sparqDB == nil {
                println("Error: \(sparqDB.lastErrorMessage())")
            }
            
            if sparqDB.open() {
                var sql_stmt = "CREATE TABLE IF NOT EXISTS Users (userID INT, type INT, grade INT, email TEXT)"
                if !sparqDB.executeStatements(sql_stmt) {
                    println("Error: \(sparqDB.lastErrorMessage())")
                }
                
                
                sql_stmt = "CREATE TABLE IF NOT EXISTS Schedules (version INT, grade INT, schoolName TEXT, timezone TEXT, startDate TEXT, stopDate TEXT)"
                if !sparqDB.executeStatements(sql_stmt) {
                    println("Error: \(sparqDB.lastErrorMessage())")
                }
                
                
                sql_stmt = "CREATE TABLE IF NOT EXISTS Days (number INT, name TEXT)"
                if !sparqDB.executeStatements(sql_stmt) {
                    println("Error: \(sparqDB.lastErrorMessage())")
                }
                
                
                sql_stmt = "CREATE TABLE IF NOT EXISTS Meetings (subject TEXT, grade INT, room  TEXT, startTime TEXT, stopTime TEXT, period INT, day INT, section INT, teacherName TEXT, teacherEmail TEXT, icon TEXT)"
                if !sparqDB.executeStatements(sql_stmt) {
                    println("Error: \(sparqDB.lastErrorMessage())")
                }
                
                sql_stmt = "CREATE TABLE IF NOT EXISTS Holidays (name TEXT, date TEXT)"
                if !sparqDB.executeStatements(sql_stmt) {
                    println("Error: \(sparqDB.lastErrorMessage())")
                }
                
                sparqDB.close()
            } else {
                println("Error: \(sparqDB.lastErrorMessage())")
            }            // delete sqlite file to clear data: http://stackoverflow.com/questions/1077810/delete-reset-all-entries-in-core-data
            
    }
    
    // built in method called when the main view is pressed
    override func touchesBegan(touches: Set<NSObject>, withEvent event: UIEvent) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginPressed(sender: AnyObject) {
        self.errorText.hidden = true;
        
        // hide keyboard
        self.view.endEditing(true)

        //self.usernameField.resignFirstResponder()
        //self.passwordField.resignFirstResponder()
        
        let username = usernameField.text
        let password = passwordField.text
        
        if username != nil && !username.isEmpty {
            
        } else {
            self.errorText.hidden = false
            self.errorText.text = "Enter a username/email"
            return
        }
        
        if password != nil && !password.isEmpty {
            
        } else {
            self.errorText.hidden = false
            self.errorText.text = "Enter a password"
            return
        }
        
        // make login call
        RestApiManager.sharedInstance.login(username, password: password, onCompletion: { json -> Void in
            //self.errorText?.hidden = false
            //self.errorText?.text = String(json["userID"].intValue)
            
            let dayCount = self.processSchedule(json)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
            NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
            NSUserDefaults.standardUserDefaults().synchronize()

            self.loginSegue()
        })
    }
    
    func processSchedule(json: JSON) -> Int {
        
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB == nil {
            println("Error: \(sparqDB.lastErrorMessage())")
        }
        
        /* iterate to save into DB */
        
        // User
        user.email = usernameField.text
        user.userID = json["userID"].intValue
        user.type = json["type"].intValue
        
        // put into DB
        if sparqDB.open() == false {
            println("can't open DB")
        }
        
        var stmt = "INSERT INTO Users (userID, email, grade, type) VALUES "
        stmt += "(\(user.userID), "
        stmt += "'" + user.email + "', "
        stmt += "\(user.grade), "
        stmt += "\(user.type))"
        
        var results = sparqDB.executeUpdate(stmt, withArgumentsInArray: nil)
        
        if !results {
            self.errorText.text = "Failed to add user"
            println("Error: \(sparqDB.lastErrorMessage())")
        }
        
        
        // Schedule
        schedule.schoolName = json["schoolName"].stringValue
        schedule.startDate = dateFormatter.dateFromString(json["startDate"].stringValue)!
        schedule.stopDate = dateFormatter.dateFromString(json["stopDate"].stringValue)!
        schedule.grade = json["grade"].intValue
        schedule.timezone = json["timezone"].stringValue
        schedule.version = json["version"].intValue
        
        // put into DB
        stmt = "INSERT INTO Schedules (schoolName, startDate, stopDate, grade, timezone, version) VALUES"
        stmt += "('" + schedule.schoolName + "', "
        stmt += "'" + json["startDate"].stringValue + "', "
        stmt += "'" + json["stopDate"].stringValue + "', "
        stmt += "\(schedule.grade), "
        stmt += "'" + schedule.timezone + "', "
        stmt += "\(schedule.version))"
        
        results = sparqDB.executeUpdate(stmt,
            withArgumentsInArray: nil)
        
        if !results {
            self.errorText.text = "Failed to add user"
            println("Error: \(sparqDB.lastErrorMessage())")
        }
        
        
        for( index, section ) in json["meetings"] {
            stmt  = "INSERT INTO Meetings(subject, grade, room, startTime, stopTime, period, day, section, teacherName, teacherEmail, icon) VALUES("
            stmt += "'" + section["subject"].stringValue + "', "
            stmt += String(section["grade"].intValue) + ", "
            stmt += "'" + section["room"].stringValue + "', "
            stmt += "'" + section["startTime"].stringValue + "', "
            stmt += "'" + section["stopTime"].stringValue + "', "
            stmt += String(section["period"].intValue) + ", "
            stmt += String(section["day"].intValue) + ", "
            stmt += String(section["section"].intValue) + ", "
            stmt += "'" + section["teacherName"].stringValue + "', "
            stmt += "'" + section["teacherEmail"].stringValue + "', "
            stmt += "'" + section["icon"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                println("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        
        var dayCount = 0
        for( index, day ) in json["days"] {
            stmt = "INSERT INTO Days(number, name) VALUES("
            
            
            stmt += String(day["number"].intValue) + ", "
            stmt += "'" + day["name"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                println("Error: \(sparqDB.lastErrorMessage())")
            }
            dayCount++
        }
        
        for( index, holiday ) in json["holidays"] {
            stmt = "INSERT INTO Holidays (name, date) VALUES ("
            
            stmt += "'" + holiday["date"].stringValue + "', "
            stmt += "'" + holiday["name"].stringValue + "')"
            
            // put into db
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                self.errorText.text = "Failed to add user"
                println("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        sparqDB.commit()
        sparqDB.close()

        return dayCount
    }
    
    @IBAction func troublePressed(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(NSURL(string:"http://www.sparqcalendar.com/recover")!)
    }
    
    func loginSegue() {
        performSegueWithIdentifier("LoginSegue", sender: nil)
    }

    
    override func viewWillAppear(animated: Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        timeFormatter.dateFormat = "HH:mm:ss"
        todFormatter.dateFormat = "h:mm a"
        
        
        // background setup
        // #3DFCBC
        let left = UIColor(red: 61/255.0, green: 252/255.0, blue: 189/255.0, alpha: 1.0)
        // #1279bd
        let right = UIColor(red: 18/255.0, green: 121/255.0, blue: 189/255.0, alpha: 1.0).CGColor as CGColorRef
        
        // 2
        gl.frame = self.view.bounds
        
        gl.colors = [left, right]
        gl.locations = [0.0,1.0]
        
        
        
        //        let frame:CGRect = CGRect(x:0, y:100, width:self.view.frame.width, height:self.view.frame.height-100)
        //        self.tableView = UITableView(frame: frame)
        //        self.tableView?.dataSource = self
        //        self.tableView?.delegate = self
        //        self.view.addSubview(self.tableView!)
        
    }
}