//
//  ScheduleTableViewController.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/22/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import UIKit

class ScheduleTableViewController: UITableViewController, UITableViewDelegate, UITableViewDataSource {
    
    var dayCount = 0
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        dayCount = NSUserDefaults.standardUserDefaults().integerForKey("dayCount")
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
        let cell:ClassTableViewCell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! ClassTableViewCell
        
        if let h = holidays[dateFormatter.stringFromDate(today)] {
            cell.subjectImage?.image = UIImage(named: "holiday.png")
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
                cell.subjectImage?.image = UIImage(named: "icn_default.png")
            }
            cell.subjectLabel?.text = c.subject
            cell.roomLabel?.text = "Room: \(c.room)"
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
