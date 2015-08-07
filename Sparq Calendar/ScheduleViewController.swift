//
//  ClassTableViewController.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/11/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import UIKit
import Foundation

var today = NSDate()
var dayNumber = 0

var notificationTimer: NSTimer?
var backgroundTask: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid

// this is the delegate
class ScheduleViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    let gl = CAGradientLayer()
    
    var items = NSMutableArray();
        var dayID = 0
    
    @IBOutlet var tblClasses: UITableView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        
        
        // background setup
        // #3DFCBC
        let left = UIColor(red: 61/255.0, green: 252/255.0, blue: 189/255.0, alpha: 1.0)
        // #1279bd
        let right = UIColor(red: 18/255.0, green: 121/255.0, blue: 189/255.0, alpha: 1.0).CGColor as CGColorRef
        
        // 2
        gl.frame = self.view.bounds
        
        gl.colors = [left, right]
        gl.locations = [0.0,1.0]
        
//        self.classesTableView.registerClass(ClassTableViewCell.self, forCellReuseIdentifier: "Cell")
//        self.classesTableView.delegate = self\
//        self.tblClasses.reloadData()
        
        
        if schedule.version == -1 || days.count <= 0 {
            loadScheduleDaysAndHolidays()
        }
        
        loadTableViewForDate(NSDate())
        
