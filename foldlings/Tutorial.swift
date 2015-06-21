//
//  Tutorial.swift
//  foldlings
//
//  Created by nook on 6/20/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved. All rights reserved.
//

import Foundation
import MediaPlayer

class Tutorial {
    class func video(named:String) -> MPMoviePlayerViewController{
        // video friend
        let path = NSBundle.mainBundle().pathForResource(named, ofType: "mp4")
        let pathURL = NSURL.fileURLWithPath(path!)
        let myPlayer = MPMoviePlayerViewController(contentURL: pathURL)
        myPlayer.moviePlayer.controlStyle = MPMovieControlStyle.None
        myPlayer.moviePlayer.repeatMode = .None
        myPlayer.moviePlayer.backgroundView.backgroundColor = UIColor.whiteColor()
        
        // stuff video friend in a modal popover
        myPlayer.modalPresentationStyle = .Popover
        myPlayer.preferredContentSize = CGSizeMake(582 * 0.75, 712 * 0.75)
        
        return myPlayer
    }
    
    // gets the number of significant events performed (right now, sketches made) from UAAppReviewManager
    class func numberOfSignificantEvents() -> Int{
        let key = UAAppReviewManager.keyForUAAppReviewManagerKeyType(UAAppReviewManagerKeySignificantEventCount)
        let events = UAAppReviewManager.userDefaultsObject().valueForKey(key) as! NSNumber
        return events.integerValue
    }
}