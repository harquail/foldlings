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
        MasterCard//some things are priceless, for everything else there's border edges and the driving fold
    }
    
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
    // features that affect this feature's edges/validity
    var children:[FoldFeature]?
    var drivingFold:Edge?
    // start and end touch points for gradding a
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    var foldKind:Kind = .Box
    
    
    
    init(start:CGPoint,kind:Kind){
        startPoint = start
        foldKind = kind
    }
    
    
    
    //this should probably be caching or a singleton or something fancy
    func getEdges()->[Edge]{
        switch(foldKind){
        case .Box:
            
            //                  h0
            //            S- - - - -
            //            |         | e0
            //         s0 |     h1  |
            //            - - - - - -
            //         s1 |         | e1
            //     _ _ _ _|         |_ _ _ _ _ master
            //            |         |
            //         s2 |     h2  | e2
            //            - - - - - E
            
            var returnee:[Edge] = []
            let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Fold)
            let h2 = Edge.straightEdgeBetween(CGPointMake(startPoint!.x, endPoint!.y), end:endPoint!, kind: .Fold)
            returnee.append(h0)
            returnee.append(h2)
            
            //if there's a master fold
            if let master = drivingFold{
                let masterDist = endPoint!.y - master.start.y
                
                
                let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, startPoint!.y + masterDist), kind: .Cut)
                let h1 = Edge.straightEdgeBetween(s0.end, end:CGPointMake(endPoint!.x, s0.end.y), kind: .Fold)
                
                let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)
                let s1 = Edge.straightEdgeBetween(s0.end, end:s2.end, kind: .Cut)
                
                let e2 = Edge.straightEdgeBetween(endPoint!, end: CGPointMake(endPoint!.x, endPoint!.y - masterDist),kind:.Cut)
                let e1 = Edge.straightEdgeBetween(e2.end, end: CGPointMake(e2.end.x, h1.end.y), kind: .Cut)
                let e0 = Edge.straightEdgeBetween(e1.end, end: h0.end, kind: .Cut)
                
                returnee.append(h1)
                returnee.append(s0)
                returnee.append(s2)
                returnee.append(s1)
                returnee.append(e0)
                returnee.append(e1)
                returnee.append(e2)
                
                
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
                horizontalFolds = [master]
                returnee.append(master)
                
                print("NO CHILDREN\n")
            }
                // for now, sort children by start point x and then draw master fold edges between them
                // later, we'll have to do fancy intersection stuff
            else{
                
                if var childs = children{
                    
                    //sort children by x position
                    childs.sort({(a, b) -> Bool in return a.startPoint!.x < b.startPoint!.x})
                    
                    //pieces of the master fold, which go inbetween child features
                    var masterPieces:[Edge] = []
                    
                    print("CHILDREN: \(childs.count)")
                    
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
                
                print("!!! CHILDREN !!!\n")

            }
            
            
            for edge in returnee{
                edge.isMaster = true
            }
            
            return returnee
            
        default:
            return []
        }
    }
    
    /// used for quickly testing whether features might overlap
    func boundingBox()->CGRect?{
        
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
    
    
    
    
}