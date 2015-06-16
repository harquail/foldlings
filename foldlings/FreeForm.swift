//
// FreeForm.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved



import Foundation

class FreeForm:FoldFeature
{
    
    var path: UIBezierPath?
    var interpolationPoints:[AnyObject] = []
    var lastUpdated:NSDate = NSDate(timeIntervalSinceNow: 0)
    var cachedPath:UIBezierPath? = UIBezierPath()
    var closed = false
    //the intersection points calculated by featureSpansFold & used for occlusion
    var intersectionsWithDrivingFold:[CGPoint] = []
    var intersections:[CGPoint] = []
    
    //the top and bottom edges that truncate a shape
    //these are not modified when folds are dragged, and are used to create tabs.
    var topTruncations:[Edge] = []
    var bottomTruncations:[Edge] = []

    
    override init(start: CGPoint) {
        super.init(start: start)
        interpolationPoints.append(NSValue(CGPoint: start))
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        path = aDecoder.decodeObjectForKey("path") as? UIBezierPath
        cachedPath = aDecoder.decodeObjectForKey("cachedPath") as? UIBezierPath
        interpolationPoints = aDecoder.decodeObjectForKey("points") as! [AnyObject]
        closed = aDecoder.decodeBoolForKey("closed")
        intersections = convertToCGPoints((aDecoder.decodeObjectForKey("intersections") as! NSArray))
        intersectionsWithDrivingFold =  convertToCGPoints((aDecoder.decodeObjectForKey("drivingIntersections") as! NSArray))
        topTruncations = aDecoder.decodeObjectForKey("topTruncations") as! [Edge]
        bottomTruncations = aDecoder.decodeObjectForKey("bottomTruncations") as! [Edge]
        }
    
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
    
