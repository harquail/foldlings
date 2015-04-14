//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

/// a set of folds/cuts that know something about whether it is a valid 3d feature
class FoldFeature: NSObject, Printable{

    enum ValidityState {
        case Invalid, // we don't know how to make this feature valid
        Valid // can be simulated in 3d/folded in real life
    }
    
    enum DefinitionState {
        case Incomplete, //still drawing/dragging
        Complete //finished drawing
    }
    
    //not used yet
    var featurePlanes:[Plane] = []
    //not used yet
    var drawingPlanes:[Plane] = []
    
    
    var horizontalFolds:[Edge] = [] //list horizontal folds
    var featureEdges:[Edge]?        //edges in a feature
    var children:[FoldFeature]?// children of feature
    var drivingFold:Edge?// driving fold of feature
    var parent:FoldFeature?// parent of feature
    
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    
    /// is it valid?
    var state:ValidityState = .Valid
    var dirty: Bool = true

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
        if let returnee = featureEdges {
            return returnee
        }
        return []
    }
    
    //we might need separate functions for invalidating cuts & folds?
    //might also need a set of user-defined edges that we don't fuck with
    // this removes cached edges, sets them all to nil
    func invalidateEdges(){
        featureEdges = nil
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?{
        return nil
    }
    
    /// makes the start point the top left point
    func fixStartEndPoint(){
        
        let topLeft = CGPointMake(min(startPoint!.x,endPoint!.x), min(startPoint!.y,endPoint!.y))
        let bottomRight = CGPointMake(max(startPoint!.x,endPoint!.x), max(startPoint!.y,endPoint!.y))
        
        startPoint = topLeft
        endPoint = bottomRight
        
        horizontalFolds.sort({ (a: Edge, b:Edge) -> Bool in return a.start.y > b.start.y })
        
    }
    
    
    /// #TODO: things you can do to this feature and the function that does them (eg: Delete)
    // delete is special because it affects the sketch (& possibly other features).  Is that true of others?
    // If so, delete should probably be added in at the sketch/sketchview level, and this should just feature-specific options
    // or, we could keep a reference to the sketch in each feature so we can do the deletion from here...
    // Some of these options will necessarily do some UI things also (for example, we might want to preview fold adding).
    // That might mean we should keep a sketchView here (not just a sketch)
    func options() -> [(String,())]{
        return [("Claim Edges",claimEdges())]
    }
    
    
    /// returns the edge in a feature at a point
    /// and the nearest point on that edge to the hit
    func featureEdgeAtPoint(touchPoint:CGPoint) -> Edge?{
        // go through edges in feature 
        if let edges = featureEdges{
            for edge in edges{
                // #TODO: hardcoding this is baaaad
                if let hitPoint = Edge.hitTest(edge.path,point: touchPoint,radius:kHitTestRadius*3.5){
                    return edge
                }
            }
        }
        return nil
    }
    
    // assign edges to a features
    // TODO: should do this when we make edges instead of looping through
    func claimEdges(){
        if let edges = featureEdges{
            for edge in edges{
                edge.feature = self
            }
        }
    }
    
    /// splits an edge, making edges around its children
    func edgeSplitByChildren(edge:Edge) -> [Edge]{
        
        var start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if var childs = children{
            
            //sort children by x position
            childs.sort({(a, b) -> Bool in return a.startPoint!.x < b.startPoint!.x})
            childs = childs.filter({(a) -> Bool in return a.drivingFold?.start.y == edge.start.y })
            
            //create fold pieces between the children
            //needs explanation
            for child in childs{
                var newStart = CGPointMake(child.endPoint!.x,start.y)
                let piece = Edge.straightEdgeBetween(start, end: CGPointMake(child.startPoint!.x, start.y), kind: .Fold)
                returnee.append(piece)
                horizontalFolds.append(piece)
                start = newStart
            }
            
            let finalPiece = Edge.straightEdgeBetween(start, end: end, kind: .Fold)
            returnee.append(finalPiece)
        }
        
        //if there are no split edges, give the edge back whole
        if (returnee.count == 0){
            return [edge]
        }
        return returnee
        
    }
    
    //delete a feature from a sketch
    func removeFromSketch(sketch:Sketch){
        
        //remove parent relationship from children
        if let childs = self.children{
            for child in childs{
                child.removeFromSketch(sketch)
                child.invalidateEdges()
            }
        }
        
        //remove child relationship from parents
        self.parent?.children?.remove(self)
        // TODO: Mark feature as dirty?
        self.parent?.invalidateEdges()
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
    
    class func featureSpansFold(feature:FoldFeature!,fold:Edge)->Bool{
        
        //feature must be inside fold x bounds
        if(!(feature.startPoint!.x > fold.start.x && feature.endPoint!.x > fold.start.x  &&  feature.startPoint!.x < fold.end.x && feature.endPoint!.x < fold.end.x   )){
            return false
        }
        
        func pointsByY(a:CGPoint,b:CGPoint)->(min:CGPoint,max:CGPoint){
            return (a.y < b.y) ? (a,b) : (b,a)
        }
        
        let sorted = pointsByY(feature.startPoint!, feature.endPoint!)
        return (sorted.min.y < fold.start.y  && sorted.max.y > fold.start.y)
        
    }
    // this caches planes from edges
    func getFeaturePlanes(){
    
    }
}