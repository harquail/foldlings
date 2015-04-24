//
//  FreeForm.swift
//  foldlings
//
//  Created by nook on 3/24/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

class FreeForm:FoldFeature{
    
    var path: UIBezierPath?
    var interpolationPoints:[AnyObject] = []
    var lastUpdated:NSDate = NSDate(timeIntervalSinceNow: 0)
    var cachedPath:UIBezierPath? = UIBezierPath()
    var closed = false
    //the intrsection points calculated by featureSpansFold & used for occlusion
    var intersectionsWithDrivingFold:[CGPoint] = []
    var intersections:[CGPoint] = []
    
    
    override init(start: CGPoint) {
        super.init(start: start)
        interpolationPoints.append(NSValue(CGPoint: start))
    }
    
    required init(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func getEdges() -> [Edge] {
        
        //if there are cached edges, return them
        if let cache = cachedEdges {
            println("freeform cache HIT!!")
            return cache
        }
        
        if let p = path{
            
            let edge = Edge(start: p.firstPoint(), end: p.lastPoint(), path: p, kind: .Cut, isMaster: false)
            
            return [edge]
        }
        else{
            return [Edge.straightEdgeBetween(startPoint!, end: CGPointZero, kind: .Cut)]
        }
    }
    
    
    /// splits a path at each of the points, which are already known to be on it
    func pathSplitByPoints(path:UIBezierPath,breakers:[CGPoint]) ->[UIBezierPath]{
        
        //intersectin points
        var breaks = breakers
        let elements = path.getPathElements()
        var points = getSubdivisions(elements)
        var pointBins: [[CGPoint]] = [[]]
        
        // distance between point on curve and intersection point, for splitting
        var minDist = CGFloat(1.0)
        
        //collect points into bins, making a new bin at every braker
        for (i, point) in enumerate(points)
        {
            pointBins[pointBins.count-1].append(point);
            
            for (var i = 0; i<breaks.count; i++){
                if(ccpDistance(point,breaks[i]) < minDist){
                    
                    //add break point instead of point, to ensure all paths have start & end points that exactly match others'
                    pointBins[pointBins.count-1].append(breaks[i])
                    pointBins.append([breaks[i]])
                    breaks.remove(breaks[i])
                }
            }
        }
        
        var paths:[UIBezierPath] = []
        //make paths from the point bins
        for bin in pointBins{
            
            
            
            //            var p = UIBezierPath.interpolateCGPointsWithCatmullRom(convertToNSArray(bin) as [AnyObject], closed: false, alpha: 1.0)
            
            var p = pathFromPoints(smoothPoints(bin))
            
            //get top and bottom folds
            let maxFold = self.horizontalFolds.maxBy({$0.start.y})
            let minFold = self.horizontalFolds.minBy({$0.start.y})
            
            //discard paths whose centroid is above or below top & bottom folds
            if(p.center().y > maxFold!.start.y || p.center().y < minFold!.start.y ){
                continue
            }
            
            paths.append(p)
        }
        
        return paths
        
    }
    
    func pathSplitByPointsNew(path:UIBezierPath,breakers:[CGPoint]) ->[UIBezierPath]{
        
        var closestElements = [CGPathElement](count: breakers.count, repeatedValue: CGPathElement())
        var closestElementsDists = [CGFloat](count: breakers.count, repeatedValue:CGFloat.max)
        
        let returnee = UIBezierPath()
        
        for var i = 0; i < Int(path.elementCount()); i++ {
            let el = path.elementAtIndex(i)
            let prevPoint:CGPoint
            if(i == 1){
                let elPrev = path.elementAtIndex(0)
                prevPoint = elPrev.points[0]
            }
            else{
                let elPrev = path.elementAtIndex(i-1)
                prevPoint = elPrev.points[2]
            }
            let points = el.points
            
            switch(el.type.value){
            case kCGPathElementAddCurveToPoint.value :
                //replace with moveToPoint


                for (i,breaker) in enumerate(breakers){
                    
                    for j:Float in [0.1,1]{
                    
                        
                        let p = CGPointMake(bezierInterpolation(CGFloat(j), prevPoint.x, points[0].x, points[1].x, points[2].x), bezierInterpolation(CGFloat(j), prevPoint.y, points[0].y, points[1].y, points[2].y));
                        
                        let dist = ccpDistance(p, breaker)
                        if ( dist < closestElementsDists[i]){
                            closestElementsDists[i] = dist
                            closestElements[i] = el
                        }
                        
                    }
                    
//
//                    if (dist < closestElementsDists[i]){
//                        closestElementsDists[i] = dist
//                        closestElements[i] = el
//                    }
                    
                }
                
                //                returnee.addCurveToPoint(points[2], controlPoint1: points[0], controlPoint2: points[1])
                
            case kCGPathElementCloseSubpath.value : returnee.closePath()
            default: println("unexpected")
                
                
            }
        }
        
        //this second loop is less bad than it looks, because elements are cached by PerformanceBezier
        for var i = 0; i < Int(path.elementCount()); i++ {
            
            //            var points:[CGPoint] = []
            let el = path.elementAtIndex(i)
            let prevPoint:CGPoint
            if(i == 1){
                prevPoint = el.points[0]
            }
            else{
                prevPoint = el.points[2]
            }
            let points = el.points
            
            switch(el.type.value){
            case kCGPathElementMoveToPoint.value : returnee.moveToPoint(points[0])
            case kCGPathElementAddLineToPoint.value : println("line")
            case kCGPathElementAddQuadCurveToPoint.value : println("quad")
            case kCGPathElementAddCurveToPoint.value :
                
                
                var pointsEqual = {(element:CGPathElement) -> (Bool) in return CGPointEqualToPoint(el.points[2], element.points[2])}
                
                if(contains(closestElements, pointsEqual)){
                    println("FOUND CLOSE")
                    returnee.moveToPoint(points[2])
//            points[2]
                }
                else{
                    println("added")
                    returnee.addCurveToPoint(points[2], controlPoint1: points[0], controlPoint2: points[1])
                }
            case kCGPathElementCloseSubpath.value : returnee.closePath()
            default: println("unexpected")
            }
        }
        
        //
        //            for (var i = 1; i < els.count; i++) {
        //                currPath = els[i]
        //                switch (currPath.type.value) {
        //                case kCGPathElementMoveToPoint.value:
        //                    let p = currPath.points[0].CGPointValue()
        //
        //                case kCGPathElementAddLineToPoint.value:
        //                    let p = currPath.points[0].CGPointValue()
        //                    outPath.addLineToPoint(p)
        //
        //                case kCGPathElementAddQuadCurveToPoint.value:
        //                    let p1 = currPath.points[0].CGPointValue()
        //                    let p2 = currPath.points[1].CGPointValue()
        //                    outPath.addQuadCurveToPoint(p2, controlPoint: p1)
        //
        //                case kCGPathElementAddCurveToPoint.value:
        //                    let p1 = currPath.points[0].CGPointValue()
        //                    let p2 = currPath.points[1].CGPointValue()
        //                    let p3 = currPath.points[2].CGPointValue()
        //                    outPath.addCurveToPoint(p3, controlPoint1: p1, controlPoint2: p2)
        //                default:
        //                    break
        //                }
        
        
        //            //TODO: Fix this not-super terrible, but still bad shit (pathFromPoints)
        //            let bounds = pathFromPoints(points).bounds
        //            let length = max(bounds.width, bounds.height)
        //            for var t:CGFloat = 0.0; t <= 1.00001; t += increments / length {
        //                let point = CGPointMake(bezierInterpolation(t, points[0].x, points[1].x, points[2].x, points[3].x), bezierInterpolation(t, points[0].y, points[1].y, points[2].y, points[3].y));
        //                npoints.append(point);
        
        //get element of each breaker
        //split elements at t
        return [returnee]
    }
    
    /// this function should be called exactly once, when the feature is created at the end of a pan gesture
    func freeFormEdgesSplitByIntersections() ->[Edge]{
        
        println(intersections)
        /// splits the path into multiple edges based on intersection points
        var paths = pathSplitByPointsNew(path!,breakers: intersections)
        //        pathSplitByPoints(path!, breakers:intersections)
        var edges:[Edge] = []
        
        //create edges from split paths
        for p in paths{
            edges.append(Edge(start: p.firstPoint(), end: p.lastPoint(), path: p, kind: .Cut, isMaster: false))
        }
        
        return edges
    }
    
    
    
    //the bezier path through a set of points
    func pathThroughTouchPoints() -> UIBezierPath{
        
        //if the points are far enough apart, make a new path
        //(Float(ccpDistance((interpolationPoints.last! as! NSValue).CGPointValue(), endPoint!)) > 2
        if (cachedPath == nil || (Float(ccpDistance((interpolationPoints.last! as! NSValue).CGPointValue(), endPoint!)) > 2)){
            lastUpdated = NSDate(timeIntervalSinceNow: 0)
            
            interpolationPoints.append(NSValue(CGPoint: endPoint!))
            
            //set the curve to be closed when we are close to the endpoint
            var closed = false
            if interpolationPoints.count > 7
                &&
                ccpDistance((interpolationPoints.first! as! NSValue).CGPointValue(), endPoint!) < kMinLineLength*2{
                    closed = true
            }
            
            //if ther are enough points, draw a full curve
            if(interpolationPoints.count > 3){
                let path = UIBezierPath()
                
                //the line between the first two points, which is not part of the catmull-rom curve
                if(!closed){
                    path.moveToPoint(interpolationPoints[0].CGPointValue())
                    path.addLineToPoint(interpolationPoints[1].CGPointValue())
                }
                
                
                //                path.appendPath(pathFromPoints(convertToCGPoints(interpolationPoints)))
                path.appendPath(UIBezierPath.interpolateCGPointsWithCatmullRom(interpolationPoints as! [NSArray], closed: closed,alpha: 1.0))
                
                //                path.appendPath(UIBezierPath.interpolateCGPointsWithHermite(interpolationPoints, closed: closed))
                
                //the line to the currrent touch point from the end
                if(!closed){
                    path.addLineToPoint(endPoint!)
                }
                cachedPath = path
                return path
                
            }
            else{
                //for low numbers of points, return a straight line
                let path = UIBezierPath()
                path.moveToPoint(startPoint!)
                path.addLineToPoint(endPoint!)
                cachedPath = path
                return path
            }
            
        }
        return cachedPath!
    }
    
    override func featureSpansFold(fold: Edge) -> Bool {
        
        //first, test if y value is within cgrect ys
        let lineRect = CGRectMake(fold.start.x,fold.start.y,fold.end.x - fold.start.x,1)
        
        //if the line does not intersect the bezier's bounding box, the fold can't span it
        if(!CGRectIntersectsRect(self.boundingBox()!,lineRect)){
            return false
        }
        else{
            
            if let intersects = PathIntersections.intersectionsBetween(fold.path,path2: self.path!){
                
                intersectionsWithDrivingFold = intersects
                intersections += intersects
                return true
            }
            return false
        }
        
    }
    /// This bounding box does not include control points, used for scanline
    override func boundingBox() -> CGRect? {
        return path?.boundsForPath()
    }
    
    /// boxFolds can be deleted
    /// folds can be added only to leaves
    override func tapOptions() -> [FeatureOption]?{
        var options:[FeatureOption] = []
        options.append(.DeleteFeature)
        if(self.isLeaf()){
            options.append(.AddFolds)
        }
        
        return options
        
    }
    
    private func tryIntersectionTruncation(testPathOne:UIBezierPath,testPathTwo:UIBezierPath, maxIntercepts:Int = 100) -> Bool{
        
        print("trunc. ")
        
        var points = PathIntersections.intersectionsBetween(testPathOne, path2: testPathTwo)
        
        if let ps = points{
            if(ps.count%2 == 0 && ps.count <= maxIntercepts){
                print(" points")
                var i = 0
                var edgesToAdd:[Edge] = []
                while(i<ps.count){
                    print(" \(i) ")
                    
                    if(ps.count>i+1){
                        //try making a straight edge between the points
                        let edge = Edge.straightEdgeBetween(ps[i], end: ps[i+1], kind: .Fold)
                        // if the line's center is inside the path, add the edge and go to the next pair
                        print(" just before contains point ")
                        if(testPathTwo.containsPoint(edge.path.center()) && ccpDistance(ps[i], ps[i + 1]) > kMinLineLength){
                            edgesToAdd.append(edge)
                            print(" i+2 ")
                            i += 2
                            continue
                        }
                    }
                    //otherwise, try the next point
                    //                    else{
                    print(" i+1 ")
                    i += 1
                    //                    }
                }
                
                //if there are edges to add, add them, and return that the trucation succeeded
                if(edgesToAdd.count>0){
                    intersections.extend(ps)
                    self.horizontalFolds.extend(edgesToAdd)
                    self.cachedEdges!.extend(edgesToAdd)
                    return true
                    
                }
                
            }
        }
        return false
    }
    
    
    /// creates intersections with top, bottom and middle folds; also creates horizontal folds
    func truncateWithFolds(){
        
        if let driver = drivingFold, p = path{
            
            let box = self.boundingBox()
            // scan line is the line we use for intersection testing
            var scanLine:Edge = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut)
            
            var yTop:CGFloat = 0;
            var yBottom:CGFloat = 0;
            
            
            //hop defines the amount to move each time through the loop, intercepts is the maximum number of accepatable intercepts, endSearchAtY is the
            func truncate(hop:CGFloat,intercepts:Int,endSearchAtY:CGFloat) -> CGFloat?{
                
                //move scanline up to find bottom intersection point
                while(abs(scanLine.path.firstPoint().y - endSearchAtY) > hop){
                    
                    var moveDown = CGAffineTransformMakeTranslation(0, hop);
                    scanLine.path.applyTransform(moveDown)
                    
                    let truncated = tryIntersectionTruncation(scanLine.path,testPathTwo: self.path!, maxIntercepts: intercepts)
                    if(truncated){
                        //                        println("success! \()")
                        return scanLine.path.firstPoint().y
                    }
                }
                return nil
            }
            
            
            let scanLineStartingAtTop = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut)
            
            scanLine = scanLineStartingAtTop
            //try truncting at bottom with 2 intersections first, then any number of intersections if that fails in the first 50 points
            if let top = truncate(3,2,box!.origin.y+20){
                
                yTop = top
            }
            else{
                scanLine = scanLineStartingAtTop
                if let top = truncate(3,100,driver.start.y){
                    yTop = top
                }
                
            }
            
            
            let scanLineStartingAtBottom =  Edge.straightEdgeBetween(CGPointMake(box!.origin.x, box!.origin.y + box!.height), end: CGPointMake(box!.origin.x + box!.width, box!.origin.y + box!.height), kind: .Cut)
            scanLine = scanLineStartingAtBottom
            //try truncting at bottom with 2 intersections first, then any number of intersections if that fails in the first 50 points
            if let bottom = truncate(-5,2,box!.origin.y + box!.height - 20){
                
                yBottom = bottom
            }
            else{
                scanLine = scanLineStartingAtBottom
                if let bottom = truncate(-3,100,driver.start.y){
                    
                    yBottom = bottom
                }
                
            }
            
            //MIDDLE FOLD
            //move scan line to position that will make the shape fold to 90º
            let masterdist = yTop - driver.start.y
            let moveToCenter = CGAffineTransformMakeTranslation(0, masterdist)
            // scanline is at the bottom fold position, so we just move it up by masterdist
            scanLine.path.applyTransform(moveToCenter)
            
            //get the intersections with the mid fold
            //            let points = PathIntersections.intersectionsBetweenCGPaths(scanLine.path.CGPath, p2: self.path!.CGPath)
            //            intersections.extend(points!)
            
            
            let middleFolds = tryIntersectionTruncation(scanLine.path,testPathTwo: pathThroughTouchPoints())
            if(!middleFolds){
                println("\(intersections)");
                println("\(intersectionsWithDrivingFold)");
                self.state = .Invalid
                println("FAILED TO INTERSECT WITH MIDDLE")
            }
            //            // add a fold between those intersection points
            //            let midLine = Edge.straightEdgeBetween(points![0], end: points![1], kind: .Fold)
            //            self.horizontalFolds.append(midLine)
            //            self.cachedEdges!.append(midLine)
        }
    }
    
    //split folds around intersections with driving fold
    override func splitFoldByOcclusion(edge: Edge) -> [Edge] {
        
        let start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if intersectionsWithDrivingFold.count == 0{
            return [edge]
        }
        
        
        let firstPiece = Edge.straightEdgeBetween(start, end: intersectionsWithDrivingFold.first!, kind: .Fold)
        returnee.append(firstPiece)
        
        var brushTip = intersectionsWithDrivingFold[0]
        
        //skip every other point, so we don't make edges inside shape
        for (var i = 1; i < intersectionsWithDrivingFold.count-1; i+=2){
            
            brushTip = intersectionsWithDrivingFold[i]
            let brushTipTranslated = CGPointMake(intersectionsWithDrivingFold[i+1].x,brushTip.y)
            let piece = Edge.straightEdgeBetween(brushTip, end: brushTipTranslated, kind: .Fold)
            returnee.append(piece)
        }
        
        let finalPiece = Edge.straightEdgeBetween(intersectionsWithDrivingFold.last!, end: end, kind: .Fold)
        returnee.append(finalPiece)
        return returnee
    }
    
    
}