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
    
    override func splitFoldByOcclusion(edge: Edge) -> [Edge] {
        var points = intersectionsWithDrivingFold
        points.append(edge.start)
        points.append(edge.end)
        points.sort({return $0.x < $1.x})
        
        println(points)
        assert(points.count == 4)
        
        let fragments = [Edge.straightEdgeBetween(points[0], end: points[1], kind: .Fold, feature: self.parent!),
            Edge.straightEdgeBetween(points[2], end: points[3], kind: .Fold, feature: self.parent!)
        ]
        
        let internalFold = Edge.straightEdgeBetween(points[1], end: points[2], kind: .Fold, feature: self)
        featureEdges?.append(internalFold)
        
        return fragments
        
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
    
    func makeDiagonalFolds(#to:CGPoint) -> CGPoint{
        let pointOnDriver = CGPointMake(to.x,self.drivingFold!.start.y)
        
        diagonalFolds.map({self.featureEdges?.remove($0)})
        diagonalFolds = [Edge.straightEdgeBetween(verticalCut.start, end: pointOnDriver, kind: .Fold, feature: self),
                         Edge.straightEdgeBetween(verticalCut.end, end: pointOnDriver, kind: .Fold, feature: self)
                        ]
        featureEdges?.extend(diagonalFolds)
        
        return pointOnDriver
    }
    
    func splitVerticalCut(){
    
        let splitter = intersectionsWithDrivingFold.first!
        let paths = splitPath(verticalCut!.path, withPoint: splitter)
        
        let ps = [paths.0,paths.1]
    
        func closestOf(point:CGPoint,pts:[CGPoint]) -> CGPoint{
            
            var closest = CGPointZero
            var minDist = CGFloat.max
            for p in pts{
                let dist = ccpDistance(point, p)
                if( dist < minDist){
                    closest = p
                    minDist = dist
                }
            }
            return closest
        }

        
        for p in ps{
            let possibleEnds = [splitter, verticalCut.start, verticalCut.end]
            let e = Edge(start: closestOf(p.firstPoint(),possibleEnds), end: closestOf(p.lastPoint(),possibleEnds), path: p, kind: .Cut, isMaster: false, feature: self)
            println(e)
            featureEdges?.append(e)
        }
        
        
        featureEdges?.remove(verticalCut)
    }
    
    override func containsPoint(point: CGPoint) -> Bool {
        // construct a path that encloses the v-fold
        var enclosingPath = UIBezierPath(CGPath: verticalCut!.path.CGPath)
        enclosingPath.addLineToPoint(diagonalFolds[1].end)
        enclosingPath.addLineToPoint(verticalCut!.start)
        enclosingPath.closePath()

        return enclosingPath.containsPoint(point)
        
    }
    
    
    
}