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


struct Edge: Printable {
    var name = "Edge"
    var description: String {
        return "Start: \(start), End: \(end), \n \(kind.rawValue),\(fold.rawValue)"
    }

    
    enum Kind: String {
        case Fold = "Fold"
        case Cut = "Cut"
    }
    
    enum Fold: String {
        case Hill = "Hill"
        case Valley = "Valley"
        case Unknown = "Unknown"
    }
    
    struct Color {
        static var Hill:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
        static var Valley:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
        static var Fold:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 255.0)
        static var Cut:UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 255.0)
    }

    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var fold = Fold.Unknown
    var kind = Kind.Cut
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath){
        self.start = start
        self.end = end
        self.path = path
    }
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Kind, fold: Fold = Fold.Unknown) {
        self.init(start: start, end: end, path:path)
        self.kind = kind
        self.fold = fold
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
    
    
    static func getColor(kind: Edge.Kind, fold: Edge.Fold = Edge.Fold.Unknown) -> UIColor
    {
        var color: UIColor!
        switch kind
        {
        case .Fold:
            switch fold {
                case .Hill:
                    color = Color.Hill
                case .Valley:
                    color = Color.Valley
                default:
                    color = Color.Fold
            }
        case .Cut:
            color = Color.Cut
        default:
            color = Color.Cut
        }
        return color
    }
    
    func getColor() -> UIColor
    {
        return Edge.getColor(self.kind, fold:self.fold)
    }
    
    
    
    
    
}