//        let interval = 
//        NSTimer.scheduledTimerWithTimeInterval(0.5, target: self,
//            selector: "notificationTask", userInfo: nil, repeats: true)
        startTimer()
    }
    
    override func viewWillAppear(animated: Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = NSTimeZone.localTimeZone()
        todFormatter.dateFormat = "h:mm a"
        todFormatter.timeZone = NSTimeZone.localTimeZone()
    }
    
    func getDayOfSchedule(now: NSDate) -> Int {
        
        let skip = countHolidays(schedule.startDate, stop: now)
        
        let cal = NSCalendar.currentCalendar()
        
        let components = cal.components(NSCalendarUnit.CalendarUnitDay, fromDate: schedule.startDate, toDate: now, options: nil)
        let daysBetween = components.day
        let startComp = cal.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: schedule.startDate)
        let startWeekday = startComp.weekday
        let stopComp = cal.components(NSCalendarUnit.CalendarUnitWeekday, fromDate: now)
        let stopWeekeday = stopComp.weekday
        
        if stopComp.weekday == 1 || stopComp.weekday == 7 {
            // load view for weekend
            
            return 0
        }
        
        println("days: " + String(daysBetween))
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
        
        let holiday = dateFormatter.stringFromDate(today)
        
        if let h = holidays[holiday] {
            // load view for today's holiday
            
            return
        }
        
        dayNumber = getDayOfSchedule(date)
        
        if dayNumber == 0 { // is a weekend
            return
        }

        classes = getClassesForScheduleDay(dayNumber)
    }
    
    func getClassesForScheduleDay(day: Int) -> [ClassMeetings] {
        var m = [ClassMeetings]()
        
        if day > 0 {
        
            let sparqDB = FMDatabase(path: databasePath as String)
            if sparqDB.open() {
                var stmt = "SELECT * from Meetings WHERE day = \(dayNumber) order by startTime ASC"
                
                var results:FMResultSet? = sparqDB.executeQuery(stmt,
                    withArgumentsInArray: nil)
                
                classes = [ClassMeetings]()
                while results?.next() == true {
                    var meeting = ClassMeetings()
                    
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
                var day = Days()
                
                day.name = results!.stringForColumn("name")
                day.number = Int(results!.intForColumn("number"))
                
                days.append(day.name)
            }
            
            stmt = "SELECT * FROM Holidays WHERE date >= \(schedule.startDate) AND date <= \(schedule.stopDate) order by date ASC"
            results = sparqDB.executeQuery(stmt, withArgumentsInArray: nil)
            
            while results?.next() == true {
                var day = Holidays()
                
                var name = results!.stringForColumn("name")
                var date = results!.stringForColumn("date")
                
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
            
            
            let stmt = "SELECT COUNT(date) as count FROM Holidays WHERE date >= \(startDate) AND date <= \(stopDate)"
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
            return classes.count
        }
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ClassTableViewCell
        
        if let h = holidays[dateFormatter.stringFromDate(today)] {
            cell.subjectImage?.image = UIImage(named: "icn_default") //"icn_holiday")
            cell.subjectLabel?.text = h
            cell.roomLabel?.text = ""
            cell.timeLabel?.text = ""
            cell.backgroundColor = UIColor.whiteColor()
        } else {
            let c = classes[indexPath.row]
            // Configure the cell...
            
            if let icon = c.icon as String? {
                cell.subjectImage?.image = UIImage(named: icon)
            } else {
                // default image
                cell.subjectImage?.image = UIImage(named: "icn_default")
            }
            cell.subjectLabel?.text = c.subject
            cell.roomLabel?.text = "Room \(c.room)"
            cell.timeLabel?.text = todFormatter.stringFromDate(c.startTime) + " to " + todFormatter.stringFromDate(c.stopTime)
            
            let now = timeFormatter.stringFromDate(NSDate())
            let start = timeFormatter.stringFromDate(c.startTime)
            let stop = timeFormatter.stringFromDate(c.stopTime)
            
            
            if now >= start && now < stop {
                cell.backgroundColor = UIColor.whiteColor()
            } else if now < start {
                cell.backgroundColor = UIColor.lightGrayColor()
            } else if now >= stop {
                cell.backgroundColor = UIColor.darkGrayColor()
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
        
        notificationTimer = NSTimer.scheduledTimerWithTimeInterval(0.5,
            target: self,
            selector: Selector("notificationTask"),
            userInfo: nil,
            repeats: false)
    }
    
    
    func notificationTask() {
        let now = NSDate()
        let nowStr = timeFormatter.stringFromDate(now)
        
//        switch UIApplication.sharedApplication().applicationState {
//        case .Active:
//            break
//        case .Background:
//            break
//        case .Inactive:
//            break
//        }
        
        var timerInterval = NSTimeInterval(0)
        var meeting = ClassMeetings()
        
        
        let d = getDayOfSchedule(now)
        if d == 0 { // weekend, check tomorrow
            timerInterval = now.beginningOfDay + 1.day - now
        } else { // find the next class
            if isDateAHoliday(now) { // check tomorrow
                timerInterval = now.beginningOfDay + 1.day - now
            } else {
                let meetings = getClassesForScheduleDay(d)
                
                if meetings[0].startTime > now {    // before classes have started, pick first
                    meeting = meetings[0]
                    timerInterval = now.change(hour: meeting.startTime.hour, minute: meeting.startTime.minute + 10.minutes) - now
                } else if meetings.last.stopTime < now { // after classes have started, check tomorrow
                    timerInterval = now.beginningOfDay + 1.day - now
                } else { // during a class, pick next
                    for (index, m) in enumerate(meetings) {
                        if m.startTime <= now && m.stopTime > now {
                            if index == meetings.count - 1 { // last class, pick next
                                timerInterval = now.beginningOfDay + 1.day - now
                            } else { // pick a class
                                meeting = m
                                timerInterval = now.change(hour: meeting.hour, minute: meeting.minute + 10.minutes) - now
                            }
                        }
                    }
                }
            }
        }
        
        if meeting.day > 0 { // !nil
            pushClassNotification(meeting)
        }
        
        
        notificationTimer = NSTimer.scheduledTimerWithTimeInterval(
            timerInterval,
            target: self,
            selector: Selector("notificationTask"),
            userInfo: nil,
            repeats: false)
    }
    
    func pushClassNotification(meeting: ClassMeetings) {
        UIApplication.sharedApplication().cancelAllLocalNotifications()
        
        var localNotification: UILocalNotification = UILocalNotification()
        localNotification.alertAction = "Next Class"
        localNotification.alertBody = meeting.subject + " - room: " + meeting.room + "\n" + todFormatter.stringFromDate(meeting.startTime) + " to " + todFormatter.stringFromDate(meeting.stopTime)
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
    }
    
    func isDateAHoliday(date: NSDate) -> Bool {
        let sparqDB = FMDatabase(path: databasePath as String)
        
        if sparqDB.open() {
            let date = dateFormatter.stringFromDate(date)
            
            
            let stmt = "SELECT COUNT(date) as count FROM Holidays WHERE date = \(date)"
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
    
    /*
    // Override to support conditional editing of the table view.
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the specified item to be editable.
    return true
    }
    */
    
    /*
    // Override to support editing the table view.
    override func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
    if editingStyle == .Delete {
    // Delete the row from the data source
    tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Fade)
    } else if editingStyle == .Insert {
    // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }
    }
    */
    
    /*
    // Override to support rearranging the table view.
    override func tableView(tableView: UITableView, moveRowAtIndexPath fromIndexPath: NSIndexPath, toIndexPath: NSIndexPath) {
    
    }
    */
    
    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(tableView: UITableView, canMoveRowAtIndexPath indexPath: NSIndexPath) -> Bool {
    // Return NO if you do not want the item to be re-orderable.
    return true
    }
    */
    
    /*
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    }
    */
    
}
