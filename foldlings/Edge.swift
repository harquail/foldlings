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

struct EdgeColor {
    static var Hill:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
    static var Valley:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
    static var Fold:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
    static var Cut:UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 255.0)
}

//for now, only straight folds/cuts
struct Edge {
    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var orientation = EdgeType.Cut
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath){
        self.start = start
        self.end = end
        self.path = path
    }
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath, type: EdgeType) {
        self.init(start: start, end: end, path:path)
        self.orientation = type
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
    
    func getColor() -> UIColor
    {
        var color: UIColor!
        switch orientation
        {
        case .Fold:
            color = EdgeColor.Fold
        case .Hill:
            color = EdgeColor.Hill
        case .Valley:
            color = EdgeColor.Valley
        default:
            color = EdgeColor.Cut
        }
        return color
    }
    
    
}