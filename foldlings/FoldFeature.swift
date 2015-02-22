//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

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
        case Invalid,
        Fixable,
        Valid
    }
    
    var featurePlanes:[Plane] = []
    var drawingPlanes:[Plane] = []
    var horizontalFolds:[Edge] = []
    var children:[FoldFeature]?
    var drivingFold:Edge?
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    var foldKind:Kind = .Box
    
    
    func bounds()->CGRect?{
        if self.foldKind == .MasterCard{
            
        }
        return nil
        
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
                
                
                let s0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, startPoint!.y + masterDist), kind: .Fold)
                let h1 = Edge.straightEdgeBetween(s0.end, end:CGPointMake(endPoint!.x, s0.end.y), kind: .Fold)
                
                let s2 = Edge.straightEdgeBetween(h2.start, end:CGPointMake(startPoint!.x, master.start.y), kind: .Cut)
                let s1 = Edge.straightEdgeBetween(s0.start, end:s2.end, kind: .Cut)
                
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
            
            //for now, sort children by start point x and then draw master fold edges between them
            
            //maybe we don't want master here after all
            let master = Edge.straightEdgeBetween(r1.end, end:l0.end, kind: .Fold)
            
            horizontalFolds = [master]
            
            let returnee = [top,bottom,l0,l1,r0,r1,master]
            for edge in returnee{
                edge.isMaster = true
            }

            return returnee

        default:
            return []
        }
    }
    
    init(start:CGPoint,kind:Kind){
        
        startPoint = start
        foldKind = kind
        
    }
    
    
    
    
}