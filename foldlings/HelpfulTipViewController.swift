//
//  HelpfulTip.swift
//  foldlings
//
//  Created by nook on 6/23/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved. All rights reserved.
//

import Foundation
import UIKit
import Regift

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
        let imageName = tip["image"]
        
        if imageName!.pathExtension == "mp4"{
            
            println("success")
            let videoPath  = NSBundle.mainBundle().pathForResource(imageName!.stringByDeletingPathExtension, ofType: "mp4")!
            let url = NSURL(fileURLWithPath: videoPath)
            let length = tip["videoLength"]
            let gifURL = Regift.createGIFFromURL(url!, withFrameCount: length!.toInt()!*20, delayTime: 0.05, loopCount: 0)
            let gifData = NSData(contentsOfURL: gifURL!)

            tipImage.image = UIImage.animatedImageWithAnimatedGIFURL(gifURL)
        }
        else{
        tipImage.image = UIImage(named: tip["image"]!)
        }
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