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
    //
    //    enum Kind {
    //        case Box,
    //        Mirrored,
    //        FreeForm,
    //        VFold,
    //        Track,
    //        Slider,
    //        MasterCard//some things are priceless; for everything else there's border edges and the driving fold
    //    }
    
    enum ValidityState {
        case Invalid, // we don't know how to make this feature valid
        Fixable, // we know how to make this feature valid
        Valid // can be simulated in 3d/folded in real life
    }
    
    //not used yet
    var featurePlanes:[Plane] = []
    //not used yet
    var drawingPlanes:[Plane] = []
    //not used yet
    var horizontalFolds:[Edge] = []
    
    //used by getEdges
    var cachedEdges:[Edge]?
    // features that affect this feature's edges/validity
    var children:[FoldFeature]?
    var drivingFold:Edge?
    var parent:FoldFeature?
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    
    /// is it valid?
    var state:ValidityState = .Fixable
    
    
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
        
        if let edges = cachedEdges{
            for edge in edges{
                
                // #TODO: harcoding this to 35 is baaaad
                if let hitPoint = Edge.hitTest(edge.path,point: touchPoint,radius:kHitTestRadius*3.5){
                    return edge
                }
                
            }
        }
        else{
            
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
    
    /// splits an edge, making edges around its children
    func edgeSplitByChildren(edge:Edge) -> [Edge]{
        
        let start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if var childs = children{
            
            //sort children by x position
            childs.sort({(a, b) -> Bool in return a.startPoint!.x < b.startPoint!.x})
            childs = childs.filter({(a) -> Bool in return a.drivingFold?.start.y == edge.start.y })
            
            //pieces of the edge, which go inbetween child features
            var masterPieces:[Edge] = []
            
            //create fold pieces between the children
            var brushTip = start
            
            for child in childs{
                
                let brushTipTranslated = CGPointMake(child.endPoint!.x,brushTip.y)
                
                let piece = Edge.straightEdgeBetween(brushTip, end: CGPointMake(child.startPoint!.x, brushTip.y), kind: .Fold)
                returnee.append(piece)
                horizontalFolds.append(piece)
                
                brushTip = brushTipTranslated
            }
            
            let finalPiece = Edge.straightEdgeBetween(brushTip, end: end, kind: .Fold)
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
        
        if let childs = self.children{
            for child in childs{
                child.parent = nil
            }
        }
        
        if let fs = sketch.features{
            for feature in fs{
                if((feature.children?.contains(self)) != nil){
                feature.children?.remove(self)
                feature.invalidateEdges()
                }
            }
        }
        
        //remove edges from master Edge
        
        for edge in sketch.edges{
        
            let fEdges = self.getEdges()
                
            for fEdge in fEdges{
                
                if fEdge ≈ edge {
                    sketch.removeEdge(edge)
                    break
                }
            
            }
            
        
        }
        
        self.invalidateEdges()
        sketch.features?.remove(self)
    }
    
    
}