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
    var adjacency : [CGPoint : Edge]!
    
    
    func addEdge(start:CGPoint,end:CGPoint){
        edges += [Edge(start: start, end: end)]
    }
    
    //fold neares to point
    func edgeNearPoint(point:CGPoint)->Edge{
        
        var smallestDist = Float.infinity
        var nearestEdge = Edge(start: CGPointZero, end: CGPointZero)
        
        
        
        //find the fold with the smallest distance to the given point
        //TODO: make work for curvy cuts
        for edge in edges{
            let currentDist = distanceBetween(point, startLine: edge.start, endLine: edge.end)
            if(currentDist<smallestDist){
                nearestEdge = edge
                smallestDist = currentDist
            }
            
        }
        
        return nearestEdge
    }
    
    //distance between a point and line
    private func distanceBetween(point:CGPoint,startLine:CGPoint, endLine:CGPoint) -> Float{
        //#TODO
        return 0.5
    }
//    func changeFoldOrientationTo(var fold:Fold,orientation:FoldOrientation){
//        fold.orientation=orientation
//    }
}

