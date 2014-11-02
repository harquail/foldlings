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
    var bEdge1: Edge!
    var bEdge2: Edge!
    var bEdge3: Edge!
    var bEdge4: Edge!
    
    init()
    {
        //insert master fold and make borders into cuts
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

        // make border into cuts
        makeBorderEdges( screenWidth, height: screenHeight)

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
    
    func makeBorderEdges(width: CGFloat, height: CGFloat){
        
        //border paths
        var path1 = UIBezierPath()
        var path2 = UIBezierPath()
        var path3 = UIBezierPath()
        var path4 = UIBezierPath()

        // border points
        let b1 = CGPointMake(0, 0)
        let b2 = CGPointMake(width, 0)
        let b3 = CGPointMake(width, height)
        let b4 = CGPointMake(0, height)
        
        //border edges
        path1.moveToPoint(b1)
        path1.addLineToPoint(b2)
        bEdge1 = Edge(start: b1, end: b2, path: path1, kind: Edge.Kind.Cut)
        edges.append(bEdge1)
        
        path2.moveToPoint(b2)
        path2.addLineToPoint(b3)
        bEdge2 = Edge(start: b2, end: b3, path: path2, kind: Edge.Kind.Cut)
        edges.append(bEdge2)
        
        path3.moveToPoint(b3)
        path3.addLineToPoint(b4)
        bEdge3 = Edge(start: b3, end: b4, path: path3, kind: Edge.Kind.Cut)
        edges.append(bEdge3)
        
        path4.moveToPoint(b4)
        path4.addLineToPoint(b1)
        bEdge4 = Edge(start: b4, end: b1, path: path4, kind: Edge.Kind.Cut)
        edges.append(bEdge4)
    }
    
}

