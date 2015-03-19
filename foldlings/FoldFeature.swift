//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

/// a set of folds/cuts that know something about whether it is a valid 3d feature
class FoldFeature{
    
    enum Kind {
        case Box,
        Mirrored,
        FreeForm,
        VFold,
        Track,
        Slider,
        MasterCard//some things are priceless; for everything else there's border edges and the driving fold
    }
    
    enum ValidityState {
        case Invalid, // we don't know how to make this feature valid
        Fixable, // we know how to make this feature valid
        Valid // can be simulated in 3d/folded in real life
    }
    
    enum Options{
        case Delete //delete calls removeFeature
    }
    
    class func optiontoFunc(){
    }
    
    //not used yet
    var featurePlanes:[Plane] = []
    //not used yet
    var drawingPlanes:[Plane] = []
    //not used yet
    var horizontalFolds:[Edge] = []
    
    //used by getEdges
    private var cachedEdges:[Edge]?
    
    // features that affect this feature's edges/validity
    var children:[FoldFeature]?
    var drivingFold:Edge?
    // start and end touch points
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    
    // what sort of feature is this?
    var foldKind:Kind = .Box
    // is it valid?
    var state:ValidityState = .Fixable
    
    init(start:CGPoint,kind:Kind){
        startPoint = start
        foldKind = kind
    }
    
    
    
