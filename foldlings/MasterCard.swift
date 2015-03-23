//
//  MasterCard.swift
//  foldlings
//
//  Created by nook on 3/22/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

class MasterCard:FoldFeature{
    
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
    
    override func getEdges()->[Edge]{
        
        if let returnee = cachedEdges {
            return returnee
        }
        
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
        claimEdges()
        return returnee
        
    }
    
     override func boundingBox() -> CGRect? {
        return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
    }
}