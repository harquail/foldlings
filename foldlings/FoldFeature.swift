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
         Slider
    }
    
    enum ValidityState {
        case Invalid,
        Fixable,
        Valid
    }
    
    var featurePlanes:[Plane] = []
    var drawingPlanes:[Plane] = []
    var horizontalFolds:[Edge] = []
    var parent:FoldFeature?
    var drivingFold:Edge?
    var startPoint:CGPoint?
    var endPoint:CGPoint?
    var foldKind:Kind = .Box
    
    func getEdges()->[Edge]{
        switch(foldKind){
        case .Box:
            
//                  h0
//            S---------
//            |         | e0
//         s0 |     h1  |
//            -----------
//         s1 |         | e1
//     _______|         |__________
//            |         |
//         s2 |     h2  | e2
//            ----------E
            
            var returnee:[Edge] = []
            let h0 = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut)
            returnee.append(h0)
            if let master = drivingFold{
                
            }
            return [h0,];
        default:
                return []
        }
    }
    
    

}