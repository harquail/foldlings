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
    
//    init()
//    {
//
//    }
    
    
    func addEdge(start:CGPoint,end:CGPoint){
        edges += [Edge(start: start, end: end)]
    }
    
    
}

