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
    //  edges(Fold?) in ordered array
    //  vertices in ordered array
    //  dict of vertices->edges(Fold)
    //  create bounding box per line.  ordered array of rects indexed same as line array

    
    //the folds that define a sketch
    //for now, cuts are in this array too
    var edges : [Edge] = []
    var vertices : [CGPoint] = []
    var adjacency : [CGPoint : Edge] = [CGPoint : Edge]()
    
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
        path.lineWidth = 2.0
        
        self.addEdge(p1 ,end: p2,path: path , kind:Edge.Kind.Fold)
        edges[0].fold = .Valley

    }
    
    
    func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind){
        edges += [Edge(start: start, end: end, path: path, kind: kind)]
    }
    
    
}

