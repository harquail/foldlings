//
//  Plane.swift
//  foldlings
//
//  Created by Marissa Allen on 11/1/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import CoreGraphics
import SceneKit
import UIKit


class Plane: Printable {
    var name = "Plane"
    var path = UIBezierPath()
    var description: String {
        return "this is an array of edges"
    }
    
    var edges : [Edge] = []
    
    init(edges : [Edge]){
        self.edges = edges
        
        for (i,e) in enumerate(edges){
            path.appendPath(e.path)
        }
        
        self.sanitizePath()
    }
    
    func addToPlane(edge: Edge){
        edges.append(edge)
        path.appendPath(edge.path)
    }
    
    func node() -> SCNNode{
        
        let node = SCNNode()

        let shape = SCNShape(path: path, extrusionDepth: 0)
        let white = SCNMaterial()
        white.diffuse.contents = UIColor.whiteColor()
        white.doubleSided = true
        
        node.geometry = shape
        node.geometry?.firstMaterial = white
        
        return node
    }
    
    func sanitizePath(){
        path = sanitizedPath(path)

    }
    
    // remove kCGPathElementMoveToPoint
    private func sanitizedPath(path:UIBezierPath) -> UIBezierPath{
        
        let elements = path.getPathElements()
        //
        //        var bezierPoints = [CGPoint]();
        //        var subdivPoints = [CGPoint]();
        //
        //        var index:Int = 0
        let els = elements as [CGPathElementObj]
        var outPath = UIBezierPath()
        
        var priorPoint:CGPoint = els[0].points[0].CGPointValue()
        var nextPoint:CGPoint = els[0].points[0].CGPointValue()
        var priorPath:CGPathElementObj = els[0]
        var currPath:CGPathElementObj = els[0]
        
        outPath.moveToPoint(els[0].points[0].CGPointValue())
        
        for (var i = 1; i < els.count; i++) {
            currPath = els[i]
            switch (currPath.type.value) {
            case kCGPathElementMoveToPoint.value:
                println("moveToPoint")
                let p = currPath.points[0].CGPointValue()
                //                outPath.addLineToPoint(p)
                
            case kCGPathElementAddLineToPoint.value:
                println("subdiv:addLine")
                let p = currPath.points[0].CGPointValue()
                outPath.addLineToPoint(p)
                //                bezierPoints.append(p)
                //                let pointsToSub:[CGPoint] = [priorPoint, p]
                //                subdivPoints  += subdivide(pointsToSub)
                //                priorPoint = p
                //                index++
            case kCGPathElementAddQuadCurveToPoint.value:
                println("subdiv: addQuadCurve")
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                outPath.addQuadCurveToPoint(p1, controlPoint: p2)
                
            case kCGPathElementAddCurveToPoint.value:
                println("subdiv: addCurveToPoint")
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                let p3 = currPath.points[2].CGPointValue()
                outPath.addCurveToPoint(p1, controlPoint1: p2, controlPoint2: p2)
            default:
                println("other: \(currPath.type.value)")
            }
        }
        println(outPath)
        outPath.closePath()
        
        return outPath
        
    }
    
}


