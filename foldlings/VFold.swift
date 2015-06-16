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
    var cachedEnclosingPath:UIBezierPath? = nil

    
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
    
        // points to make edges between
        var points = intersectionsWithDrivingFold
        points.append(edge.start)
        points.append(edge.end)
        points.sort({return $0.x < $1.x})
        
        // there should be exactly 4
        assert(points.count == 4)
        
        // folds around shape
        let fragments = [Edge.straightEdgeBetween(points[0], end: points[1], kind: .Fold, feature: self.parent!),
            Edge.straightEdgeBetween(points[2], end: points[3], kind: .Fold, feature: self.parent!)
        ]
        


//        featureEdges?.append(internalFold)
        
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
    
    // v-folds span a fold if they have exactly one intersection with it
    override func featureSpansFold(fold: Edge) -> Bool {
        
        var intersects = PathIntersections.intersectionsBetween(fold.path,path2: self.verticalCut.path)
        let spans = (intersects?.count ?? 0) == 1
        
        // add intersections if found
        if spans{
            intersectionsWithDrivingFold = intersects!
        }
        
        return spans
    }
    
    // make folds between intersection point and verical cut end points, return intersection point
    func makeDiagonalFolds(#to:CGPoint) -> CGPoint{
        // calculate intersection point with driving fold
        let pointOnDriver = CGPointMake(to.x,self.drivingFold!.start.y)
        
        diagonalFolds.map({self.featureEdges?.remove($0)})
        // make folds between intersection point and vetical cut endpoints
        diagonalFolds = [Edge.straightEdgeBetween(verticalCut.start, end: pointOnDriver, kind: .Fold, feature: self),
                         Edge.straightEdgeBetween(verticalCut.end, end: pointOnDriver, kind: .Fold, feature: self)
                        ]
        
        featureEdges?.extend(diagonalFolds)
        
        return pointOnDriver
    }
    
    func makeInternalFold(){
        


        
        var startPointA = diagonalFolds[0].start
        var startPointB =  diagonalFolds[1].start
        var endPointA = diagonalFolds[0].end
        var endPointB = diagonalFolds[1].end
        
        let vectorA = ccpSub(startPointA, endPointA)
        let vectorB = ccpSub(startPointB, endPointB)
        let vectorDriving = ccpSub(drivingFold!.start,drivingFold!.end)
        
        let angleA = ccpAngleSigned(vectorA,vectorDriving)
        let angleB = ccpAngleSigned(vectorB, vectorDriving)
        
        var angleC = 2*angleA
        if(angleC < Float(-M_PI)){
            angleC = Float(angleC - Float(2*M_PI))
        }

        var angleD = 2*angleB
        if(angleD > Float(M_PI)){
            angleD = Float(angleD + Float(2*M_PI))
        }
      
        startPointA = ccpRotateByAngle(startPointA, endPointA, Float(angleC))
        let internalFoldA = Edge.straightEdgeBetween(startPointA, end: endPointA, kind: Edge.Kind.Fold, feature: self)
        featureEdges?.append(internalFoldA)
        
        startPointB = ccpRotateByAngle(startPointB, endPointB, Float(angleD))
        let internalFoldB = Edge.straightEdgeBetween(startPointB, end: endPointB, kind: Edge.Kind.Fold, feature: self)
        featureEdges?.append(internalFoldB)
        
    }

    // TODO: REFACTOR
    func splitVerticalCut(){
    
        // split the vertical cut into two paths
        let splitter = intersectionsWithDrivingFold.first!
        let paths = splitPath(verticalCut!.path, withPoint: splitter)
        let ps = [paths.0,paths.1]
        
        // return the closest point in an array to the given point
        func closestOf(point:CGPoint,pts:[CGPoint]) -> CGPoint{
            var closest = CGPointZero
            var minDist = CGFloat.max
            // for each point, find closest
            for p in pts{
                let dist = ccpDistance(point, p)
                if( dist < minDist){
                    closest = p
                    minDist = dist
                }
            }
            return closest
        }

        // make edges from paths
        for p in ps{
            let possibleEnds = [splitter, verticalCut.start, verticalCut.end]
            let e = Edge(start: closestOf(p.firstPoint(),possibleEnds), end: closestOf(p.lastPoint(),possibleEnds), path: p, kind: .Cut, isMaster: false, feature: self)
            featureEdges?.append(e)
        }
        
        featureEdges?.remove(verticalCut)
    }
    
    // things that can be done to v-folds
    override func tapOptions() -> [FeatureOption]?{
        var options:[FeatureOption] = super.tapOptions() ?? []
        options.append(.DeleteFeature)
        
        return options
        
    }
    
    override func boundingBox() -> CGRect? {
        return cachedEnclosingPath?.boundsForPath() ?? CGRectZero
    }
    
    override func containsPoint(point: CGPoint) -> Bool {
        // construct a path that encloses the v-fold
        if(cachedEnclosingPath == nil){
        var enclosingPath = UIBezierPath(CGPath: verticalCut!.path.CGPath)
        enclosingPath.addLineToPoint(diagonalFolds[1].end)
        enclosingPath.addLineToPoint(verticalCut!.start)
        enclosingPath.closePath()
        cachedEnclosingPath = enclosingPath
        }
    
        return cachedEnclosingPath!.containsPoint(point)
        
    }
    
    
    
}