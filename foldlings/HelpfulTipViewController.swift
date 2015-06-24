//
//  HelpfulTip.swift
//  foldlings
//
//  Created by nook on 6/23/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved. All rights reserved.
//

import Foundation
import UIKit

class HelpfulTipViewController: UIViewController{

    @IBOutlet var tipLabel: UILabel!
    
    @IBOutlet var tipImage: UIImageView!
    
    @IBOutlet var tipText: UITextView!
    
    
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //sometimes replace with video
}