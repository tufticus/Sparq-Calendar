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
        self.tblClasses.reloadData()
        
    }
    
    override func viewWillAppear(animated: Bool) {
        dateFormatter.dateFormat = "yyyy-MM-dd"
        dateFormatter.timeZone = NSTimeZone.localTimeZone()
        timeFormatter.dateFormat = "HH:mm:ss"
        timeFormatter.timeZone = NSTimeZone.localTimeZone()
        todFormatter.dateFormat = "h:mm a"
        todFormatter.timeZone = NSTimeZone.localTimeZone()
        
        if schedule.version == -1 || days.count <= 0 {
            loadScheduleDaysAndHolidays()
        }
        
        loadTableViewForDate(today)
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
        
        let skip = countHolidays(schedule.startDate, stop: date)
        
        let cal = NSCalendar.currentCalendar()
        
        let components = cal.components(NSCalendarUnit.CalendarUnitWeekdayOrdinal|NSCalendarUnit.CalendarUnitDay, fromDate: schedule.startDate, toDate: date, options: nil)
        println("days: " + String(components.day))
        var weeks = Int(floor(Double(components.day) / 7.0))
        var remainder = (components.day % 7)
        var day = (components.day - skip - 2 * weeks) % days.count


        let sparqDB = FMDatabase(path: databasePath as String)
        if sparqDB.open() {
            var stmt = "SELECT * from Meetings WHERE day = \(day) order by startTime ASC"
            
            var results:FMResultSet? = sparqDB.executeQuery(stmt,
                withArgumentsInArray: nil)
            
            while results?.next() == true {
                var meeting = ClassMeetings()
                
                meeting.subject = results!.stringForColumn("subject")
                meeting.grade = Int(results!.intForColumn("grade"))
                meeting.room = results!.stringForColumn("room")
                meeting.startTime = timeFormatter.dateFromString(results!.stringForColumn("startTime"))!
                meeting.stopTime = timeFormatter.dateFromString(results!.stringForColumn("stopTime"))!
                meeting.period = Int(results!.intForColumn("period"))
                meeting.day = day
                meeting.dayName = days[day-1]
                meeting.section = Int(results!.intForColumn("section"))
                meeting.teacherName = results!.stringForColumn("teacherName")
                meeting.teacherEmail = results!.stringForColumn("teacherEmail")
                meeting.icon = results!.stringForColumn("icon")
                
                classes.append(meeting)
            }
            
        }

        tblClasses?.reloadData()
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
        }
        
        return cell
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
