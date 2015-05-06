//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

/// a set of folds/cuts that know something about whether it is a valid 3d feature
class FoldFeature: NSObject, Printable, NSCoding{
    //    enum Kind {
    //        case Box,
    //        Mirrored,
    //        FreeForm,
    //        VFold,
    //        Track,
    //        Slider,
    //        MasterCard //some things are priceless; for everything else there's border edges and the driving fold
    //    }
    
    enum ValidityState:Int {
        case Invalid = 0, // we don't know how to make this feature valid
        Valid = 1 // can be simulated in 3d/folded in real life
    }
    
//    enum DefinitionState {
//        case Incomplete, //still drawing/dragging
//        Complete //finished drawing
//    }
    
    //not used yet
    var featurePlanes:[Plane] = []
    //not used yet
    var drawingPlanes:[Plane] = []
    //not used yet
    var horizontalFolds:[Edge] = []
    
    //used by getEdges
    var cachedEdges:[Edge]?
    // features that span folds in this feature
    var children:[FoldFeature]?
    var drivingFold:Edge?
    var parent:FoldFeature?
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    var activeOption:FeatureOption?  // the operation being performed on this feature (eg. .MoveFold)
    var deltaY:CGFloat? = nil  //distance moved from original y position during this drag, nil if not being dragged

    required init(coder aDecoder: NSCoder) {
        
        self.startPoint = aDecoder.decodeCGPointForKey("startPoint")
        self.endPoint = aDecoder.decodeCGPointForKey("endPoint")
        self.children = aDecoder.decodeObjectForKey("children") as? [FoldFeature]
        self.parent = aDecoder.decodeObjectForKey("parent") as? FoldFeature
        self.drivingFold = aDecoder.decodeObjectForKey("children") as? Edge
        self.horizontalFolds = aDecoder.decodeObjectForKey("children") as! [Edge]
        self.cachedEdges = aDecoder.decodeObjectForKey("children") as? [Edge]
        self.state = ValidityState(rawValue: aDecoder.decodeObjectForKey("state") as! Int)!
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
        aCoder.encodeObject(cachedEdges,forKey:"cachedEdges")
        aCoder.encodeObject(state.rawValue,forKey:"state")
    }
    
    /// is it valid?
    var state:ValidityState = .Valid
    
    
    /// printable description is the object class & startPoint
    override var description: String {
        return "\(reflect(self).summary) \(startPoint!)"
    }
    
    init(start:CGPoint){
        startPoint = start
    }
    
    // return the edges of a feature
    // maybe the right way to do this is to have getEdges return throwaway preview edges,
    // and then freeze edges into a feature after the feature is finalized when the drag ends
    // invalidating edges during drags is one way, but it might not be the cleanest.
    func getEdges()->[Edge]{
        
        if let returnee = cachedEdges {
            return returnee
        }
        return []
    }
    
