

import UIKit
import Foundation

var dateFormatter = NSDateFormatter()
var timeFormatter = NSDateFormatter()
var todFormatter = NSDateFormatter()

var user = User()
var classes = [Class]()
var days = [String]()
var holidays = Dictionary<String,String>()
var schedule = Schedule()

var databasePath = ""

var debug = false
var debug_login = false
var debug_userID = 61

let debugToday: NSDate = "2015-12-10 12:00:00".dateFromFormat("yyyy-MM-dd HH:mm:ss")!


class LoginViewController: UIViewController, UIApplicationDelegate, UITextViewDelegate {
    let gl = CAGradientLayer()
    
    @IBOutlet weak var errorText: UILabel!
    @IBOutlet weak var usernameField: UITextField!
    @IBOutlet weak var passwordField: UITextField!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var troubleButton: UIButton!
    @IBOutlet weak var progress: UIActivityIndicatorView!
        
    
    override func viewDidLoad() {
        super.viewDidLoad()
        errorText.hidden = true
        showActivityIndicator(false)

        usernameField.text = ""
        usernameField.autocorrectionType = UITextAutocorrectionType.No
        usernameField.autocapitalizationType = UITextAutocapitalizationType.None
        passwordField.text = ""
        passwordField.autocorrectionType = UITextAutocorrectionType.No
        passwordField.autocapitalizationType = UITextAutocapitalizationType.None
        
        // Do any additional setup after loading the view, typically from a nib.
        //let filemgr = NSFileManager.defaultManager()
        let dirPaths =
        NSSearchPathForDirectoriesInDomains(.DocumentDirectory,
            .UserDomainMask, true)
        
        let docsDir = dirPaths[0] 
        
        databasePath = (docsDir as NSString).stringByAppendingPathComponent(
            "sparq.db")

        
        let loginStored = NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey")
        
        // check server version to sync the data
        
        if debug && debug_login {
            self.dropAllTables()
            
            RestApiManager.sharedInstance.getSchedule(debug_userID, onCompletion: { json -> Void in
                let dayCount = self.processSchedule(json)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
                NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
                NSUserDefaults.standardUserDefaults().setInteger(debug_userID, forKey: "userID")
                NSUserDefaults.standardUserDefaults().synchronize()
                
                self.loginSegue()
            })
        } else if loginStored  {
            let sparqDB = FMDatabase(path: databasePath as String)
            
            if sparqDB == nil {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            var version = 0
            var userID = 0
            var schoolYearID = 0
            var dataFound = false;
            if sparqDB.open() {
                var stmt = "SELECT version, schoolYearID from Schedules LIMIT 1"
                
                // put into DB
                var results:FMResultSet? = sparqDB.executeQuery(stmt,
                    withArgumentsInArray: nil)
                
                if results?.next() == true {
                    version = Int(results!.intForColumn("version"))
                    schoolYearID = Int(results!.intForColumn("schoolYearID"))
                } else {
                    print("error getting verson number")
                }
                
                
                stmt = "SELECT userID, email from Users LIMIT 1"
                
                // put into DB
                results = sparqDB.executeQuery(stmt,
                    withArgumentsInArray: nil)
                
                if results?.next() == true {
                    //usernameField.text = results?.stringForColumn("email")
                    userID = Int(results!.intForColumn("userID"))
                } else {
                    print("error getting user info")
                }
                
                if version > 0 && schoolYearID > 0 && userID > 0 {
                    dataFound = true
                }
             
                sparqDB.close()
            }
            
            if !dataFound { // data base moved yet login creds stored.
                let userID = NSUserDefaults.standardUserDefaults().integerForKey("UserID")
                
                if userID > 0 {
                    self.getSchedule(userID)
                }
            } else {
                RestApiManager.sharedInstance.checkVersion(version, schoolYearID: schoolYearID, onCompletion: { json -> Void in
                    
                    if json["version"] == "current" {
                        print("schedule current")
                        self.loginSegue()
                    } else { // grab the schedule again
                        print("schedule out of date")
                        self.dropAllTables()
                        
                        let sparqDB = FMDatabase(path: databasePath as String)
                        
                        if sparqDB == nil {
                            print("Error: \(sparqDB.lastErrorMessage())")
                        }
                        
                        var userID = 0
                        if sparqDB.open() {
                            let stmt = "SELECT userID from Users LIMIT 1"
                            
                            // delete old data first!
                            // TODO
                            
                            // put into DB
                            let results:FMResultSet? = sparqDB.executeQuery(stmt,
                                withArgumentsInArray: nil)
                            
                            if results?.next() == true {
                                userID = Int(results!.intForColumn("userID"))
                                
                                self.getSchedule(userID)
                            } else {
                                print("error getting user info")
                            }
                        }
                        
                        sparqDB.close()
                    }
                })
            }
        }
        
        createTables()
    }
    
    // built in method called when the main view is pressed
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    @IBAction func loginPressed(sender: AnyObject) {
        print("Login button pressed")
        
        // can haz WIFI?
        let status = Reach().connectionStatus()
        switch status {
        case .Unknown, .Offline:
            self.errorText.hidden = false
            self.errorText.text = "Not connected to the internet."
            return
        case .Online(.WWAN):
            print("Connected via WWAN")
        case .Online(.WiFi):
            print("Connected via WiFi")
        }

        
        self.errorText.hidden = true;
        showActivityIndicator(true)
        
        // hide keyboard
        self.view.endEditing(true)

        //self.usernameField.resignFirstResponder()
        //self.passwordField.resignFirstResponder()
        
        var username = usernameField.text
        let password = passwordField.text
        
        if username != nil && !username!.isEmpty {
            if username!.rangeOfString("@") != nil && username!.rangeOfString(".") != nil {
                username = username!.lowercaseString
            } else {
                self.errorText.hidden = false
                self.errorText.text = "Not a valid email address"
                self.showActivityIndicator(false)
                return
            }
        } else {
            self.errorText.hidden = false
            self.errorText.text = "Enter a username/email"
            self.showActivityIndicator(false)
            return
        }
        
        if password != nil && !password!.isEmpty {
          
//            password = 
        } else {
            self.errorText.hidden = false
            self.errorText.text = "Enter a password"
            self.showActivityIndicator(false)
            return
        }
        
        if NSUserDefaults.standardUserDefaults().boolForKey("hasLoginKey") {
            // CLEAR stored DATA
            dropAllTables()
            
            
            NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasLoginKey")
            NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "dayCount")
            NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "userID")
            NSUserDefaults.standardUserDefaults().synchronize()

        }
        
