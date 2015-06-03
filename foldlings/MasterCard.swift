//
//  MasterCard.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved


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
        
        //if mastercard has already been created, return edges
        if let returnee = featureEdges {
            return returnee
        }
//        println("MASTER: cache miss")

        
        //if the mastercard hasn't been created then create the mastercard
        let top = Edge.straightEdgeBetween(startPoint!, end:CGPointMake(endPoint!.x, startPoint!.y), kind: .Cut, feature: self)
        let bottom = Edge.straightEdgeBetween(endPoint!, end:CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut, feature: self)
        let midPointDist = (endPoint!.y - startPoint!.y)/2
        let l0 = Edge.straightEdgeBetween(startPoint!, end: CGPointMake(startPoint!.x, startPoint!.y + midPointDist), kind: .Cut, feature: self)
        let l1 = Edge.straightEdgeBetween(l0.end, end: CGPointMake(startPoint!.x, endPoint!.y), kind: .Cut, feature: self)
        let r1 = Edge.straightEdgeBetween(endPoint!, end: CGPointMake(endPoint!.x,endPoint!.y-midPointDist), kind: .Cut, feature: self)
        let r0 = Edge.straightEdgeBetween(r1.end, end: CGPointMake(endPoint!.x,startPoint!.y), kind: .Cut, feature: self)
        
        //set edges in feature
        var returnee = [top,bottom,l0,l1,r0,r1]
        // if there are no children, then we just need to draw a single fold
        // maybe we don't want master here after all, but for now the only horizontal folds are the driving edge
        let master = Edge.straightEdgeBetween(l0.end, end:r1.end, kind: .Fold, feature: self)

        
        returnee.append(master)
        horizontalFolds = [master]
//        
        
        returnee.map({$0.isMaster = true})
        //set feature edges
        featureEdges = returnee
        //assign edges to feature 
        //claimEdges()
        return returnee
        
    }
    
    
    override func tapOptions() -> [FeatureOption]?{
        
        return [FeatureOption.PrintSketch]
        
    }
    
    /// bounding box is start & end point
    override func boundingBox() -> CGRect? {
        return CGRectMake(startPoint!.x, startPoint!.y, endPoint!.x - startPoint!.x, endPoint!.y - startPoint!.y)
    }
}