

import UIKit
import Foundation

var today = NSDate()
var dayNumber = 0

var notificationTimer: NSTimer?
var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
var titleDateFormatter = NSDateFormatter()

let lightGrey = UIColor(red: 239/255.0, green: 239/255.0, blue: 239/255.0, alpha: 1.0)

let darkGrey = UIColor(red: 214/255.0, green: 214/255.0, blue: 214/255.0, alpha: 1)


// this is the delegate
class ScheduleViewController: UITableViewController {
    let gl = CAGradientLayer()
    
    var items = NSMutableArray();
        var dayID = 0
    
    @IBOutlet var tblClasses: UITableView!
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var leftArrow: UIImageView!
    @IBOutlet weak var rightArrow: UIImageView!
    @IBOutlet weak var settingsIcon: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        // add it to the image view;
        leftArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("leftArrow:")))
        rightArrow.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("rightArrow:")))
        dayLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dayLabel:")))
        dateLabel.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("dateLabel:")))
        settingsIcon.addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("settingsClicked:")))
        // make sure imageView can be interacted with by user
        leftArrow.userInteractionEnabled = true
        rightArrow.userInteractionEnabled = true
        dayLabel.userInteractionEnabled = true
        dateLabel.userInteractionEnabled = true
        settingsIcon.userInteractionEnabled = true
        
        if schedule.version == -1 || days.count <= 0 {
            loadScheduleDaysAndHolidays()
        }
        
        
        if debug {
            loadTableViewForDate(debugToday)
        } else {
            loadTableViewForDate(NSDate())
        }
        
        startTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = NSTimeZone.localTimeZone()
        todFormatter.dateFormat = "h:mm a"
        todFormatter.timeZone = NSTimeZone.localTimeZone()
        titleDateFormatter.dateFormat = "EEEE d"
        titleDateFormatter.timeZone = NSTimeZone.localTimeZone()
    
        dayLabel.hidden = false
        dateLabel.hidden = false
        
//        self.navigationController?.navigationBarHidden = true
        self.navigationItem.hidesBackButton = true
