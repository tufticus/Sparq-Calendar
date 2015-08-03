//
//  ClassTableViewCell.swift
//  Sparq Calendar
//
//  Created by Good Shepherd on 7/20/15.
//  Copyright (c) 2015 Sparq Calendar. All rights reserved.
//

import UIKit

class ClassTableViewCell: UITableViewCell {
    
    @IBOutlet weak var subjectImage: UIImageView!
    @IBOutlet weak var subjectLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var roomLabel: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
