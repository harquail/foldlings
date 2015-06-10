//
//  VFold.swift
//  foldlings
//
//  Created by nook on 6/9/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved. All rights reserved.
//

import Foundation

class VFold:FoldFeature{
    // the cut that crosses the driving fold
    var verticalCut: Edge?
    // diagonal folds that intersect with driving fold
    var diagonalFolds:[Edge] = []
    var interpolationPoints:[AnyObject] = []
    var lastUpdated = NSDate(timeIntervalSinceNow: 0)
    
    // the bezier path through the touch points
    func pathThroughTouchPoints() -> UIBezierPath{
        
        //if the points are far enough apart, make a new path
        if Float(ccpDistance((interpolationPoints.last! as! NSValue).CGPointValue(), endPoint!)) > 2{
            lastUpdated = NSDate(timeIntervalSinceNow: 0)
            
            interpolationPoints.append(NSValue(CGPoint: endPoint!))
            
            //set the curve to be closed when we are close to the endpoint
            var closed = false
            if interpolationPoints.count > 7
                &&
                ccpDistance((interpolationPoints.first! as! NSValue).CGPointValue(), endPoint!) < kMinLineLength*2{
                    closed = true
            }
            return pathThroughCatmullPoints(interpolationPoints as! [NSValue], closed)
        }
        return verticalCut?.path ?? UIBezierPath()
    }
    
}