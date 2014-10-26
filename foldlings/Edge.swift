//
//  Edge.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

//the direction of the fold.  For now, cuts are considered a type of fold -- will have to reconsider later
enum EdgeType{
    case Hill
    case Valley
    case Fold
    case Cut
}

//for now, only straight folds/cuts
struct Edge {
    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var orientation = EdgeType.Hill
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath){ //, type: EdgeType) {
        self.start = start
        self.end = end
        self.path = path
    }
    
    func tapTargetForPath(path:UIBezierPath)->UIBezierPath{
        
        let STROKE_HIT_RADIUS = CGFloat(25.0)
        
        let tapTargetPath = CGPathCreateCopyByStrokingPath(path.CGPath, nil, STROKE_HIT_RADIUS, path.lineCapStyle, path.lineJoinStyle, path.miterLimit)
        
        let tapTarget = UIBezierPath(CGPath: tapTargetPath)
        
        return tapTarget
        
    }
    
    func hitTest(point:CGPoint) -> Bool{
        
        return tapTargetForPath(path).containsPoint(point)
        
    }
}