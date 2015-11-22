//
//  ViewController.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 6/18/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    let gl = CAGradientLayer()
    
    var tableView:UITableView?
    var items = NSMutableArray();
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        }
    
    override func viewWillAppear(animated: Bool) {
        
        // background setup
        // #3DFCBC
        let left = UIColor(red: 61/255.0, green: 252/255.0, blue: 189/255.0, alpha: 1.0)
        // #1279bd
        let right = UIColor(red: 18/255.0, green: 121/255.0, blue: 189/255.0, alpha: 1.0).CGColor as CGColorRef
        
        // 2
        gl.frame = self.view.bounds
        
        gl.colors = [left, right]
        gl.locations = [0.0,1.0]

        
        
        let frame:CGRect = CGRect(x:0, y:100, width:self.view.frame.width, height:self.view.frame.height-100)
        self.tableView = UITableView(frame: frame)
        self.tableView?.dataSource = self
        self.tableView?.delegate = self
        self.view.addSubview(self.tableView!)
        
    }
    
//    // how many sections are in the table?
//    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
//        return 1;
//    }
//    
//    // how many sections are in the table?
//    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        return items.count; // TODO number of Periods
//    }
//    
//    // what is the cell content?
//    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
//        let cell = UITableViewCell()
//        
//        var (name,location) = people[indexPath.row]
//        
//        
//        return cell
//    }
    
}
