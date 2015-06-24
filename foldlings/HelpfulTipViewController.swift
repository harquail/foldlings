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

    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        println(randomTip())
//        tipText.text = randomTip()["text"]

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    
        let tip = randomTip()
        
        tipLabel.text = tip["label"]
        tipText.selectable = true
        tipText.text = tip["text"]
        tipText.selectable = false
        let imageName =  UIImage(named: tip["image"]!)
//        
//        if imageName!.pathExtension == "mp4"{
//        
//        }
        
        tipImage.image = UIImage(named: tip["image"]!)

    }
    
    // return a random tip object
    private func randomTip() -> Dictionary<String, String>{

    let path = NSBundle.mainBundle().pathForResource("tips", ofType:"plist")
    let ray = NSArray(contentsOfFile:path!)
    let randomElement = ray!.objectAtIndex(Int(arc4random_uniform(UInt32(ray!.count)))) as! Dictionary<String, String>
    return randomElement

    }
    
    // hide status bar
    override func prefersStatusBarHidden() -> Bool {
        return true
    }
    
    //sometimes replace with video
}