        aCoder.encodeObject(path, forKey: "path")
        aCoder.encodeObject(interpolationPoints, forKey: "points")
        aCoder.encodeObject(cachedPath, forKey: "cachedPath")
        aCoder.encodeBool(closed, forKey: "closed")
        //can't save raw cgpoint array
        aCoder.encodeObject(convertToNSArray(intersectionsWithDrivingFold), forKey: "drivingIntersections")
        aCoder.encodeObject(convertToNSArray(intersections), forKey: "intersections")
        aCoder.encodeObject(topTruncations, forKey: "topTruncations")
        aCoder.encodeObject(bottomTruncations, forKey: "bottomTruncations")

    }
    
    
    override func getEdges() -> [Edge] {
        
        //if there are cached edges, return them
        if let cache = featureEdges {
            return cache
        }
        
        if let p = path{
            let edge = Edge(start: round(p.firstPoint()), end: round(p.lastPoint()), path: p, kind: .Cut, isMaster: false, feature: self)
            return [edge]
        }
            // else create a straight edge
        else{
            //TODO: this looks suspiscious
            let edge = Edge.straightEdgeBetween(startPoint!, end: CGPointZero, kind: .Cut, feature: self)
            return [edge]
        }
    }
    
    //TODO: verify that this is not introducing floating point error
    //TODO: convenience function to return edges, move to Bezier.swift
    //splits a bezierpath composed of cubic curves at intersection points
    class func pathSplitByPoints(path:UIBezierPath,breakers:[CGPoint]) ->[UIBezierPath]{

        var closestElements = [CGPathElement](count: breakers.count, repeatedValue: CGPathElement())
        var closestElementsDists = [CGFloat](count: breakers.count, repeatedValue:CGFloat.max)
        
        // start with an empty path
        var returnee:[UIBezierPath] = []
        returnee.append(UIBezierPath())
        
//        
        // first, find the closest element to each intersection point
        for var i = 0; i < Int(path.elementCount()); i++ {
            let el = path.elementAtIndex(i)
            // this is the end point of the previous element, which is our new start point
            let prevPoint:CGPoint
            // element 0 is always a moveto
            if(i == 1){
                let elPrev = path.elementAtIndex(0)
                prevPoint = elPrev.points[0]
            }
            else{
                let elPrev = path.elementAtIndex(i-1)
                prevPoint = elPrev.points[2]
            }
            let points = el.points
            
            // ignore elements that are not curves
            if el.type.value == kCGPathElementAddCurveToPoint.value{
                for (i,breaker) in enumerate(breakers){
                    // take 10 subdivisions
                    for j:Float in [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]{
                        
                        //get point at t value on curve
                        let p = CGPointMake(bezierInterpolation(CGFloat(j), prevPoint.x, points[0].x, points[1].x, points[2].x), bezierInterpolation(CGFloat(j), prevPoint.y, points[0].y, points[1].y, points[2].y));
                        
                        // set new closest element if appropriate
                        let dist = ccpDistance(p, breaker)
                        if ( dist < closestElementsDists[i]){
                            closestElementsDists[i] = dist
                            closestElements[i] = el
                        }
                        
                    }
                }
                
            }
        }
//        
        //this second loop is less bad than it looks, because elements are cached by PerformanceBezier
        for var i = 0; i < Int(path.elementCount()); i++ {
            
            let el = path.elementAtIndex(i)
            // this is the end point of the previous element, which is our new start point
            var prevPoint:CGPoint
            // element 0 is always a moveto
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
            case kCGPathElementMoveToPoint.value : returnee.last!.moveToPoint(points[0])
            case kCGPathElementAddLineToPoint.value : println("line")
            case kCGPathElementAddQuadCurveToPoint.value : println("quad")
            case kCGPathElementAddCurveToPoint.value :
                
                var splittingPointsForElement:[(p:CGPoint,t:CGFloat)] = []
                
                for (j,breaker) in enumerate(breakers){
                    // if the element contains a break point
                    if(CGPointEqualToPoint(el.points[2], closestElements[j].points[2])){
                        
                        //add the point & t value to the splitting points
                        let t = tVeryNearPointonCurve(prevPoint, originalCurve: el, p: breaker)
                        splittingPointsForElement.append((p:breaker,t:t))
                    }
                }
                
                //need to sort splitting points by t value, so we can keep subdividing the last point
                splittingPointsForElement.sort({$0.t < $1.t})
                
                //set initial curve to entire cgpathelement
                var cgObj = CGPathElementObj()
                cgObj.type = el.type
                cgObj.points =  convertToNSArray([el.points[0],el.points[1],el.points[2]]) as [AnyObject]
                
                for (i,split) in enumerate(splittingPointsForElement){
                    
                    // split the curve at t
                    let newCurves = splitCubicCurveAtT(prevPoint,originalCurve: cgObj,t: Float(split.t))
                    
                    //append the portion of the element between its startpoint and the t point
                    returnee.append(UIBezierPath())
                    returnee.last!.moveToPoint(prevPoint)
                    returnee.last!.addCurveToPoint(split.p  , controlPoint1: newCurves.0.points[0].CGPointValue(), controlPoint2: newCurves.0.points[1].CGPointValue())
                    
                    //if this is the last intersection, also append last portion of the path, from t point to end
                    if(i == splittingPointsForElement.count - 1){
                        returnee.append(UIBezierPath())
                        returnee.last!.moveToPoint(split.p)
                        returnee.last!.addCurveToPoint(newCurves.1.points[2].CGPointValue(), controlPoint1: newCurves.1.points[0].CGPointValue(), controlPoint2: newCurves.1.points[1].CGPointValue())
                    }
                    // set up curve for next interation.  The new curve goes from split to the end of the previous path element
                    prevPoint = split.p
                    cgObj.points = newCurves.1.points
                    
                }
                
                //if the element does not have any splitting points, add it to the returned path as is
                if(splittingPointsForElement.isEmpty){
                    returnee.last!.addCurveToPoint(points[2], controlPoint1: points[0], controlPoint2: points[1])
                }
            case kCGPathElementCloseSubpath.value :
                break
            default: println("unexpected")
            }
        }



        return returnee
    }
    
    func filterPathsOutsideBounds(paths:[UIBezierPath]) -> [UIBezierPath]{
        var returnee = paths
        //reject paths whose center point is outside the truncated shape
        for p in returnee{
            //get top and bottom folds
            
            let maxFold = horizontalFolds.last
            let minFold = horizontalFolds.first
            
            //discard paths whose centroid is above or below top & bottom folds
            if(p.center().y > maxFold!.start.y || p.center().y < minFold!.start.y ){
                returnee.remove(p)
            }
            
        }
        return returnee
    }
    
    
    // searches for the nearest interpolation point to p on curve
    class func tVeryNearPointonCurve(previousPoint:CGPoint,originalCurve:CGPathElement,p:CGPoint) -> CGFloat
    {
        
        //    Calculate the parameterized value along the curve (between 0.0 and 1.0) of the touch. To do this you can calculate a set of points at regular intervals (0.1, 0.2, 0.3 etc.) and then find the two closest points to your touch points and repeat the parameterization between these points if you want more accuracy (0.21, 0.22, 0.23, etc.). This will result in a number between 0.0 and 1.0 along the curve segment representing where you touched.
        let maxRecursionDepth = 3
        return FreeForm.approachT(0.000,endT: 1.000,start: previousPoint,ctrl1: originalCurve.points[0],ctrl2: originalCurve.points[1],end: originalCurve.points[2],goal:p,recursionDepth: maxRecursionDepth)
    }
    
    //recursive search for nearest t value
    class func approachT (startT:CGFloat,endT:CGFloat,start:CGPoint,ctrl1:CGPoint,ctrl2:CGPoint,end:CGPoint,goal:CGPoint, recursionDepth:Int) -> CGFloat{
        
        //calculate 5 t values
        let divisions = CGFloat(4.0000)
        let step = abs(endT - startT)/divisions
        
        if(recursionDepth > 0){
            
            var closestPointOnCurve = (t:CGFloat(0),p:CGPointZero,dist:CGFloat.max)
            var secondClosest = (t:CGFloat(1.0),p:CGPointZero,dist:CGFloat.max)
            
            //get the two closest points, between which we will make our next set of divisions
            for(var t = startT; t <= endT; t += step){
                let p = bezierInterpolation(t, start, ctrl1, ctrl2, end)
                let distToGoal = ccpDistance(p,goal)
                
                if(distToGoal < secondClosest.dist){
                    secondClosest = closestPointOnCurve
                    closestPointOnCurve = (t:t,p:p,dist:distToGoal)
                }
            }
            
            //recurse with new t values, decremented recursion value, and everything else the same
            
            return FreeForm.approachT(min(closestPointOnCurve.t,secondClosest.t),endT: max(closestPointOnCurve.t,secondClosest.t),start: start,ctrl1: ctrl1,ctrl2: ctrl2,end: end, goal:goal,recursionDepth: recursionDepth - 1)
            
            
        }
        else{
            // base case: return the average of the t values of the two closest points
            
            return (startT + endT)/2
        }
    }
    
    
    // splits a cubic bezier curve at a fraction of its length.  Pseudocode from stackoverflow
    //    This bit is difficult to explain in text, but there's a good visualization on this page about half-way down under the heading Subdividing a Bezier curve. Use the slider under the diagram to see how it works, here's my textual explanation: You need to subdivide the straight lines between the control points of your curve segment proportional to the parameterized value you calculated in step 1. So if you calculated 0.4, you have four points (A, B, C, D) plus the split-point on the curve closest to your touch at 0.4 along the curve, we'll call this split-point point S:
    class func splitCubicCurveAtT(previousPoint:CGPoint,originalCurve:CGPathElementObj,t:Float) -> (CGPathElementObj,CGPathElementObj){
        
        //    Calculate a temporary point T which is 0.4 along the line B→C
        
        let a = previousPoint
        let b = originalCurve.points[0].CGPointValue()
        let c = originalCurve.points[1].CGPointValue()
        let d = originalCurve.points[2].CGPointValue()
        //t a b c d
        let s = bezierInterpolation(CGFloat(t), a, b, c, d)
        
        //Calculate a temporary point T which is 0.4 along the line B→C
        let temp = ccpLerp(b,c,t)
        //    Let point A1 be equal to point A
        let a1 = a
        //    Calculate point B1 which is 0.4 along the line A→B
        let b1 = ccpLerp(a1,b,t)
        //    Calculate point C1 which is 0.4 along the line B1→T
        let c1 = ccpLerp(b1,temp,t)
        //    Let point D1 be equal to the split point S
        let d1 = s
        //    Let point D2 be equal to point D
        let d2 = d
        //    Calculate point C2 which is 0.4 along the line C→D
        let c2 = ccpLerp(c,d,t)
        //    Calculate point B2 which is 0.4 along the line T→C2
        let b2 = ccpLerp(temp,c2,t)
        //    Let point A2 be equal to the split point S
        let a2 = s
        
        let leg1 = CGPathElementObj(type: kCGPathElementAddCurveToPoint, points: convertToNSArray([b1,c1,d1]) as [AnyObject])
        let leg2 = CGPathElementObj(type: kCGPathElementAddCurveToPoint, points: convertToNSArray([b2,c2,d2]) as [AnyObject])
        
        return (leg1,leg2)
    }
    
    /// this function should be called exactly once, when the feature is created at the end of a pan gesture
    func freeFormEdgesSplitByIntersections() ->[Edge]{
        
        /// splits the path into multiple edges based on intersection points
        var paths = FreeForm.pathSplitByPoints(path!,breakers: intersections.map({round($0)}))
        paths = filterPathsOutsideBounds(paths)
        
        var edges:[Edge] = []
        
        //create edges from split paths
        for p in paths{
            
            // check greater less than greater than top truncations heights
            // findCentroid(p)
//            if(true){
            let e = Edge(start: round(p.firstPoint()), end: round(p.lastPoint()), path: p, kind: .Cut, isMaster: false, feature: self)
                edges.append(e)
//            }
        }
        
//        println("\nEDGES!!!!!!\n \(edges)")
        return edges
    }
    
    
    // the bezier path through the touch points
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
            cachedPath = pathThroughCatmullPoints(interpolationPoints as! [NSValue], closed)
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
            if var intersects = PathIntersections.intersectionsBetween(fold.path,path2: self.path!){
                intersects = intersects.map({(a:CGPoint) -> CGPoint in
                    // intersection points are at the same height as the fold they're intersecting with
                    return CGPointMake(a.x, fold.start.y)
                })
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
        var options:[FeatureOption] = super.tapOptions() ?? []
        options.append(.DeleteFeature)
        if(self.isLeaf() && horizontalFolds.count >= 3){
                options.append(.MoveFolds);
          }
        
        return options
        
    }
    
    // attempt to truncate testpathtwo with testpathone, which should be a line.  maxIntercepts indicates how many intersection points are allowed
    func tryIntersectionTruncation(testPathOne:UIBezierPath,testPathTwo:UIBezierPath, maxIntercepts:Int = 100) -> Bool{
        
        var points = PathIntersections.intersectionsBetween(testPathOne, path2: testPathTwo)
        
        if let ps = points{
            //for all intersections, if there are an even number
            if(ps.count>=2 && ps.count <= maxIntercepts){
                var edgesToAdd:[Edge] = []
                for (var i = 0; i<ps.count-1; i++){
                        //try making a straight edge between the points
                        let edge = Edge.straightEdgeBetween(round(ps[i]), end: round(ps[i+1]), kind: .Fold, feature:self)
                        // if the line's center is inside the path, add the edge and go to the next pair
                        if(testPathTwo.containsPoint(edge.path.center()) && ccpDistance(ps[i], ps[i + 1]) > kMinLineLength){
                            edgesToAdd.append(edge)
                        }
                }
                
                //if there are edges to add, add them, and return that the trucation succeeded
                if(edgesToAdd.count>0){
                    intersections.extend(ps)
                    
                    for fold in edgesToAdd{
                        self.horizontalFolds.insertIntoOrdered(fold, ordering: {$0.start.y < $1.start.y})
                    }
                    self.featureEdges!.extend(edgesToAdd)
                    return true
                }
            }
        }
        
//        println("Failed with points: \(points)")
        return false
    }
    /// creates intersections with top, bottom and middle folds; also creates horizontal folds
    func truncateWithFolds()
    {
        
        if let driver = drivingFold, p = path
        {
            let box = self.boundingBox()
            // scan line is the line we use for intersection testing
            var scanLine:Edge = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut, feature: self)
            
            var yTop:CGFloat = 0;
            var yBottom:CGFloat = 0;
            
            //hop defines the amount to move each time through the loop, intercepts is the maximum number of accepatable intercepts, endSearchAtY is the
            func truncate(hop:CGFloat,intercepts:Int,endSearchAtY:CGFloat) -> CGFloat?{
                
                //move scanline to find bottom intersection point until we are close to limit
                while(abs(scanLine.path.firstPoint().y - endSearchAtY) > 20 ){
                    
                    var moveDown = CGAffineTransformMakeTranslation(0, hop);
                    scanLine.path.applyTransform(moveDown)
                    
                    let truncated = tryIntersectionTruncation(scanLine.path,testPathTwo: self.path!, maxIntercepts: intercepts)
                    if(truncated){
                        return scanLine.path.firstPoint().y
                    }
                }
                return nil
            }
            
            /// TOP FOLD
            let scanLineStartingAtTop = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut, feature: self)
            
            scanLine = scanLineStartingAtTop
            //try truncting at bottom with 2 intersections first, then any number of intersections if that fails in the first 50 points
            if let top = truncate(5,2,box!.origin.y+50){
                yTop = top
            }
            else{
                scanLine = scanLineStartingAtTop
                if let top = truncate(5,100,driver.start.y){
                    yTop = top
                }
                
            }
            
            // BOTTOM FOLD
            let scanLineStartingAtBottom =  Edge.straightEdgeBetween(CGPointMake(box!.origin.x, box!.origin.y + box!.height), end: CGPointMake(box!.origin.x + box!.width, box!.origin.y + box!.height), kind: .Cut, feature: self)
            scanLine = scanLineStartingAtBottom
            //try truncting at bottom with 2 intersections first, then any number of intersections if that fails in the first 50 points
            if let bottom = truncate(-5,2,box!.origin.y + box!.height - 50){
                yBottom = bottom
            }
            else{
                scanLine = scanLineStartingAtBottom
                if let bottom = truncate(-5,100,driver.start.y){
                    yBottom = bottom
                }
            }
            
            //MIDDLE FOLD
            //move scan line to position that will make the shape fold to 90º
            let masterdist = yTop - driver.start.y
            let moveToCenter = CGAffineTransformMakeTranslation(0, masterdist)
            // scanline is at the bottom fold position, so we just move it up by masterdist
            scanLine.path.applyTransform(moveToCenter)
            
            let middleFolds = tryIntersectionTruncation(scanLine.path,testPathTwo: self.path!)
            if(!middleFolds){
//                println("FAILED INTERSECTION POINTS: \(intersections)");
                //                println("\(intersectionsWithDrivingFold)");
                self.state = .Invalid
                println("FAILED TO INTERSECT WITH MIDDLE")
            }
        }
    }
    //split folds around intersections with driving fold
    override func splitFoldByOcclusion(edge: Edge) -> [Edge]
    {
        
        let start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if intersectionsWithDrivingFold.count == 0
        {
            return [edge]
        }
        
        
        let firstPiece = Edge.straightEdgeBetween(start, end: intersectionsWithDrivingFold.first!, kind: .Fold, feature:self.parent!)
        returnee.append(firstPiece)
        
        var brushTip = intersectionsWithDrivingFold[0]
        
        //skip every other point, so we don't make edges inside shape
        for (var i = 1; i < intersectionsWithDrivingFold.count-1; i+=2)
        {
            brushTip = intersectionsWithDrivingFold[i]
            let brushTipTranslated = CGPointMake(intersectionsWithDrivingFold[i+1].x,brushTip.y)
            let piece = Edge.straightEdgeBetween(brushTip, end: brushTipTranslated, kind: .Fold, feature: self.parent!)
            returnee.append(piece)
        }
        
        let finalPiece = Edge.straightEdgeBetween(intersectionsWithDrivingFold.last!, end: end, kind: .Fold, feature: self.parent!)
        returnee.append(finalPiece)
        return returnee
    }
    
    // sets top & bottom truncations based on fold height
    // TODO: like claimedges, this should probably be done differently
    func setTopBottomTruncations(){
        let heights = uniqueFoldHeights()
        
        for fold in horizontalFolds{
            if fold.start.y == heights.first!
            {
                topTruncations.append(fold)
            }
            else if fold.start.y == heights.last!
            {
                bottomTruncations.append(fold)
            }
            
        }
    }
    
    
    func addTabs(translatedHeights:[CGFloat],savedHeights:[CGFloat]){
        
        let originalHeights = uniqueFoldHeights()
        var rejectedFolds:[Edge] = []

        func addTab(#up:Bool){
        
            var topEdges = self.horizontalFolds.filter({(a:Edge) -> Bool in return (a.kind == .Fold && a.start.y == (up ? originalHeights.first : originalHeights.last))})
            rejectedFolds.extend(topEdges)
            topEdges = topEdges.uniqueBy({$0.start})
            
            func cutsAndFoldsForTab(referenceEdge:Edge,#up:Bool) -> [Edge]{
                //draw to nearest saved height
                let translatedY = translatedHeights.minBy({(transY:CGFloat) in return  abs(referenceEdge.start.y - transY)})

                let fold = Edge.straightEdgeBetween(CGPointMake(referenceEdge.start.x, translatedY!), end: CGPointMake(referenceEdge.end.x, translatedY!), kind: .Fold, feature:self)
                return [fold, Edge.straightEdgeBetween(fold.start, end: referenceEdge.start, kind: .Cut,feature:self),Edge.straightEdgeBetween(fold.end, end: referenceEdge.end, kind: .Cut,feature:self)]
            }
        
            for edge in topEdges{
                let tabEdges = cutsAndFoldsForTab(edge,up:up)
                self.featureEdges?.extend(tabEdges)
                self.horizontalFolds.remove(edge)
                self.horizontalFolds.append(tabEdges[0])
            }

        }
        
        // if there is a tab up
        if translatedHeights.first < savedHeights.first{
            addTab(up:true)
        }
        // if there is a tab down
        if translatedHeights.last > savedHeights.last{
            addTab(up:false)
        }

        
        self.featureEdges = self.featureEdges?.difference(rejectedFolds)
    }
    
    
    func shiftEdgeEndpoints(){
        
//        println("\n\nstartPoint: \(startPoint) | endPoint: \(endPoint)")
        
        //first, snap Edge to intersections
        var snappablePoints = intersections.map({round($0)})
//        snappablePoints.extend(intersectionsWithDrivingFold)
        snappablePoints.append(startPoint!)
        snappablePoints.append(endPoint!)
        // also need to take horizontal fold endpoints into account
        for fold in horizontalFolds{
            snappablePoints.append(fold.start)
            snappablePoints.append(fold.end)
        }

        
        if let edges = featureEdges{
            for edge in edges{
                // TODO: check endpoint
                let newStart = snappablePoints.minBy({ccpDistance($0,edge.start)})!
                
                if (ccpDistance(edge.start,newStart) < 2){
                    edge.snapStart(to: newStart)
                }
                else{
                    snappablePoints.append(edge.start)
                }
                
                let newEnd = snappablePoints.minBy({ccpDistance($0,edge.end)})!
                if (ccpDistance(edge.end,newEnd) < 2){
                    edge.snapEnd(to: newEnd)
                    
                }
                else{
                    snappablePoints.append(edge.end)
                }
            }
        }
    }
    
    override func containsPoint(point:CGPoint) -> Bool{
        if (self.boundingBox()?.contains(point) ?? false){
            return path?.containsPoint(point) ?? false
        }
        return false
    }
    
}
