//
//  Constants.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import UIKit



let kLineWidth:CGFloat = 2.0
let kHitTestRadius = CGFloat(20.0)
let kMinLineLength = kHitTestRadius/4



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
    var warmColors: [UIColor] = [UIColor.redColor(), UIColor.yellowColor(), UIColor.magentaColor(), UIColor.orangeColor()]
    var coolColors: [UIColor] = [UIColor.greenColor(), UIColor.blueColor(), UIColor.cyanColor(), UIColor.purpleColor()]
    
    var rIndex: Int = Int(arc4random_uniform(3))
    
    var randomRed:CGFloat = CGFloat(drand48())
    var randomGreen:CGFloat = CGFloat(drand48())
    var randomBlue:CGFloat = CGFloat(drand48())
    
    if horizontal{
        return warmColors[rIndex]

    }
    return coolColors[rIndex]
    
}
