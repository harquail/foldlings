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
    //the intersection points calculated by featureSpansFold & used for occlusion
    var intersectionsWithDrivingFold:[CGPoint] = []

    
    override init(start: CGPoint) {
        super.init(start: start)
        verticalCut = Edge.straightEdgeBetween(start, end: start, kind: .Cut, feature: self)
        featureEdges = []
        featureEdges?.append(verticalCut)
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
    
    override func featureSpansFold(fold: Edge) -> Bool {
        
        var intersects = PathIntersections.intersectionsBetween(fold.path,path2: self.verticalCut.path)
        
        let spans = (intersects?.count ?? 0) == 1
        
        if spans{
            intersectionsWithDrivingFold = intersects!
        }
        
        return spans
    }
    
    func makeDiagonalFolds(#to:CGPoint){
        
        let pointOnDriver = CGPointMake(to.x,self.drivingFold!.start.y)
        
        diagonalFolds.map({self.featureEdges?.remove($0)})
        diagonalFolds = [Edge.straightEdgeBetween(verticalCut.start, end: pointOnDriver, kind: .Fold, feature: self),
                         Edge.straightEdgeBetween(verticalCut.end, end: pointOnDriver, kind: .Fold, feature: self)
                        ]
        featureEdges?.extend(diagonalFolds)
    }
    
    
}