//        let backButton = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Plain, target: navigationController, action: nil)
//        navigationItem.leftBarButtonItem = backButton
        
        self.view.backgroundColor = UIColor(patternImage: UIImage(named: "bg.png")!)
    }
    
    func getDayOfSchedule(now: NSDate) -> Int {
        
        let skip = countHolidays(schedule.startDate, stop: now)
        
        let cal = NSCalendar.currentCalendar()
        
        let components = cal.components(NSCalendarUnit.Day, fromDate: schedule.startDate, toDate: now, options: [])
        let daysBetween = components.day
        let startComp = cal.components(NSCalendarUnit.Weekday, fromDate: schedule.startDate)
        let startWeekday = startComp.weekday
        let stopComp = cal.components(NSCalendarUnit.Weekday, fromDate: now)
        let stopWeekeday = stopComp.weekday
        
        if stopComp.weekday == 1 || stopComp.weekday == 7 {
            // load view for weekend
            
            return 0
        }
        
        var weeks = Int(floor(Double(daysBetween) / 7.0))
        //        var remainder = ((daysBetween) % 7)
        if stopWeekeday < startWeekday { // add another weekend if wraps around a weekend.
            weeks++
        }
        return ((daysBetween - skip - 2 * weeks) % days.count) + 1 // % is 0-ordinal
    }
    
    func loadTableViewForDate(date:NSDate) {
        if today != date {
            today = date
        }
        classes = [ClassMeetings]()
        
        print("Loading tableView for " + dateFormatter.stringFromDate(today) + " " + timeFormatter.stringFromDate(today))
        
        dateLabel.text = today.stringFromFormat("EEEE MMM d")
        
        
        let holiday = dateFormatter.stringFromDate(today)
        
        if let h = holidays[holiday] {
            // load view for today's holiday
            dayLabel.text = "Holiday"
        } else if schedule.startDate > today {
            dayLabel.text = "Before Schedule"
        } else if schedule.stopDate < today {
            dayLabel.text = "After Schedule"
        } else {
            dayNumber = getDayOfSchedule(date)
            
            if dayNumber != -1 { // error of some sort
            
                if today.weekday == 1 || today.weekday == 7 {
                    dayLabel.text = "Weekend"
                } else {
                    dayLabel.text = days[dayNumber-1] + "-Day"
                }
                
                if dayNumber != 0 { // is a weekend
                    classes = getClassesForScheduleDay(dayNumber)
                }
            }
        }
        
        
        tableView.reloadData()
    }
    
    func getClassesForScheduleDay(day: Int) -> [ClassMeetings] {
        var m = [ClassMeetings]()
        
        if day > 0 {
        
            let sparqDB = FMDatabase(path: databasePath as String)
            if sparqDB.open() {
                let stmt = "SELECT * from Meetings WHERE day = \(dayNumber) order by startTime ASC"
                
                let results:FMResultSet? = sparqDB.executeQuery(stmt,
                    withArgumentsInArray: nil)
                
                while results?.next() == true {
                    let meeting = ClassMeetings()
                    
                    meeting.subject = results!.stringForColumn("subject")
                    meeting.grade = Int(results!.intForColumn("grade"))
                    meeting.room = results!.stringForColumn("room")
                    meeting.startTimeStr = results!.stringForColumn("startTime")
                    meeting.startTime = timeFormatter.dateFromString(meeting.startTimeStr)!
                    meeting.stopTimeStr = results!.stringForColumn("stopTime")
                    meeting.stopTime = timeFormatter.dateFromString(meeting.stopTimeStr)!
                    meeting.period = Int(results!.intForColumn("period"))
                    meeting.day = dayNumber
                    meeting.dayName = days[dayNumber-1]
                    meeting.section = Int(results!.intForColumn("section"))
                    meeting.teacherName = results!.stringForColumn("teacherName")
                    meeting.teacherEmail = results!.stringForColumn("teacherEmail")
                    meeting.icon = results!.stringForColumn("icon")
                    
                    m.append(meeting)
                }
                
                sparqDB.close()
            }
        }

        return m
    }

    func loadScheduleDaysAndHolidays() {
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB.open() {
            var stmt = "SELECT * FROM Schedules"
            
            var results:FMResultSet? = sparqDB.executeQuery(stmt,
                withArgumentsInArray: nil)
            
            if results?.next() == true {
                schedule.version = Int(results!.intForColumn("version"))
                schedule.timezone = results!.stringForColumn("timezone")
                schedule.stopDate = dateFormatter.dateFromString(results!.stringForColumn("stopDate"))!
                schedule.startDate = dateFormatter.dateFromString(results!.stringForColumn("startDate"))!
                schedule.schoolName = results!.stringForColumn("schoolName")
                schedule.grade = Int(results!.intForColumn("grade"))
            }
            
            stmt = "SELECT * from Days order by number ASC"
            results = sparqDB.executeQuery(stmt, withArgumentsInArray: nil)
            
            days = [String]()
            while results?.next() == true {
                let day = Days()
                
                day.name = results!.stringForColumn("name")
                day.number = Int(results!.intForColumn("number"))
                
                days.append(day.name)
            }
            
            stmt = "SELECT * FROM Holidays WHERE date >= '" + dateFormatter.stringFromDate(schedule.startDate) + "' AND date <= '" + dateFormatter.stringFromDate(schedule.stopDate) + "' order by date ASC"
            results = sparqDB.executeQuery(stmt, withArgumentsInArray: nil)
            
            while results?.next() == true {
                var day = Holidays()
                
                let name = results!.stringForColumn("name")
                let date = results!.stringForColumn("date")
                
                holidays[date] = name
            }

            sparqDB.close()
        }
    }
    
    func countHolidays(start:NSDate, stop:NSDate) -> Int{
        let sparqDB = FMDatabase(path: databasePath as String)

        if sparqDB.open() {
            let startDate = dateFormatter.stringFromDate(start)
            let stopDate = dateFormatter.stringFromDate(stop)
            
            
            let stmt = "SELECT COUNT(date) as count FROM Holidays WHERE date >= '\(startDate)' AND date <= '\(stopDate)'"
            let results:FMResultSet? = sparqDB.executeQuery(stmt, withArgumentsInArray: nil)
            
            if results?.next() == true {
                let count = Int(results!.intForColumn("count"))
                sparqDB.close()

                return count
            }
            
            sparqDB.close()
        }
        
        return -1
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // #warning Potentially incomplete method implementation.
        // Return the number of sections.
        return 1
    }
    
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete method implementation.
        // Return the number of rows in the section.
        if let h = holidays[dateFormatter.stringFromDate(today)] {
            return 1
        } else {
            if classes.count == 0 {
                return 1
            } else {
                return classes.count
            }
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ClassTableViewCell
        
        if let h = holidays[dateFormatter.stringFromDate(today)] { // holiday
            //cell.subjectImage?.image = UIImage(named: "icn_holiday") //"icn_holiday")
            cell.subjectImage?.image = UIImage(named: "icn_default")
            cell.subjectLabel?.text = h
            cell.roomLabel?.text = ""
            cell.timeLabel?.text = ""
            cell.backgroundColor = UIColor.whiteColor()
        } else if classes.count == 0 { // weekend
            cell.subjectImage?.image = UIImage(named: "icn_default")
            cell.roomLabel?.text = ""
            cell.timeLabel?.text = ""
            cell.teacherLabel?.text = ""
            cell.backgroundColor = darkGrey
            
            if today.weekday == 1 || today.weekday == 7 { // weekday
                cell.subjectLabel?.text = "It's the weekend, enjoy!"
            } else {
                cell.subjectLabel?.text = "It's your day off, enjoy!"
            }
        } else { // school day
            let c = classes[indexPath.row]
            // Configure the cell...
            
            if let icon = c.icon as String? {
                cell.subjectImage?.image = UIImage(named: icon)
            } else {
                // default image
                cell.subjectImage?.image = UIImage(named: "icn_default")
            }
            
            if c.grade == 0 {
                cell.subjectLabel?.text = c.subject
            } else {
                if c.section == 0 {
                    cell.subjectLabel?.text = c.subject + " \(c.grade)"
                } else {
                    cell.subjectLabel?.text = c.subject + " \(c.grade)-\(c.section)"
                }
            }
            
            if c.teacherName.isEmpty || user.type != 1 {
                cell.teacherLabel.hidden = true
            } else {
                cell.teacherLabel.hidden = false
                cell.teacherLabel.text = "Taught by: " + c.teacherName
            }
            
            if c.room.isEmpty {
                cell.roomLabel.hidden = true
            } else {
                cell.roomLabel.text = "Room \(c.room)"
                cell.roomLabel.hidden = false
            }
            cell.timeLabel?.text = todFormatter.stringFromDate(c.startTime) + " to " + todFormatter.stringFromDate(c.stopTime)
            
//            let now = timeFormatter.stringFromDate(today)
//            let start = timeFormatter.stringFromDate(c.startTime)
//            let stop = timeFormatter.stringFromDate(c.stopTime)
            
            if (!debug && today.beginningOfDay == NSDate().beginningOfDay) || (debug && today.beginningOfDay == debugToday.beginningOfDay) { // only color if today's schedule
                if (today >>= c.startTime) && today << c.stopTime { // class is now
                    cell.backgroundColor = UIColor.whiteColor()
                    
                //    tableView.scrollToRowAtIndexPath(indexPath, atScrollPosition: .Top, animated: false)
                } else if today << c.startTime { // class in the future
                    cell.backgroundColor = lightGrey
                } else if (today >>= c.stopTime) { // class in the past
                    cell.backgroundColor = darkGrey
                }
            } else {
                cell.backgroundColor = UIColor.whiteColor()
            }
        }
        
        return cell
    }
    
    func registerBackgroundTask() {
        backgroundTask = UIApplication.sharedApplication().beginBackgroundTaskWithExpirationHandler {
            [unowned self] in
            self.endBackgroundTask()
        }
        assert(backgroundTask != UIBackgroundTaskInvalid)
    }
    
    func endBackgroundTask() {
        NSLog("Background task ended.")
        UIApplication.sharedApplication().endBackgroundTask(backgroundTask)
        backgroundTask = UIBackgroundTaskInvalid
    }
    
    func startTimer() {
        if let n = notificationTimer {
            return
        }
        
        notificationTask()
    }
    
    
    func notificationTask() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), { () -> Void in
            
            var now = NSDate()
            if debug {
                now = today
            }
            let nowStr = timeFormatter.stringFromDate(now)
            
    //        switch UIApplication.sharedApplication().applicationState {
    //        case .Active:
    //            breaknotifi
    //        case .Background:
    //            break
    //        case .Inactive:
    //            break
    //        }
            
            var timerInterval = NSTimeInterval(0)
            var meeting = ClassMeetings()
            
            
            let d = self.getDayOfSchedule(now)
            if d == 0 { // weekend, check tomorrow
                timerInterval = now.beginningOfDay + 1.day - now
            } else { // find the next class
                if self.isDateAHoliday(now) { // check tomorrow
                    timerInterval = now.beginningOfDay + 1.day - now
                } else {
                    let meetings = self.getClassesForScheduleDay(d)
                    
                    if meetings.count == 0 { // no classes today, check tomorrow
                        timerInterval = now.beginningOfDay + 1.day - now
                    } else if meetings[0].startTime >> now {    // before classes have started, pick first
                        meeting = meetings[0]
                        timerInterval = now.change(hour: meeting.startTime.hour, minute: (meeting.startTime.minute + 10)) - now
                    } else if meetings.last.stopTime << now { // after classes have started, check tomorrow
                        timerInterval = now.beginningOfDay + 1.day - now
                    } else { // during a class, pick next
                        for (index, m) in meetings.enumerate() {
                            if (m.startTime <<= now) && m.stopTime >> now {
                                if index == meetings.count - 1 { // last class, pick next day
                                    timerInterval = now.beginningOfDay + 1.day - now
                                } else { // pick the next class
                                    meeting = meetings[index + 1]
                                    timerInterval = now.change(hour: meeting.startTime.hour, minute: (meeting.startTime.minute + 10)) - now
                                }
                            }
                        }
                    }
                }
            }
            
            if meeting.day > 0 { // !nil
                self.pushClassNotification(meeting)
            }
            
            
            notificationTimer = NSTimer.scheduledTimerWithTimeInterval(
                timerInterval,
                target: self,
                selector: Selector("notificationTask"),
                userInfo: nil,
                repeats: false)
            
        })
    }
    
    func pushClassNotification(meeting: ClassMeetings) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        let localNotification: UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Next Class"
        localNotification.alertBody = meeting.dayName + " - Day\n" + meeting.subject + " in " + meeting.room + "\n" + todFormatter.stringFromDate(meeting.startTime) + " to " + todFormatter.stringFromDate(meeting.stopTime)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func isDateAHoliday(date: NSDate) -> Bool {
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB.open() {
            let date = dateFormatter.stringFromDate(date)
            
            
            let stmt = "SELECT COUNT(date) as count FROM Holidays WHERE date = '\(date)'"
            let results:FMResultSet? = sparqDB.executeQuery(stmt, withArgumentsInArray: nil)
            
            if results?.next() == true {
                let count = Int(results!.intForColumn("count"))
                sparqDB.close()
                
                return count > 0
            }
            
            sparqDB.close()
        }

        return false
    }
    
    // weekday 1 = Sunday, weekeday 7 = Saturday
    func leftArrow(gesture: UIGestureRecognizer) {
        if today.weekday == 2 {
            loadTableViewForDate(today - 3.day)
        } else if today.weekday == 1 {
            loadTableViewForDate(today - 2.day)
        } else {
            loadTableViewForDate(today - 1.day)
        }
    }
    
    func rightArrow(gesture: UIGestureRecognizer) {
        if today.weekday == 6 {
            loadTableViewForDate(today + 3.day)
        } else if today.weekday == 7 {
            loadTableViewForDate(today + 2.day)
        } else {
            loadTableViewForDate(today + 1.day)
        }
    }
    
    func dayLabel(gesture: UIGestureRecognizer) {
        loadTableViewForDate(NSDate())
    }
    
    func dateLabel(gesture: UIGestureRecognizer) {
        loadTableViewForDate(NSDate())
    }
    
    func settingsClicked(gesture: UIGestureRecognizer) {
        let logoutDialog: UIAlertController = UIAlertController(title: "Logout?", message: "Do you want to logout of your calendar?", preferredStyle: .Alert)
        
        //Create and add the Cancel action
        let cancelAction: UIAlertAction = UIAlertAction(title: "Cancel", style: .Cancel) { action -> Void in
            //Do some stuff
            logoutDialog.dismissViewControllerAnimated(true, completion: nil)
        }
        logoutDialog.addAction(cancelAction)
        
        //Create and an option action
        let nextAction: UIAlertAction = UIAlertAction(title: "Logout", style: .Default) { action -> Void in
            //Do some other stuff
            self.performSegueWithIdentifier("UnwindToLogin", sender: self)
            
        }
        logoutDialog.addAction(nextAction)
        
        self.presentViewController(logoutDialog, animated: true, completion: nil)
    }
}
