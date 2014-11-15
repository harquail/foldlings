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
    
    
    enum Kind: String {
        case Hole = "Hole"
        case Plane = "Plane"
    }
    
    enum Orientation: String {
        case Horizontal = "Horizontal"
        case Vertical = "Vertical"
    }
    
    var kind = Kind.Hole
    var orientation = Orientation.Horizontal
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

    func node() -> SCNNode{
        
        let node = SCNNode()
        
        // TODO: might need to increase extrusion depth for holes (if there's z-fighting
        let shape = SCNShape(path: path, extrusionDepth: 0)
        let material = SCNMaterial()

        if(self.kind == .Hole){
        material.diffuse.contents = getRandomColor(1)
        }
        else{
            material.diffuse.contents = UIColor.whiteColor()
        }
        material.doubleSided = true
        node.geometry = shape
        node.geometry?.firstMaterial = material
        
        return node
    }
    
    func bottomFold() -> Edge{
        
        let maxPoint = CGPointMake(CGFloat.max, CGFloat.max)
        var minEdge:Edge = Edge(start:  maxPoint, end: maxPoint, path: UIBezierPath())
        
        for edge in edges{
        
            if(edge.kind ==  .Fold){
                
                if(edge.start.y < minEdge.start.y){
                
                minEdge = edge
                    
                }
            }
        }
        
        return minEdge
    
    }
    
    
    func topFold() -> Edge{
        
        let minPoint = CGPointMake(CGFloat.min, CGFloat.min)
        var maxEdge:Edge = Edge(start:  minPoint, end: minPoint, path: UIBezierPath())
        
        for edge in edges{
            
            if(edge.kind ==  .Fold){
                
                if(edge.start.y > maxEdge.start.y){
                    
                    maxEdge = edge
                    
                }
            }
        }
        
        return maxEdge
        
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
                outPath.addLineToPoint(p)
                
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


