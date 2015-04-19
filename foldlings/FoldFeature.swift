//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

/// a set of folds/cuts that know something about whether it is a valid 3d feature
class FoldFeature: NSObject, Printable
{
    
    enum ValidityState
    {
        case Invalid, // we don't know how to make this feature valid
        Valid // can be simulated in 3d/folded in real life
    }
    
    enum DefinitionState
    {
        case Incomplete, //still drawing/dragging
        Complete //finished drawing
    }
    
    //not used yet
    var featurePlanes:[Plane] = []
    //not used yet
    var drawingPlanes:[Plane] = []
    
    
    var horizontalFolds:[Edge] = [] //list horizontal folds
    var featureEdges:[Edge]?        //edges in a feature
    var children:[FoldFeature] = []// children of feature
    var drivingFold:Edge?// driving fold of feature
    var parent:FoldFeature?// parent of feature
    
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    
    /// is it valid?
    var state:ValidityState = .Invalid
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
    // this removes cached edges, sets them all to nil
    func invalidateEdges()
    {
        featureEdges = nil
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?
    {
        return nil
    }
    
    /// makes the start point the top left point
    func fixStartEndPoint()
    {
        let topLeft = CGPointMake(min(startPoint!.x,endPoint!.x), min(startPoint!.y,endPoint!.y))
        let bottomRight = CGPointMake(max(startPoint!.x,endPoint!.x), max(startPoint!.y,endPoint!.y))
        
        startPoint = topLeft
        endPoint = bottomRight
        
        horizontalFolds.sort({ (a: Edge, b:Edge) -> Bool in return a.start.y > b.start.y })
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
    
    // assign edges to a features
    // TODO: should do this when we make edges instead of looping through
//    func claimEdges()
//    {
//        if let edges = featureEdges
//        {
//            for edge in edges
//            {
//                edge.feature = self
//            }
//        }
//    }
    
    /// splits an edge around the current feature
    func splitFoldByOcclusion(edge:Edge) -> [Edge]
    {
        //by default, return edge whole
        return [edge]
    }

    //delete a feature from a sketch
    func removeFromSketch(sketch:Sketch)
    {
        
        //        //remove parent relationship from children
        //        if let childs = self.children{
        ////            println(childs);
        
        for child in self.children
        {
            child.removeFromSketch(sketch)
            //                child.invalidateEdges()
        }
        //}
        
        //remove child relationship from parents
        self.parent?.children.remove(self)
        //        self.parent?.invalidateEdges()
        sketch.features?.remove(self)
    }
    
    /// features are leaves if they don't have children
    func isLeaf() -> Bool
    {
        return children.count == 0
    }
    
    /// modifications that can be made to the current feature
    func tapOptions() -> [FeatureOption]?
    {
        return nil
    }
    
    
    
    func featureSpansFold(fold:Edge)->Bool
    {
        //feature must be inside fold x bounds
        if(!(self.startPoint!.x > fold.start.x && self.endPoint!.x > fold.start.x  &&  self.startPoint!.x < fold.end.x && self.endPoint!.x < fold.end.x   ))
        {
            return false
        }
        
        //sort points by y
        func pointsByY(a:CGPoint,b:CGPoint)->(min:CGPoint,max:CGPoint)
        {
            return (a.y < b.y) ? (a,b) : (b,a)
        }
        
        let sorted = pointsByY(self.startPoint!, self.endPoint!)
        
        // test whether the feature starts above minimum height & below maximum
        return (sorted.min.y < fold.start.y  && sorted.max.y > fold.start.y)
    }
    
    // this caches planes from edges
    func getFeaturePlanes(){}
    
    // replaces one fold edge with an array of fold edges
    // that span the same distance

    func replaceFold(fold:Edge, folds:[Edge]){
        horizontalFolds.remove(fold)
        featureEdges?.remove(fold)
        horizontalFolds.extend(folds)
        featureEdges?.extend(folds)
    }
    
    // makes a straight path between two points
    func makeStraightPath(start: CGPoint, end: CGPoint)-> UIBezierPath{
        let path = UIBezierPath()
        path.moveToPoint(start)
        path.addLineToPoint(end)
        
        return path
    }
}