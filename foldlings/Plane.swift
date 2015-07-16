//
// Plane.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

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
        return "\(self.kind.rawValue), \(self.orientation.rawValue)" + join("|",edges.map({$0.description}))
    }
    
    var hashValue: Int { get {
        return join("|",edges.map({$0.description})).hashValue
        }
    }
    
    enum Kind: String {
        case Hole = "Hole"
        case Plane = "Plane"
        case Flap = "Flap"
    }
    
    
    /// whether a plane should end horizontal or vertical after folding
    enum Orientation: String {
        case Horizontal = "Horizontal"
        case Vertical = "Vertical"
    }
    
    var kind = Kind.Hole
    var orientation = Orientation.Vertical
    var color = getRandomColor(0.5)
    //var color = getOrientaionColorTrans(self.orientation)
    var edges : [Edge]!
    var path = UIBezierPath()
    var feature:FoldFeature!
    var topEdge : Edge!
    var bottomEdge : Edge!
    var parent : Plane!
    var children : [Plane] = []
    var foldcount : Int!
    var NegNinety : Bool = false
    
    
    // mark if this plane is the master's feature top or bottom plane
    var masterTop: Bool = false
    var masterBottom: Bool = false
    
    var node:SCNNode? = nil
    var masterSphere:SCNNode? = nil
    let transformToCamera = SCNVector3Make(-3.9, +5, -4.5)
    let scaleToCamera = SCNVector3Make(0.01, -0.01, 0.01)
    
    
    
    init()
    {
        self.edges = []
    }
    
    init(edges : [Edge])
    {
        self.edges = edges
        edges.map({self.path.appendPath($0.path)})// create one path for all edges
        //#TODO: put back
        self.sanitizePath()
    }
    
    func clearNode(){
        node = nil
    }
    
    /// makes an SCNNode by extruding the UIBezierPath
    func makeNode() -> SCNNode
    {
        
        // make the node
        node = SCNNode()
        var shape : SCNShape
        
        // loop through children
        for c in children {
            // if hole then just add path to parent plane
            if c.kind == .Hole && c.path.isClockwise(){
                var cEdges = c.edges
                // add hole edges to plane path
                cEdges.map({self.path.appendPath($0.path)})
            }
        }
        
        shape = SCNShape(path: path, extrusionDepth: 5)
        
        let material = SCNMaterial()
        
        material.diffuse.contents = self.color
        material.shininess = 0
        
        // planes are visible from both sides
        material.doubleSided = true
        node!.geometry = shape
        node!.geometry?.firstMaterial = material
        
        // move node to where the camera can see it
        node!.position = transformToCamera
        node!.scale = scaleToCamera
        return node!
        //}
    }
    
    /// close the path and remove MoveToPoint instructions
    func sanitizePath(){
        //TODO: fix me to use performancebezier
        path = sanitizedPath(path)
        
    }
    
    /// closes and combines paths into one
    /// remove kCGPathElementMoveToPoints in a path, to make it convertible to SCNNode
    //TODO: convert this to use performanceBezier
    private func sanitizedPath(path:UIBezierPath) -> UIBezierPath{

        
        let elements = path.getPathElements()
        if(elements.isEmpty){
            return UIBezierPath()
        }
        
        let els = elements as! [CGPathElementObj]
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
                //                print("skipped move to point ")
            case kCGPathElementAddLineToPoint.value:
                let p = currPath.points[0].CGPointValue()
                outPath.addLineToPoint(p)
                //                print("\t add line to \(p)")
                
                
            case kCGPathElementAddQuadCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                outPath.addQuadCurveToPoint(p2, controlPoint: p1)
                //                print("\t add quad curve to \(p2)")
                
            case kCGPathElementAddCurveToPoint.value:
                let p1 = currPath.points[0].CGPointValue()
                let p2 = currPath.points[1].CGPointValue()
                let p3 = currPath.points[2].CGPointValue()
                outPath.addCurveToPoint(p3, controlPoint1: p1, controlPoint2: p2)
                //                print("\t add curve to \(p3)")
                
            default:
                break
            }
        }
        //        println("reached close")
        outPath.closePath()
        outPath.flatness = 3.0;
        return outPath
    }
    
    
    func hasEdge(edge:Edge) -> Bool
    {
        return self.edges.contains(edge)
    }
    
    
}