    //we might need separate functions for invalidating cuts & folds?
    //might also need a set of user-defined edges that we don't fuck with
    func invalidateEdges(){
        cachedEdges = nil
        horizontalFolds = []
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?{
        
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
        
        horizontalFolds.sort({ (a: Edge, b:Edge) -> Bool in return a.start.y > b.start.y })
        
    }
    
    
    /// returns the edge in a feature at a point
    /// and the nearest point on that edge to the hit
    func featureEdgeAtPoint(touchPoint:CGPoint) -> Edge?{
        
        if let edges = cachedEdges{
            for edge in edges{
                // #TODO: hardcoding this is baaaad
                if let hitPoint = Edge.hitTest(edge.path,point: touchPoint,radius:kHitTestRadius*3.5){
                    return edge
                }
            }
        }

        return nil;
    }
    
    func claimEdges(){
        
        if let edges = cachedEdges{
            for edge in edges{
                edge.feature = self
            }
        }
    }
    
    /// splits an edge around the current feature
    func splitFoldByOcclusion(edge:Edge) -> [Edge]{
        //by default, return edge whole
        return [edge]
    }
    

//    
//    /// splits an edge, making edges around its children
//    func edgeSplitByChildren(edge:Edge) -> [Edge]{
//        
//        let start = edge.start
//        let end = edge.end
//        var returnee = [Edge]()
//        
//        if var childs = children{
//            
//            //sort children by x position
//            childs.sort({(a, b) -> Bool in return a.startPoint!.x < b.startPoint!.x})
//            childs = childs.filter({(a) -> Bool in return a.drivingFold?.start.y == edge.start.y })
//            
//            //pieces of the edge, which go inbetween child features
//            var masterPieces:[Edge] = []
//            
//            //create fold pieces between the children
//            var brushTip = start
//            
//            for child in childs{
//                
//                let brushTipTranslated = CGPointMake(child.endPoint!.x,brushTip.y)
//                
//                let piece = Edge.straightEdgeBetween(brushTip, end: CGPointMake(child.startPoint!.x, brushTip.y), kind: .Fold)
//                returnee.append(piece)
//                horizontalFolds.append(piece)
//                
//                brushTip = brushTipTranslated
//            }
//            
//            let finalPiece = Edge.straightEdgeBetween(brushTip, end: end, kind: .Fold)
//            returnee.append(finalPiece)
//        }
//        
//        //if there are no split edges, give the edge back whole
//        if (returnee.count == 0){
//            return [edge]
//        }
//        return returnee
//        
//    }
//    
    //delete a feature from a sketch
    func removeFromSketch(sketch:Sketch){
        
        //remove parent relationship from children
        if let childs = self.children{
//            println(childs);

            for child in childs{
                child.removeFromSketch(sketch)
//                child.invalidateEdges()

            }
        }
        
        //remove child relationship from parents
        self.parent?.children?.remove(self)
//        self.parent?.invalidateEdges()
        sketch.features?.remove(self)
        

    }
    
    /// features are leaves if they don't have children
    func isLeaf() -> Bool{
        return children == nil || children!.count == 0
    }
    
    /// modifications that can be made to the current feature
    func tapOptions() -> [FeatureOption]?{
        
        return nil
        
    }
    
    /// the unique fold heights in the feature (ignores duplicates)
    func uniqueFoldHeights() -> [CGFloat]{
        var uniquefolds = horizontalFolds.uniqueBy({$0.start.y})
        uniquefolds.sort({$0.start.y < $1.start.y})
        return uniquefolds.map({$0.start.y})
    }
    
    
    /// the unique fold heights in the feature (ignores duplicates), modified by delta y
    func foldHeightsWithTransform(originalHeights:[CGFloat], draggedEdge:Edge, masterFold:Edge) -> [CGFloat]{
        
        let draggedHeight = draggedEdge.start.y
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
    
    func featureSpansFold(fold:Edge)->Bool{
        
        if(self.startPoint == nil ||  self.endPoint == nil){
            return false
        }
        
        //feature must be inside fold x bounds
        if(!(self.startPoint!.x > fold.start.x && self.endPoint!.x > fold.start.x  &&  self.startPoint!.x < fold.end.x && self.endPoint!.x < fold.end.x   )){
            return false
        }
        
        //sort points by y
        func pointsByY(a:CGPoint,b:CGPoint)->(min:CGPoint,max:CGPoint){
            return (a.y < b.y) ? (a,b) : (b,a)
        }
        
        let sorted = pointsByY(self.startPoint!, self.endPoint!)
        
        // test whether the feature starts above minimum height & below maximum
        return (sorted.min.y < fold.start.y  && sorted.max.y > fold.start.y)
        
    }
    
    func replaceFold(fold:Edge, folds:[Edge]){
        horizontalFolds.remove(fold)
        cachedEdges?.remove(fold)
        horizontalFolds.extend(folds)
        cachedEdges?.extend(folds)
    }
    
}