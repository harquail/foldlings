//
//  Polygon.swift
//  foldlings
//
//  Created by nook on 6/7/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved.
//

import Foundation

class Polygon:FoldFeature{
    

    // the (draggable) points that define the polygon
    var points:[CGPoint] = []
    //the path through the points
    var path: UIBezierPath?
    //the intersection points calculated by featureSpansFold & used for occlusion
    var intersectionsWithDrivingFold:[CGPoint] = []
    
    //if the user
    var draggedPoint:CGPoint? = nil
    
    //this is bullshit, but apparently we have to redeclare the initializer here
    override init(start:CGPoint)
    {
        super.init(start: start)
    }
    
    required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.points = convertToCGPoints(aDecoder.decodeObjectForKey("polyPoints") as! NSArray)
        self.path = Polygon.pathThroughPolygonPoints(points)
        self.intersectionsWithDrivingFold = convertToCGPoints(aDecoder.decodeObjectForKey("polyInts") as! NSArray)
    }
    
    
    override func encodeWithCoder(aCoder: NSCoder) {
        super.encodeWithCoder(aCoder)
        aCoder.encodeObject(convertToNSArray(self.points), forKey: "polyPoints")
        aCoder.encodeObject(convertToNSArray(self.intersectionsWithDrivingFold), forKey: "polyInts")
    }
    
    //the path through polygon points
    class func pathThroughPolygonPoints(points:[CGPoint]) -> UIBezierPath? {
        var ps = points
        
        //return nil if we can't draw a path
        if(ps.isEmpty){
            return nil
        }
        
        var polyPath = UIBezierPath()
        // move to the first point & pop it off the array
        polyPath.moveToPoint(ps.shift()!)
        // draw lines between the remaining points
        points.map({polyPath.addLineToPoint($0)})
        
        polyPath.closePath()
        
        return polyPath
    }
    
    // set intersections here
    override func featureSpansFold(fold: Edge) -> Bool {
        let ints = intersectionWithStraightEdge(fold)
        if((ints.count > 0) && (ints.count % 2 == 0)){
            
            // split cuts
            for (p,e) in ints{
                splitCut(e, at: p)
            }
            
            return true
        }
        return false
        
    }
    
    // use path to get bounds
    override func boundingBox() -> CGRect? {
        return self.path?.bounds ?? nil
    }
    
    func truncateWithFolds(){
        if let driver = drivingFold
        {
            let box = self.boundingBox()
            // scan line is the line we use for intersection testing
            var scanLine:Edge = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut, feature: self)
            //
            var yTop:CGFloat = 0;
            var yBottom:CGFloat = 0;
            //
            //hop defines the amount to move each time through the loop, intercepts is the maximum number of accepatable intercepts, endSearchAtY is the
            func truncate(hop:CGFloat,intercepts:Int,endSearchAtY:CGFloat) -> CGFloat?{
                //
                //move scanline to find bottom intersection point until we are close to limit
                while(abs(scanLine.path.firstPoint().y - endSearchAtY) > 20 ){
                    
                    
                    var ints = intersectionWithStraightEdge(scanLine)
                    
                    var moveDown = CGAffineTransformMakeTranslation(0, hop);
                    //move scanline down one hop for the next time through the loop
                    scanLine = Edge.straightEdgeBetween(CGPointApplyAffineTransform(scanLine.start, moveDown), end: CGPointApplyAffineTransform(scanLine.end, moveDown), kind: scanLine.kind, feature: scanLine.feature!)
                    
                    ints.sort (
                        {(a:(ps:CGPoint,es:Edge),b:(ps:CGPoint,es:Edge)) -> Bool in
                            return (a.ps.x < b.ps.x)
                        }
                    )
                    
                    if(!ints.isEmpty){

                    // skip this point if the resulting fold is too short
                    //  #TODO: check distances between each int point, not just the total span
                    if(!(ccpDistance(ints.first!.ps, ints.last!.ps) > kMinLineLength)){
                        continue
                    }
                        for (i,int:(ps:CGPoint,es:Edge)) in enumerate(ints){
                            // split cuts
                            splitCut(int.es, at: int.ps)
                            if(i>0){
                                // make folds between the intersections
                                let fold = Edge.straightEdgeBetween(ints[i-1].ps, end:int.ps, kind:.Fold, feature:self)
                                
                                
                                let center = fold.centerOfStraightEdge()
                                // add fold if its center is inside the polygon
                                if(self.containsPoint(center)){
                                    addFold(fold)
                                }
                            }
                        }
                        return ints[0].ps.y
                    }
                    
                    
                    
                }
                return nil
            }
            
            
            //
            /// TOP FOLD
            let scanLineStartingAtTop = Edge.straightEdgeBetween(box!.origin, end: CGPointMake(box!.origin.x + box!.width, box!.origin.y), kind: .Cut, feature: self)
            //
            scanLine = scanLineStartingAtTop
            //try truncting at bottom with 2 intersections first, then any number of intersections if that fails in the first 50 points
            if let top = truncate(5,2,box!.origin.y+50){
                yTop = top
            }
            else{
                scanLine = scanLineStartingAtTop
                if let top = truncate(5 ,100,driver.start.y){
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
            //
            //            //MIDDLE FOLD
            //move scan line to position that will make the shape fold to 90º
            let masterdist = yTop - driver.start.y
            let moveToCenter = CGAffineTransformMakeTranslation(0, masterdist)
            // scanline is at the bottom fold position, so we just move it up by masterdist
            scanLine.path.applyTransform(moveToCenter)
            
            scanLine.start = CGPointApplyAffineTransform(scanLine.start, moveToCenter)
            scanLine.end = CGPointApplyAffineTransform(scanLine.end, moveToCenter)
            
            let middleFolds = truncate(0,100,driver.start.y-masterdist)
        }
        rejectOutsideTruncation()
    }
    // split an edge into two edges at a point
    private func splitCut(edge:Edge,at:CGPoint){
        let e1 = Edge.straightEdgeBetween(edge.start, end: at, kind: .Cut, feature: self)
        let e2 = Edge.straightEdgeBetween(at, end: edge.end, kind: .Cut, feature: self)
        
        featureEdges?.remove(edge)
        featureEdges?.extend([e1,e2])
    }
    
    // adds a fold to the polygon
    private func addFold(fold:Edge){
        featureEdges?.append(fold)
        horizontalFolds.insertIntoOrdered(fold, ordering: {$0.start.y < $1.start.y})
    }
    
    // remove edges whose senter is outside the top and bottom folds
    private func rejectOutsideTruncation(){
        let top = horizontalFolds.first!.start.y
        let end = horizontalFolds.last!.start.y
        
        for edge in featureEdges!{
            let center = edge.centerOfStraightEdge()

            if(center.y < top){
                featureEdges?.remove(edge)
            }
            else if(center.y > end){
                featureEdges?.remove(edge)
            }
        }
    }
    
    // split a fold by around the polygon drawn over
    override func splitFoldByOcclusion(edge: Edge) -> [Edge] {
        let start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if intersectionsWithDrivingFold.count == 0
        {
            return [edge]
        }
        
        intersectionsWithDrivingFold.sort (
            {(a:CGPoint, b:CGPoint) -> Bool in
                return (a.x < b.x)
            }
        )
        
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
    
    // returns the polygon point at a touch point, if there is one
    func polyPointAt(point:CGPoint) -> CGPoint?{
        
        for p in points{
            if(ccpDistance(p, point) < kHitTestRadius){
                return p
            }
        }
        return nil
    }
    
    // intersections between the polygon and an edge
    private func intersectionWithStraightEdge(edge:Edge) -> [(ps:CGPoint,es:Edge)]{
        var intersections:[(ps:CGPoint,es:Edge)] = []
        
        for e in featureEdges ?? []{
            let p = ccpPointOfSegmentIntersection(edge.start, edge.end, e.start, e.end)
            // everything that is not CGPointZero is a valid intersection
            if p != CGPointZero{
                intersections.append(ps: p,es: e)
                intersectionsWithDrivingFold.append(p)
            }
        }
        return intersections
    }
    
    // adds a point to the polygon
    func addPoint(point:CGPoint){
        var p = point
        
        // snap closing point to the first point of poly
        if(pointClosesPoly(p)){
            p = points[0]
        }
        
        // add point to poly
        points.append(p)
        path = Polygon.pathThroughPolygonPoints(points)
        
        // add edge
        if(points.count>1){
            featureEdges?.append(Edge.straightEdgeBetween(points[points.count - 2], end: points.last!, kind: .Cut, feature: self))
        }
        else{
            featureEdges = []
        }

        endPoint = p
    }
    
    // a point closes a poly if it is with the hit test radius of the first point
    func pointClosesPoly(point:CGPoint) -> Bool{
        if(points.isEmpty){
            return false
        }
        
        return ccpDistance(points[0], point) < kHitTestRadius  && points.count > 2
    }
    
    func movePolyPoint(from:CGPoint, to:CGPoint) {
        // change point in array
        let i = points.indexOf(from)
        points.remove(from)
        points.insert(to, atIndex: i!)
        draggedPoint = to
        
        //squidge edge endpoints around
        for edge in featureEdges ?? []{
            if(CGPointEqualToPoint(edge.start, from)){
                featureEdges?.remove(edge)
                let newEdge = Edge.straightEdgeBetween(to, end: edge.end, kind: edge.kind, feature: edge.feature ?? self)
                newEdge.dirty = true
                featureEdges?.append(newEdge)
            }
            else if (CGPointEqualToPoint(edge.end, from)){
                featureEdges?.remove(edge)
                let newEdge = Edge.straightEdgeBetween(edge.start, end: to, kind: edge.kind, feature: edge.feature ?? self)
                newEdge.dirty = true
                featureEdges?.append(newEdge)

            }
        }
        

    }
    
    
    // things that can be done to polygons
    override func tapOptions() -> [FeatureOption]?{
        var options:[FeatureOption] = super.tapOptions() ?? []
        
        options.append(.DeleteFeature)
        
        if(self.isLeaf() && horizontalFolds.count >= 3){
            options.append(.MoveFolds);
        }
        
        options.append(.MovePoints)
        
        return options
        
    }
    
    // whether a point is inside the polygon
    override func containsPoint(point: CGPoint) -> Bool {
        return path?.containsPoint(point) ?? false
    }
    
    override func validate() -> (passed: Bool, error: String) {
        let validity = super.validate()
        if(!validity.passed){
            return validity
        }
        
        if(!intersectingEdges().isEmpty){
            return (false,"Edges cannot intersect")
        }
        
        return (true,"")
    }
    
    
    // returns edges that cross
    func intersectingEdges()-> [(Edge,Edge)]{
        var intersections:[(Edge,Edge)] = []
        
        outer:for edge in featureEdges!{
            for edg in featureEdges!{
                
                // don't count sharing endpoints as collision
                if(edg.start == edge.start || edg.end == edge.end || edg.start == edge.end || edg.end == edge.start){
                    break
                }
                if(ccpSegmentIntersect(edge.start, edge.end, edg.start, edg.end)){
                    intersections.append((edge,edg))
                }
            }
        }
        println(intersections)
        return intersections
    }
}