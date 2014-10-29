//
//  Sketch.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

//a sketch is a collection of cuts & folds
import Foundation
import CoreGraphics
import UIKit

class Sketch {
    
    
    let MINIMUM_LINE_DISTANCE = 0.5
    
    
    
    //TODO:store lines
    //  edges(Fold?) in ordered array by height
    //  vertices in ordered array
    //  dict of vertices->edges(Fold)
    //  create bounding box per line.  ordered array of rects indexed same as line array

    
    //the folds that define a sketch
    //for now, cuts are in this array too
    var edges : [Edge] = []
    var folds : [Edge] = [] // may not need to keep this but for now
    var adjacency : [CGPoint : Edge] = [CGPoint : Edge]()
    var drivingEdge: Edge!
    
    init()
    {
        //insert master fold
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        let halfH = screenHeight/2.0
        
        let p1 = CGPointMake(0, halfH)
        let p2 = CGPointMake(screenWidth, halfH)
        
        var path = UIBezierPath()
        path.moveToPoint(p1)
        path.addLineToPoint(p2)
        //TODO: refactor this to be part of edge or pull style stuff into here rather than sketchview
        path.setLineDash([10,5], count: 2, phase:0)
        path.lineWidth = kLineWidth
        
        drivingEdge = Edge(start: p1, end: p1, path: path, kind: Edge.Kind.Fold)
        drivingEdge.fold = .Valley
        edges.append(drivingEdge)

    }
    
    
    func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind)
    {
        var e = Edge(start: start, end: end, path: path, kind: kind)
        edges.append(e)
        adjacency[start] = e
        adjacency[end] = e
        
        // keep folds in ascending order by start position y height from bottom up
        // note y starts at 0 on top of screen
        // inefficient? who cares
        if kind == .Fold
        {
            if e !== drivingEdge //NOTE: driving fold not in folds
            {
                folds.append(e)
                folds.sort({ $0.start.y > $1.start.y })
            }
        }
        
        //skip 0th fold
        //TODO: this is a placeholder, not how you actually do it
        for var i = 0; i < folds.count; i++ {
            if (i % 2) == 0 {
                folds[i].fold = .Valley
            } else {
                folds[i].fold = .Hill
            }
        }
    }
    
    //TODO: needs to work
    func removeEdge()
    {
        
    }
    
    
}

