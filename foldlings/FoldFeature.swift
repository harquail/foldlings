//
//  FoldFeature.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved



import Foundation

/// a set of folds/cuts that know something about whether it is a valid 3d feature
class FoldFeature: NSObject, Printable
{
    
    override var hashValue: Int { get {
//        println(featureEdges)
        return featureEdges?.description.hashValue ?? self.description.hashValue
        }
    }

    var featurePlanes:[Plane] = []
    //not used yet
    //var drawingPlanes:[Plane] = []
    
    
    var horizontalFolds:[Edge] = [] //list horizontal folds
    var featureEdges:[Edge]?        //edges in a feature
    var children:[FoldFeature] = []// children of feature
    var drivingFold:Edge?// driving fold of feature
    var parent:FoldFeature?// parent of feature
    
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    var activeOption:FeatureOption?  // the operation being performed on this feature (eg. .MoveFold)
    var deltaY:CGFloat? = nil  //distance moved from original y position during this drag, nil if not being dragged
    
    required init(coder aDecoder: NSCoder) {
        
        self.startPoint = aDecoder.decodeCGPointForKey("startPoint")
        self.endPoint = aDecoder.decodeCGPointForKey("endPoint")
        self.children = (aDecoder.decodeObjectForKey("children") as? [FoldFeature])!
        self.parent = aDecoder.decodeObjectForKey("parent") as? FoldFeature
        self.drivingFold = aDecoder.decodeObjectForKey("drivingFold") as? Edge
        self.horizontalFolds = aDecoder.decodeObjectForKey("horizontalFolds") as! [Edge]
        self.featureEdges = aDecoder.decodeObjectForKey("cachedEdges") as? [Edge]
//        self.state = ValidityState(rawValue: aDecoder.decodeObjectForKey("state") as! Int)!
    }
    
    
    func encodeWithCoder(aCoder: NSCoder) {
        //startpoint
        //endpoint
        //        [coder encodeCGPoint:myPoint forKey:@"myPoint"];
        //children
        //drivingFold
        //parent
        //horizontalFolds
        //cachedEdges
        //validity
        //println("encoded \(featureEdges)")
        
        if let point = startPoint{
            aCoder.encodeCGPoint(point, forKey: "startPoint")
        }
        if let point = endPoint{
            aCoder.encodeCGPoint(point, forKey: "endPoint")
        }
        aCoder.encodeObject(parent,forKey:"parent")
        aCoder.encodeObject(children, forKey:"children")
        aCoder.encodeObject(drivingFold, forKey:"drivingFold")
        aCoder.encodeObject(horizontalFolds,forKey:"horizontalFolds")
        aCoder.encodeObject(featureEdges,forKey:"cachedEdges")
//        aCoder.encodeObject(state.rawValue,forKey:"state")
    }
    
    /// is it valid?
//    var state:ValidityState = .Valid
    var dirty: Bool = true
    
    /// printable description is the object class & startPoint
    override var description: String
        {
            return "\(reflect(self).summary) \(startPoint!)"
    }
    
    init(start:CGPoint)
    {
        startPoint = start
    }
    
    // return the edges of a feature
    // maybe the right way to do this is to have getEdges return throwaway preview edges,
    // and then freeze edges into a feature after the feature is finalized when the drag ends
    // invalidating edges during drags is one way, but it might not be the cleanest.
    func getEdges()->[Edge]
    {
        if let returnee = featureEdges
        {
            return returnee
        }
        return []
    }
    
