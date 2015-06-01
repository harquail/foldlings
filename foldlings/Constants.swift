//
//  Constants.swift
//  foldlings
//
//

import Foundation
import UIKit



let kLineWidth:CGFloat = 2.0
let kHitTestRadius = CGFloat(10.0)
let kMinLineLength = kHitTestRadius/2



func getRandomColor(alpha:CGFloat) -> UIColor{
    var randomRed:CGFloat = CGFloat(drand48())
    var randomGreen:CGFloat = CGFloat(drand48())
    var randomBlue:CGFloat = CGFloat(drand48())
    return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: alpha)
}

func getRandomGray(alpha:CGFloat) -> UIColor{
//    return UIColor.whiteColor()
    
    var randomHue:CGFloat =  1 - CGFloat(drand48())/1.3
    return UIColor(red: randomHue, green: randomHue, blue: randomHue, alpha: alpha)
}

//benchmark
func printTimeElapsedWhenRunningCode(title:String, operation:()->()) {
    let startTime = CFAbsoluteTimeGetCurrent()
    operation()
    let timeElapsed = CFAbsoluteTimeGetCurrent() - startTime
    println("Time elapsed for \(title): \(timeElapsed) s")
}


func getSmartRandomColor(alpha:CGFloat, horizontal: Bool) -> UIColor{
    var randomRed:CGFloat = CGFloat(drand48())
    var randomGreen:CGFloat = CGFloat(drand48())
    var randomBlue:CGFloat = CGFloat(drand48())
    return UIColor(red: randomRed, green: randomGreen, blue: randomBlue, alpha: alpha)
}

func getOrientationColor(horizontal: Bool) -> UIColor{
    if horizontal{
        return UIColor(red:0.4, green:0.2, blue:0.4, alpha:0.8)

    }
    return UIColor(red:0.2, green:0.4, blue:0.4, alpha:0.8)
    
}