        // make login call
        RestApiManager.sharedInstance.login(username!, password: password!, onCompletion: { json -> Void in
            //self.errorText?.hidden = false
            //self.errorText?.text = String(json["userID"].intValue)
            
            if let error = json["error"].string {
                self.errorText.text = error
                self.errorText.hidden = false
            } else {
                let dayCount = self.processSchedule(json)
                
                NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
                NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
                NSUserDefaults.standardUserDefaults().setInteger(json["userID"].intValue, forKey: "userID")
                NSUserDefaults.standardUserDefaults().synchronize()

                self.loginSegue()
            }
            self.showActivityIndicator(false)
        })
    }
    
    func showActivityIndicator(show: Bool) {
        if show {
            self.progress.hidden = false
            self.progress.startAnimating()
        } else {
            self.progress.stopAnimating()
            self.progress.hidden = true
        }
    }
    
    func processSchedule(json: JSON) -> Int {
        
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB == nil {
            print("Error: \(sparqDB.lastErrorMessage())")
        }
        
        /* iterate to save into DB */
        
        // User
        user.email = usernameField.text!
        user.userID = json["userID"].intValue
        user.type = json["type"].intValue
        user.grade = json["grade"].intValue
        
        // put into DB
        if sparqDB.open() == false {
            print("can't open DB")
        }
        
        print("Inserting User")
        var stmt = "INSERT INTO Users (userID, email, grade, type) VALUES "
        stmt += "(\(user.userID), "
        stmt += "'" + user.email + "', "
        stmt += "\(user.grade), "
        stmt += "\(user.type))"
        
        var results = sparqDB.executeUpdate(stmt, withArgumentsInArray: nil)
        
        if !results {
            self.errorText.text = "Failed to add user"
            print("Error: \(sparqDB.lastErrorMessage())")
        }
        
        
        // Schedule
        schedule.schoolName = json["schoolName"].stringValue
        schedule.startDate = dateFormatter.dateFromString(json["startDate"].stringValue)!
        schedule.stopDate = dateFormatter.dateFromString(json["stopDate"].stringValue)!
        schedule.grade = json["grade"].intValue
        schedule.timezone = json["timezone"].stringValue
        schedule.version = json["version"].intValue
        schedule.schoolID = json["schoolID"].intValue
        schedule.schoolYearID = json["schoolYearID"].intValue
        
        // put into DB
        print("Inserting Schedule")
        stmt = "INSERT INTO Schedules (schoolName, startDate, stopDate, grade, timezone, version, schoolID, schoolYearID) VALUES"
        stmt += "('" + schedule.schoolName + "', "
        stmt += "'" + json["startDate"].stringValue + "', "
        stmt += "'" + json["stopDate"].stringValue + "', "
        stmt += "\(schedule.grade), "
        stmt += "'" + schedule.timezone + "', "
        stmt += "\(schedule.version), "
        stmt += "\(schedule.schoolID), "
        stmt += "\(schedule.schoolYearID))"
        
        results = sparqDB.executeUpdate(stmt,
            withArgumentsInArray: nil)
        
        if !results {
            self.errorText.text = "Failed to add schedule"
            print("Error: \(sparqDB.lastErrorMessage())")
        }
        
        print("Inserting Semesters")
        for( _, semester) in json["semesters"] {
            stmt  = "INSERT INTO Semesters(semesterID, startDate, stopDate) VALUES ("
            stmt += String(semester["id"].intValue) + ","
            stmt += "'" + semester["startDate"].stringValue + "',"
            stmt += "'" + semester["stopDate"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        print("Inserting Sections")
        for( _, section) in json["sections"] {
            stmt  = "INSERT INTO Sections(sectionID, subject, grade, room, section, teacherName, teacherEmail, icon) VALUES ("
            stmt += String(section["id"].intValue) + ","
            stmt += "'" + section["subject"].stringValue + "', "
            stmt += String(section["grade"].intValue) + ", "
            stmt += "'" + section["room"].stringValue + "', "
            stmt += String(section["section"].intValue) + ", "
            stmt += "'" + section["teacherName"].stringValue + "', "
            stmt += "'" + section["teacherEmail"].stringValue + "', "
            stmt += "'" + section["icon"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        print("Insert Meetings")
        for( _, meeting ) in json["meetings"] {
            stmt = "INSERT INTO Meetings(sectionID, periodID, dayID, semesterID) VALUES("
            stmt += String(meeting["sectionID"].intValue) + ", "
            stmt += String(meeting["periodID"].intValue) + ", "
            stmt += String(meeting["dayID"].intValue) + ", "
            stmt += String(meeting["semesterID"].intValue) + ")"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        print("Insert Periods")
        for( _, period ) in json["periods"] {
            stmt = "INSERT INTO Periods(periodID, number, start, stop) VALUES("
            stmt += String(period["id"].intValue) + ", "
            stmt += String(period["number"].intValue) + ", "
            stmt += "'" + period["start"].stringValue + "', "
            stmt += "'" + period["stop"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
        print("Insert Days")
        var dayCount = 0
        for( _, day ) in json["days"] {
            stmt = "INSERT INTO Days(dayID, number, name) VALUES("
            stmt += String(day["id"].intValue) + ", "
            stmt += String(day["number"].intValue) + ", "
            stmt += "'" + day["name"].stringValue + "')"
            
            // put into DB
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            dayCount++
        }
        
        print("Insert Holidays")
        for( _, holiday ) in json["holidays"] {
            stmt = "INSERT INTO Holidays (name, date) VALUES ("
            
            stmt += "'" + holiday["name"].stringValue + "', "
            stmt += "'" + holiday["date"].stringValue + "')"
            
            // put into db
            results = sparqDB.executeUpdate(stmt,
                withArgumentsInArray: nil)
            
            if !results {
                self.errorText.text = "Failed to add user"
                print("Error: \(sparqDB.lastErrorMessage())")
            }
        }
        
//        sparqDB.commit()
        sparqDB.close()

        return dayCount
    }
    
    @IBAction func troublePressed(sender: AnyObject) {
        
        UIApplication.sharedApplication().openURL(NSURL(string:"http://www.sparqcalendar.com/recover")!)
    }
    
    func loginSegue() {
        dispatch_async(dispatch_get_main_queue()) {
            self.showActivityIndicator(false)
            self.passwordField.text = ""
            self.performSegueWithIdentifier("LoginSegue", sender: nil)
        }
    }

    
    override func viewWillAppear(animated: Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        timeFormatter.dateFormat = "HH:mm:ss"
        todFormatter.dateFormat = "h:mm a"
        showActivityIndicator(false)
        
        // background setup
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "bg.png")!)
        
        
        //        let frame:CGRect = CGRect(x:0, y:100, width:self.view.frame.width, height:self.view.frame.height-100)
        //        self.tableView = UITableView(frame: frame)
        //        self.tableView?.dataSource = self
        //        self.tableView?.delegate = self
        //        self.view.addSubview(self.tableView!)
        
    }
    
    func dropAllTables() { // delete the DB to remove all data
        if let file = NSFileHandle(forUpdatingAtPath: databasePath) {
            file.truncateFileAtOffset(0)
            file.closeFile()
        } else {
            print("File open failed")
        }
        
        createTables()
    }
    
    func createTables() {
        
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB == nil {
            print("Error: \(sparqDB.lastErrorMessage())")
        }
        
        if sparqDB.open() {
            var sql_stmt = "CREATE TABLE IF NOT EXISTS Users (userID INT, type INT, grade INT, email TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Schedules (version INT, grade INT, schoolName TEXT, timezone TEXT, startDate TEXT, stopDate TEXT, schoolID INT, schoolYearID INT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Semesters (semesterID INT, startDate TEXT, stopDate TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Sections (sectionID INT, subject TEXT, icon TEXT, grade INT, room TEXT, section INT, teacherName TEXT, teacherEmail TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Meetings (semesterID INT, sectionID INT, periodID INT, dayID INT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Periods (periodID INT, number INT, start TEXT, stop TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }

            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Days (dayID INT, number INT, name TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sql_stmt = "CREATE TABLE IF NOT EXISTS Holidays (name TEXT, date TEXT)"
            if !sparqDB.executeStatements(sql_stmt) {
                print("Error: \(sparqDB.lastErrorMessage())")
            }
            
            sparqDB.close()
        } else {
            print("Error: \(sparqDB.lastErrorMessage())")
        }
    }
    
    func textFieldShouldReturn(textField: UITextField!) -> Bool {   //delegate method
        self.loginPressed(textField)
        
        return true
    }
    
    func getSchedule(userID: Int) {
        RestApiManager.sharedInstance.getSchedule(userID, onCompletion: { json -> Void in
            let dayCount = self.processSchedule(json)
            
            NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
            NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
            NSUserDefaults.standardUserDefaults().setInteger(userID, forKey: "userID")
            NSUserDefaults.standardUserDefaults().synchronize()
            
            self.loginSegue()
        })
    }
    
    
    @IBAction func registerPressed(sender: UIButton) {
        let alert = UIAlertController(title: "Register", message: "Enter email & password", preferredStyle: UIAlertControllerStyle.Alert)
        var emailTF = UITextField()
        var pw1TF = UITextField()
        var pw2TF = UITextField()
        
        alert.addAction(UIAlertAction(title: "Register", style: UIAlertActionStyle.Default, handler: { action in
            var email = String()
            var pw1:String = String()
            var pw2:String = String()
            
            if let e = emailTF.text {
                email = e
                
                if email.rangeOfString("@") != nil && email.rangeOfString(".") != nil {
                    email = email.lowercaseString
                } else {
                    alert.message = "Enter your email"
                    return
                }
            }
            
            if let pw = pw1TF.text {
                pw1 = pw
            } else {
                alert.message = "Enter a password"
            }
            
            if let pw = pw2TF.text {
                pw2 = pw
            } else {
                alert.message = "Confirm your password"
            }
            
            if pw1 != pw2 {
                alert.message = "Passwords don't match"
            }
            
            alert.dismissViewControllerAnimated(true, completion: nil)
            self.progress.startAnimating()
            
//            let pwHashed = //pw1.dataUsingEncoding(NSUTF8StringEncoding, allowLossyConversion: false)
            RestApiManager.sharedInstance.registerUser(email, password: pw1, onCompletion: { json -> Void in
                    self.progress.stopAnimating()
                
                    if let error = json["error"].string {
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.errorText.text = error
                            self.errorText.hidden = false
                        }
                    } else {
                        let dayCount = self.processSchedule(json)
                        
                        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "hasLoginKey")
                        NSUserDefaults.standardUserDefaults().setInteger(dayCount, forKey: "dayCount")
                        NSUserDefaults.standardUserDefaults().setInteger(json["userID"].intValue, forKey: "userID")
                        NSUserDefaults.standardUserDefaults().synchronize()
                        
                        self.loginSegue()
                        
                    }
                })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { action in
            alert.dismissViewControllerAnimated(true, completion: nil)
        }))
        
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            textField.placeholder = "Enter email"
            emailTF = textField
        })
        
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            textField.placeholder = "Enter password"
            textField.secureTextEntry = true
            pw1TF = textField
        })
        
        alert.addTextFieldWithConfigurationHandler({(textField: UITextField) in
            textField.placeholder = "Reenter password"
            textField.secureTextEntry = true
            pw2TF = textField
        })
        
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    override func canPerformUnwindSegueAction(action: Selector, fromViewController: UIViewController, withSender sender: AnyObject) -> Bool {
        return true
    }
    
    
    @IBAction func unwindToLogin(sender: UIStoryboardSegue)
    {
        print("Logout")
        dropAllTables()
        
        usernameField.text = ""
        passwordField.text = ""
        
        NSUserDefaults.standardUserDefaults().setBool(false, forKey: "hasLoginKey")
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "dayCount")
        NSUserDefaults.standardUserDefaults().setInteger(0, forKey: "userID")
        NSUserDefaults.standardUserDefaults().synchronize()
    }

}