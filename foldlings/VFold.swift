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
    var verticalCut: Edge!
    // diagonal folds that intersect with driving fold
    var diagonalFolds:[Edge] = []
    var interpolationPoints:[AnyObject] = []
    var lastUpdated = NSDate(timeIntervalSinceNow: 0)
    
    
    override init(start: CGPoint) {
        super.init(start: start)
        verticalCut = Edge.straightEdgeBetween(start, end: start, kind: .Cut, feature: self)
    }

    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // the bezier path through the touch points
    func pathThroughTouchPoints(newPoint:CGPoint) -> UIBezierPath{
        
        //if the points are far enough apart, make a new path
        if interpolationPoints.isEmpty || Float(ccpDistance((interpolationPoints.last! as! NSValue).CGPointValue(), newPoint)) > 2{
            lastUpdated = NSDate(timeIntervalSinceNow: 0)
            
            interpolationPoints.append(NSValue(CGPoint: newPoint))
            
            
            verticalCut.path = pathThroughCatmullPoints(interpolationPoints as! [NSValue], false)
        }
        return verticalCut?.path ?? UIBezierPath()
    }
    
    
    
}