//
//  Plane.swift
//  foldlings
//
//

import Foundation
import CoreGraphics
import SceneKit
import UIKit

func == (lhs: Plane, rhs: Plane) -> Bool
{
    return lhs.hashValue == rhs.hashValue
}

class Plane: Printable, Hashable
{
    var description: String {
        return "\n".join(edges.map({ "\($0)" }))
    }
    
    var hashValue: Int { get {
        return description.hashValue
        }
    }

    
    enum Kind: String {
        case Hole = "Hole"
        case Plane = "Plane"
    }
    
    
    /// whether a plane should end horizontal or vertical after folding
    enum Orientation: String {
        case Horizontal = "Horizontal"
        case Vertical = "Vertical"
    }
    
    var color = getRandomColor(0.8)
    var kind = Kind.Hole
    var orientation = Orientation.Horizontal
    var edges : [Edge]!
    var path = UIBezierPath()
    private var node:SCNNode? = nil
    var masterSphere:SCNNode? = nil
    let transformToCamera = SCNVector3Make(-3.9, -3.5, -4.5)
    let scaleToCamera = SCNVector3Make(0.01, 0.01, 0.01)

    
    
    
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
    
    func clearNode(){
        node = nil
    }
    
    /// makes an SCNNode by extruding the UIBezierPath
    func lazyNode() -> SCNNode{
        
        if node == nil
        {
            
            // make the node
            node = SCNNode()
            var shape = SCNShape(path: path, extrusionDepth: 1)
            
            let material = SCNMaterial()
            
            // holes are black, and extruded to prevent z-fighting
            if(self.kind == .Hole){
                shape = SCNShape(path: path, extrusionDepth: 2)
                material.diffuse.contents = UIColor.whiteColor()
            }
            else{
                // planes are white (for now, random color)
                material.diffuse.contents = self.color
            }
            // planes are visible from both sides
            material.doubleSided = true
            node!.geometry = shape
            node!.geometry?.firstMaterial = material
            
            node!.physicsBody = SCNPhysicsBody(type: SCNPhysicsBodyType.Dynamic, shape: SCNPhysicsShape(geometry: node!.geometry!
                , options: nil))
            
            
            
            // move node to where the camera can see it
            node!.position = transformToCamera
            node!.scale = scaleToCamera
        }
        return node!
    }
    
    
    
    
    /// the fold with minimum y height in a plane
    func bottomFold() -> Edge? {
        
        let maxPoint = CGPointMake(CGFloat.max, CGFloat.max)
        var minEdge:Edge? = nil
        
        var minY:CGFloat = CGFloat.max
        for edge in edges{
            if(edge.kind ==  .Fold) {
                if(edge.start.y < minY) {
                    minEdge = edge
                }
            }
        }
        
        return minEdge
    }
    
    /// the fold with maximum y height in a plane
    func topFold() -> Edge? {
        
        let minPoint = CGPointMake(CGFloat.min, CGFloat.min)
        var maxEdge:Edge? = nil // = Edge(start:  minPoint, end: minPoint, path: UIBezierPath())
        
        var maxY:CGFloat = 0.0
        for edge in edges{
            if(edge.kind ==  .Fold){
                if(edge.start.y > maxY) {
                    maxEdge = edge
                }
            }
        }
        
        return maxEdge
    }
    
    /// close the path and remove MoveToPoint instructions
    func sanitizePath(){
        path = sanitizedPath(path)
        
    }
    
    /// closes and combines paths into one
    /// remove kCGPathElementMoveToPoints in a path, to make it convertible to SCNNode
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
//                outPath.addLineToPoint(p)
                
            case kCGPathElementAddLineToPoint.value:
                let p = currPath.points[0].CGPointValue()
                outPath.addLineToPoint(p)
                
            case kCGPathElementAddQuadCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                outPath.addQuadCurveToPoint(p2, controlPoint: p1)
                
            case kCGPathElementAddCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                let p3 = currPath.points[2].CGPointValue()
                outPath.addCurveToPoint(p3, controlPoint1: p1, controlPoint2: p2)
            default:
                //println("other: \(currPath.type.value)")
                break
            }
        }
        //println(outPath)
        outPath.closePath()
        
        
        return outPath
        
    }
    
    
    func hasEdge(edge:Edge) -> Bool
    {
        return self.edges.contains(edge)
    }
    
    func containerPlane(planes:[Plane]) -> Plane? {
        
        for (i,potentialParent) in enumerate(planes){
            
            //skip it if we're testing against ourselves
            if potentialParent == self{
            continue
            }
            
            for edge in self.edges{
            
                if(potentialParent.path.containsPoint(edge.start)){
                
                    println(potentialParent)
                    println()

                    
                return potentialParent
                    
                }
                
            }
            
        }
    
        return nil
    }
    
}