    //this should probably be caching or a singleton or something fancy
    func getEdges()->[Edge]{
        
        if let returnee = cachedEdges {
            return returnee
        }
        
        switch(foldKind){
        case .Box:
            
            // make h0, h1, and h2 first.  Then s0, s1, s2, e0, e1, e2
            //
            //                  h0
            //            S- - - - -
            //         s0 |         | e0
            //            |     h1  |
            //            - - - - - -
            //         s1 |         | e1
            //     _ _ _ _|         |_ _ _ _ _ master
            //            |         |
            //         s2 |     h2  | e2
            //            - - - - - E
            //
            
            var returnee:[Edge] = []
            let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Fold)
            let h2 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, endPoint!.y), end:endPoint!, kind: .Fold)
            horizontalFolds = [h0,h2]
            
            returnee.append(h0)
            returnee.append(h2)
            
            
            //if there's a master fold
            if let master = drivingFold{
                let masterDist = endPoint!.y - master.start.y
                let h1 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, startPoint!.y + masterDist), end:CGPointMake(endPoint!.x, startPoint!.y + masterDist), kind: .Fold)
                returnee.append(h1)
                horizontalFolds.append(h1)
                
                if(h1.start.y < master.start.y){
                    
                    let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, startPoint!.y + masterDist), kind: .Cut)
                    
                    let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)
                    
                    let s1 = Edge.straightEdgeBetween(s0.end, end:s2.end, kind: .Cut)
                    
                    let e2 = Edge.straightEdgeBetween(endPoint!, end: CGPointMake(endPoint!.x, endPoint!.y - masterDist),kind:.Cut)
                    
                    let e1 = Edge.straightEdgeBetween(e2.end, end: CGPointMake(e2.end.x, h1.end.y), kind: .Cut)
                    
                    let e0 = Edge.straightEdgeBetween(e1.end, end: h0.end, kind: .Cut)
                    
                    returnee.append(s0)
                    returnee.append(s2)
                    returnee.append(s1)
                    returnee.append(e0)
                    returnee.append(e1)
                    returnee.append(e2)
                }
                    
                    //                  h0
                    //            S- - - - -
                    //            |         |
                    //         s0 |         | e0
                    //     _ _ _ _|         |_ _ _ _ _ master
                    //            |         |
                    //         s1 |    h1   | e1
                    //            - - - - - -
                    //            |         |
                    //         s2 |    h2   | e2
                    //            - - - - - E
                    //
                    // leftmost and topmost
                    // rightmost and bottommost
                else{
                    
                    let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)//checked
                    
                    let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, h1.start.y), kind: .Cut)
                    
                    let s1 = Edge.straightEdgeBetween(s0.end, end:s2.end, kind: .Cut)//WRONG
                    
                    
                    
                    let e0 = Edge.straightEdgeBetween(h0.end, end: CGPointMake(h0.end.x, master.end.y), kind: .Cut)//checked
                    let e1 = Edge.straightEdgeBetween(e0.end, end: CGPointMake(h1.end.x, s1.end.y), kind: .Cut)
                    let e2 = Edge.straightEdgeBetween(h1.end, end: endPoint!,kind:.Cut)
                    
                    
                    
                    returnee.append(s0)
                    returnee.append(s1)
                    returnee.append(s2)
                    returnee.append(e0)
                    returnee.append(e1)
                    returnee.append(e2)
                }
                
                
            }
                // otherwise, we only have 4 edges
                //
                //               h0
                //            S------
                //            |      |
                //         s0 |      | e0
                //            |      |
                //            -------E
                //               h2
            else{
                
                let s0 = Edge.straightEdgeBetween(endPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Cut)
                let e0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut)
                
                
                returnee.append(s0)
                returnee.append(e0)
                
            }
            
            cachedEdges = returnee
            return returnee
            //         top
            //   S_______________
            //   |              |
            // l0|              |r0
            //   |              |
            //   |_ _ master _ _|
            //   |              |
            // l1|              |r1
            //   |              |
            //   |              |
            //   ---------------E
            //        bottom
            
        case .MasterCard:
            let top = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Cut)
            let bottom = Edge.straightEdgeBetween(endPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut)
            let midPointDist = (endPoint!.y - startPoint!.y)/2
            let l0 = Edge.straightEdgeBetween(startPoint!, end: CGPointMake(startPoint!.x, startPoint!.y + midPointDist), kind: .Cut)
            let l1 = Edge.straightEdgeBetween(l0.end, end: CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut)
            let r1 = Edge.straightEdgeBetween(endPoint!, end: CGPointMake(endPoint!.x,endPoint!.y-midPointDist), kind: .Cut)
            let r0 = Edge.straightEdgeBetween(r1.end, end: CGPointMake(endPoint!.x,startPoint!.y), kind: .Cut)
            
            var returnee = [top,bottom,l0,l1,r0,r1]
            // if there are no children, then we just need to draw a single fold
            if(children == nil){
                // maybe we don't want master here after all, but for now the only horizontal folds are the driving edge
                let master = Edge.straightEdgeBetween(r1.end, end:l0.end, kind: .Fold)
                horizontalFolds = [master,top,bottom]
                returnee.append(master)
                
            }
                // for now, sort children by start point x and then draw master fold edges between them
                // later, we'll have to do fancy intersection stuff
            else{
                
                if var childs = children{
                    
                    //sort children by x position
                    childs.sort({(a, b) -> Bool in return a.startPoint!.x < b.startPoint!.x})
                    
                    //pieces of the master fold, which go inbetween child features
                    var masterPieces:[Edge] = []
                    
                    //create fold pieces between the children
                    var brushTip = l0.end
                    
                    for child in childs{
                        
                        let brushTipTranslated = CGPointMake(child.endPoint!.x,brushTip.y)
                        
                        let piece = Edge.straightEdgeBetween(brushTip, end: CGPointMake(child.startPoint!.x, brushTip.y), kind: .Fold)
                        returnee.append(piece)
                        
                        brushTip = brushTipTranslated
                    }
                    
                    let finalPiece = Edge.straightEdgeBetween(brushTip, end: r1.end, kind: .Fold)
                    returnee.append(finalPiece)
                    
                }
                
            }
            
            
            for edge in returnee{
                edge.isMaster = true
            }
            
            cachedEdges = returnee
            return returnee
            
        default:
            return []
        }
    }
    
    //we might need separate functions for invalidating cuts & folds?
    //might also need a set of user-defined edges that we don't fuck with
    func invalidateEdges(){
        cachedEdges = nil
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?{
        
        //this will be complicated for free-form shapes
        switch(foldKind){
        case .Box:
            if (startPoint == nil || endPoint == nil){
                return nil;
            }
            return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
        case .MasterCard:
            return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
        default:
            return nil
        }
        
    }
    
    /// makes the start point the top left point
    func fixStartEndPoint(){
        
        let topLeft = CGPointMake(min(startPoint!.x,endPoint!.x), min(startPoint!.y,endPoint!.y))
        let bottomRight = CGPointMake(max(startPoint!.x,endPoint!.x), max(startPoint!.y,endPoint!.y))
        
        startPoint = topLeft
        endPoint = bottomRight
        
        horizontalFolds.sort(sortbyYHeight)
    }
    
    func sortbyYHeight(a:Edge, b:Edge)->Bool{
        return a.start.y > b.start.y;
    }
    
    /// returns the edge in a feature at a point
    func featureEdgeAtPoint(touchPoint:CGPoint) -> Edge?{
        
        if let edges = cachedEdges{
            for edge in edges{

                // #TODO: harcoding this to 35 is baaaad
                if let hitPoint = Edge.hitTest(edge.path,point: touchPoint,radius:35){
//                    println("HIT EDGE")
                     return edge
                }
                
            }
        }
        else{
//         println("CACHED EDGES NULL")
        }
        return nil;
        
    }
    
    
}