    //we might need separate functions for invalidating cuts & folds?
    //might also need a set of user-defined edges that we don't fuck with
    func invalidateEdges(){
        featureEdges = nil
        horizontalFolds = []
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?
    {
        return nil
    }
    
    /// makes the start point the top left point
    func fixStartEndPoint(){
        
        if(startPoint != nil && endPoint != nil){
            let topLeft = CGPointMake(min(startPoint!.x,endPoint!.x), min(startPoint!.y,endPoint!.y))
            let bottomRight = CGPointMake(max(startPoint!.x,endPoint!.x), max(startPoint!.y,endPoint!.y))
            
            startPoint = topLeft
            endPoint = bottomRight
        }
        
    }
    
    
    /// returns the edge in a feature at a point
    /// and the nearest point on that edge to the hit
    func featureEdgeAtPoint(touchPoint:CGPoint) -> Edge?
    {
        // go through edges in feature
        if let edges = featureEdges
        {
            for edge in edges
            {
                // #TODO: hardcoding this is baaaad
                if let hitPoint = Edge.hitTest(edge.path,point: touchPoint,radius:kHitTestRadius*3.5)
                {
                    return edge
                }
            }
        }
        return nil
    }
    
    /// splits an edge around the current feature
    func splitFoldByOcclusion(edge:Edge) -> [Edge]
    {
        //by default, return edge whole
        return [edge]
    }
    
    
    /// features are leaves if they don't have children
    func isLeaf() -> Bool
    {
        return children.count == 0
    }
    
    /// modifications that can be made to the current feature
    func tapOptions() -> [FeatureOption]?
    {
        return [FeatureOption.PrintPlanes, FeatureOption.PrintEdges, FeatureOption.ColorPlaneEdges, FeatureOption.PrintSinglePlane]
    }
    
    /// the unique fold heights in the feature (ignores duplicates)
    func uniqueFoldHeights() -> [CGFloat]{
        var uniquefolds = horizontalFolds.uniqueBy({$0.start.y})
        uniquefolds.sort({$0.start.y < $1.start.y})
        return uniquefolds.map({$0.start.y})
    }
    
    
    /// the unique fold heights in the feature (ignores duplicates), modified by delta y
    func foldHeightsWithTransform(originalHeights:[CGFloat], draggedEdge:Edge, masterFold:Edge) -> [CGFloat]{
        
        //        println("original heights: \(originalHeights)")
        let draggedHeight = draggedEdge.start.y
        //        println("dragged height: \(draggedHeight)")
        var newHeights:[CGFloat] = []
        
        let draggedIndex = originalHeights.indexOf(draggedHeight)!
        
        switch (draggedIndex) {
        case 0:
            newHeights = [originalHeights[0]+deltaY!,originalHeights[1],originalHeights[2]-deltaY!]
        case 1:
            //TODO: this is wrong
            newHeights = [originalHeights[0]+deltaY!,originalHeights[1]+deltaY!,originalHeights[2]+deltaY!]
        case 2:
            newHeights = [originalHeights[0]-deltaY!,originalHeights[1],originalHeights[2]+deltaY!]
        default:
            newHeights = originalHeights
        }
        
        if(newHeights.first > masterFold.start.y || newHeights.last < masterFold.start.y){
            // TODO: original heights is the wrong thing to return here
            return originalHeights
        }
        else{
            return newHeights
        }
    }
    
    func featureSpansFold(fold:Edge)->Bool
    {
        var fMin = min(fold.start.x, fold.end.x)
        var fMax = max(fold.start.x, fold.end.x)
        
        if (fMin < self.startPoint!.x && self.startPoint!.x < fMax) && (fMin < self.endPoint!.x && self.endPoint!.x < fMax){
            
            return ccpSegmentIntersect(fold.start, fold.end, self.startPoint!, self.endPoint!)
        }
        return false
    }
    
    // this caches planes from edges
    func getFeaturePlanes()-> [Plane]{
        return featurePlanes
    }
    
    //    // makes a straight path between two points
    //    func makeStraightPath(start: CGPoint, end: CGPoint)-> UIBezierPath{
    //        let path = UIBezierPath()
    //        path.moveToPoint(start)
    //        path.addLineToPoint(end)
    //
    //        return path
    //    }
    
    // whether a feature contains a point — needs to be overridden by subclasses
    func containsPoint(point:CGPoint) -> Bool{
        return self.boundingBox()?.contains(point) ?? false
    }
    
    // returns edges that are less than the minimum length
    func tooShortEdges() -> [Edge]{
        return featureEdges?.filter({$0.length() < kMinLineLength}) ?? []
    }
    
    // this function should try to fix errors first, then return an error if it can't fix them — returns whether the feature was valid
    func validate() -> (passed:Bool,error:String){
        
        var valid = true
        if(!tooShortEdges().filter({$0.kind == Edge.Kind.Fold}).isEmpty){
//            return (false,"Edges too short")
        }
        println("valid")
        return (true,"")
    }
}