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
    
    var intersectionsOnVerticalCut:[CGPoint] = []
    var cachedEnclosingPath:UIBezierPath? = nil

    
    override init(start: CGPoint) {
        super.init(start: start)
        verticalCut = Edge.straightEdgeBetween(start, end: start, kind: .Cut, feature: self)
        featureEdges = []
        featureEdges?.append(verticalCut)
    }


    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        //reconstrcut from path, because saving the edge directly fails without twins/adjancency
        let verticalCutPath = aDecoder.decodeObjectForKey("verticalCutPath") as! UIBezierPath
        verticalCut = Edge(start: verticalCutPath.firstPoint(), end: verticalCutPath.lastPoint(), path: verticalCutPath)
        diagonalFolds = aDecoder.decodeObjectForKey("diagonalFolds") as! [Edge]
        intersectionsWithDrivingFold = convertToCGPoints((aDecoder.decodeObjectForKey("intersectionsWithDrivingFold") as! NSArray))
        intersectionsOnVerticalCut = convertToCGPoints((aDecoder.decodeObjectForKey("intersectionsOnVerticalCut") as! NSArray))
        cachedEnclosingPath = aDecoder.decodeObjectForKey("cachedEnclosingPath") as? UIBezierPath
    }
    
    override func encodeWithCoder(aCoder: NSCoder) {
        verticalCut.adjacency = diagonalFolds
        verticalCut.twin = Edge(start: verticalCut.start, end: verticalCut.end, path: verticalCut.path)
        aCoder.encodeObject(verticalCut.path, forKey: "verticalCutPath")
        aCoder.encodeObject(diagonalFolds, forKey: "diagonalFolds")
        aCoder.encodeObject(convertToNSArray(intersectionsWithDrivingFold), forKey: "intersectionsWithDrivingFold")
        aCoder.encodeObject(convertToNSArray(intersectionsOnVerticalCut), forKey: "intersectionsOnVerticalCut")
        aCoder.encodeObject(cachedEnclosingPath, forKey: "cachedEnclosingPath")
        super.encodeWithCoder(aCoder)
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
            intersectionsOnVerticalCut.append(intersects!.first!)
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
    
// OLD WAY, DONT DELETE YET
//    func makeInternalFold(){
//
//        var startPointA = diagonalFolds[0].start
//        var startPointB =  diagonalFolds[1].start
//        var endPointA = diagonalFolds[0].end
//        var endPointB = diagonalFolds[1].end
//        
//        let vectorA = ccpSub(startPointA, endPointA)
//        let vectorB = ccpSub(startPointB, endPointB)
//        let vectorDriving = ccpSub(drivingFold!.start,drivingFold!.end)
//        
//        //         /|
//        //        / |
//        //     A /  |
//        //      /Φ  |    driving fold
//        //  - - \---|- - - - - - - - - - -
//        //       \Θ \
//        //     B  \  |
//        //         \  \
//        //          \ \
//        //           \|
//        let Φ = ccpAngleSigned(vectorA,vectorDriving)
//        let Θ = ccpAngleSigned(vectorB, vectorDriving)
//        
//        
//        var twoPhi = 2*Φ
//        if(twoPhi < Float(-M_PI)){
//            twoPhi = Float(twoPhi - Float(2*M_PI))
//        }
//        
//        var twoTheta = 2*Θ
//        if(twoTheta > Float(M_PI)){
//            twoTheta = Float(twoTheta + Float(2*M_PI))
//        }
//        
//        //make line really long so it definitely intersects cut
//        startPointA = ccpAdd(startPointA, ccpMult(vectorA, 2))
//        startPointA = ccpRotateByAngle(startPointA, endPointA, Float(twoPhi))
//        let internalFoldA = Edge.straightEdgeBetween(startPointA, end: endPointA, kind: Edge.Kind.Fold, feature: self)
//        let interceptA = PathIntersections.intersectionsBetween(internalFoldA.path, path2: verticalCut.path)
//        
//        // if there was an intersection, take this edge
//        if (interceptA != nil){
//            let foldToAdd = Edge.straightEdgeBetween(interceptA![0], end: endPointA, kind: Edge.Kind.Fold, feature: self)
//            featureEdges?.append(foldToAdd)
//            intersectionsOnVerticalCut.append(interceptA![0])
//
//        }
//        else{
//            //make line really long so it definitely intersects cut
//            startPointB = ccpAdd(startPointB, ccpMult(vectorB, 2))
//            startPointB = ccpRotateByAngle(startPointB, endPointB, Float(twoTheta))
//            let internalFoldB = Edge.straightEdgeBetween(startPointB, end: endPointB, kind: Edge.Kind.Fold, feature: self)
//            let interceptB = PathIntersections.intersectionsBetween(internalFoldB.path, path2: verticalCut.path)
//            let foldToAdd = Edge.straightEdgeBetween(interceptB![0], end: endPointB, kind: Edge.Kind.Fold, feature: self)
//            featureEdges?.append(foldToAdd)
//            intersectionsOnVerticalCut.append(interceptB![0])
//        }
//
////        println(intersectionsOnVerticalCut)
//        // split vertical cut
////        println(featureEdges!.count)
//        featureEdges?.remove(verticalCut)
//        let appendees = verticalCut.edgeSplitByPoints(intersectionsOnVerticalCut)
////        println("TO APPEND:")
////        println(appendees)
//        featureEdges?.extend(appendees)
//        
//    }

    
    func makeInternalFold(){
        
        var startPointA = diagonalFolds[0].start
        var startPointB =  diagonalFolds[1].start
        var endPointA = diagonalFolds[0].end
        var endPointB = diagonalFolds[1].end
        
        let vectorA = ccpSub(startPointA, endPointA)
        let vectorB = ccpSub(startPointB, endPointB)
        let vectorDriving = ccpSub(drivingFold!.start,drivingFold!.end)
        
        //         /|
        //        / |
        //     A /  |
        //      /Φ  |    driving fold
        //  - - \---|- - - - - - - - - - -
        //       \Θ \
        //     B  \  |
        //         \  \
        //          \ \
        //           \|
        var Φ = ccpAngleSigned(vectorA,vectorDriving)
        var Θ = ccpAngleSigned(vectorB, vectorDriving)
        
        
//        var twoPhi = 2*Φ
        if(Φ < Float(-M_PI/2)){
            Φ = Float(Φ - Float(M_PI))
        }
        
//        var twoTheta = 2*Θ
        if(Θ > Float(M_PI/2)){
            Θ = Float(Θ + Float(M_PI))
        }
//        make line really long so it definitely intersects cut
                startPointA = ccpAdd(startPointA, ccpMult(vectorA, 2))
                startPointA = ccpRotateByAngle(startPointA, endPointA, Float(-Θ))
                let internalFoldA = Edge.straightEdgeBetween(startPointA, end: endPointA, kind: Edge.Kind.Fold, feature: self)
                let interceptA = PathIntersections.intersectionsBetween(internalFoldA.path, path2: verticalCut.path)
        
//        featureEdges?.append(internalFoldA)

                // if there was an intersection, take this edge
                if (interceptA != nil){
                    let foldToAdd = Edge.straightEdgeBetween(interceptA![0], end: endPointA, kind: Edge.Kind.Fold, feature: self)
                    featureEdges?.append(foldToAdd)
                    intersectionsOnVerticalCut.append(interceptA![0])
        
                }
                else{
                    //make line really long so it definitely intersects cut
                    startPointB = ccpAdd(startPointB, ccpMult(vectorB, 2))
                    startPointB = ccpRotateByAngle(startPointB, endPointB, Float(-Φ))
                    let internalFoldB = Edge.straightEdgeBetween(startPointB, end: endPointB, kind: Edge.Kind.Fold, feature: self)
                    let interceptB = PathIntersections.intersectionsBetween(internalFoldB.path, path2: verticalCut.path)
//                    featureEdges?.append(internalFoldB)

                    let foldToAdd = Edge.straightEdgeBetween(interceptB![0], end: endPointB, kind: Edge.Kind.Fold, feature: self)
                    featureEdges?.append(foldToAdd)
                    intersectionsOnVerticalCut.append(interceptB![0])
                }
        
        //        println(intersectionsOnVerticalCut)
                // split vertical cut
        //        println(featureEdges!.count)
                featureEdges?.remove(verticalCut)
                let appendees = verticalCut.edgeSplitByPoints(intersectionsOnVerticalCut)
        //        println("TO APPEND:")
        //        println(appendees)
                featureEdges?.extend(appendees)

        
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
    
    override func validate() -> (passed: Bool, error: String) {
        let validity = super.validate()
        if(!validity.passed){
            return validity
        }
        
        // clever test for concave paths: close the vertical cut's path and test whether vfold end point is inside it
        var testPath = UIBezierPath(CGPath: verticalCut.path.CGPath)
        testPath.closePath()
        if(testPath.containsPoint(diagonalFolds[0].end)){
            return (false,"Angle too shallow")
        }
        
        if(!tooShortEdges().filter({$0.kind == Edge.Kind.Fold}).isEmpty){
            return (false,"Edges too short")
        }

        return (true,"")
    }
}