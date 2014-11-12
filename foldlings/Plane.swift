//
//  Plane.swift
//  foldlings
//
//

import Foundation
import CoreGraphics
import SceneKit
import UIKit

func == (lhs: Plane, rhs: Plane) -> Bool {
    return lhs.hashValue == rhs.hashValue
}


class Plane: Printable, Hashable {
    var edges : [Edge]!
    var path = UIBezierPath()
    var description: String {
        return "\n".join(edges.map({ "\($0)" }))
    }
    
    var hashValue: Int { get {
        return description.hashValue
        }
    }
    

    
    init()
    {
        self.edges = []
    }
    
    init(edges : [Edge])
    {
        self.edges = edges
        
        for (i,e) in enumerate(edges){
            path.appendPath(e.path)
        }
        
        self.sanitizePath()
    }
    
    func addToPlane(edge: Edge)
    {
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
    
    // remove kCGPathElementMoveToPoints in a path, to make it convertible to SCNNode
    private func sanitizedPath(path:UIBezierPath) -> UIBezierPath{
        
        let elements = path.getPathElements()

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
                let p = currPath.points[0].CGPointValue()
                
            case kCGPathElementAddLineToPoint.value:
                let p = currPath.points[0].CGPointValue()
                outPath.addLineToPoint(p)
                
            case kCGPathElementAddQuadCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                outPath.addQuadCurveToPoint(p1, controlPoint: p2)
                
            case kCGPathElementAddCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                let p3 = currPath.points[2].CGPointValue()
                outPath.addCurveToPoint(p1, controlPoint1: p2, controlPoint2: p2)
            default:
                //println("other: \(currPath.type.value)")
                break
            }
        }
        //println(outPath)
        outPath.closePath()
        
        
        return outPath
        
    }
    
}


