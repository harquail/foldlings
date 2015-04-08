//
//  FreeForm.swift
//  foldlings
//
//  Created by nook on 3/24/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

class FreeForm:FoldFeature{
    
    var path: UIBezierPath?
    var interpolationPoints:[AnyObject] = []
    var lastUpdated:NSDate = NSDate(timeIntervalSinceNow: 0)
    var cachedPath:UIBezierPath = UIBezierPath()
    var closed = false
    
    override init(start: CGPoint) {
        super.init(start: start)
        interpolationPoints.append(NSValue(CGPoint: start))
    }
    
    
    override func getEdges() -> [Edge] {
        if let p = path{
            let edge = Edge(start: p.firstPoint(), end: p.lastPoint(), path: p, kind: .Cut, isMaster: false)
            return [edge]
        }
        else{
            return [Edge.straightEdgeBetween(startPoint!, end: CGPointZero, kind: .Cut)]
        }
    }
    
    func pathThroughTouchPoints() -> UIBezierPath{
    
        if Float(ccpDistance((interpolationPoints.last! as! NSValue).CGPointValue(), endPoint!)) > 10{
            lastUpdated = NSDate(timeIntervalSinceNow: 0)
            
            interpolationPoints.append(NSValue(CGPoint: endPoint!))
            
            var closed = false
            if interpolationPoints.count > 7
                &&
                ccpDistance((interpolationPoints.first! as! NSValue).CGPointValue(), endPoint!) < kMinLineLength/4{
                    closed = true
            }
            
            if(interpolationPoints.count > 3){
                let path = UIBezierPath()
                path.moveToPoint(interpolationPoints[0].CGPointValue())
                path.addLineToPoint(interpolationPoints[1].CGPointValue())
                println(interpolationPoints[1])
                path.appendPath(UIBezierPath.interpolateCGPointsWithCatmullRom(interpolationPoints, closed: closed, alpha: 1))
                path.addLineToPoint(endPoint!)
                cachedPath = path
                return path

            }
            
        }
        return cachedPath
    }

}