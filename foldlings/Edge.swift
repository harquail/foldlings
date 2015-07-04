//
//  Edge.swift
//
// foldlings
// © 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import CoreGraphics
import UIKit

infix operator ≈ { associativity left precedence 160 }

func == (lhs: Edge, rhs: Edge) -> Bool {
    return lhs === rhs
}


/// equality that considers twins
func ~= (lhs: Edge, rhs: Edge) -> Bool {
    return lhs == rhs || lhs == rhs.twin
}

/// equality that only considers start & end points
func ≈ (lhs: Edge, rhs: Edge) -> Bool {
    return lhs.start == rhs.start && lhs.end == rhs.end
}

class Edge: NSObject, Printable, Hashable, NSCoding {
    override var description: String {
        
        return "Start: \(start), End: \(end), Type: \(kind.rawValue), Feature: \(feature), dirty: \(dirty), \(Bezier.endingElementsOf(path))\n"
        
    }
    
    override var hashValue: Int { get {
        return description.hashValue
        }
    }
    
    var twin:Edge!
    var crossed = false
    var plane:Plane?
    var dirty = true //if the edge is dirty it'll be reevaluated for planes
    var deltaY:CGFloat? = nil  //distance moved from original y position during this drag, nil if not being dragged
   
    
    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var kind = Kind.Cut
    var adjacency: [Edge] = []
    var isMaster = false
    var colorOverride:UIColor?
    var feature:FoldFeature?
    
    enum Kind: String {
        case Fold = "Fold"
        case Cut = "Cut"
    }
    
    struct Color {
        static var Hill:UIColor = UIColor(red: 0.0, green: 0.0, blue: 255.0, alpha: 1.0)
        static var Valley:UIColor = UIColor(red: 0.0, green: 255.0, blue: 0.0, alpha: 1.0)
        static var Fold:UIColor = UIColor(red: 255.0, green: 0.0, blue: 0.0, alpha: 1.0)
        static var Cut:UIColor = UIColor(red: 0.0, green: 0.0, blue: 0.0, alpha: 1.0)
        static var Tab:UIColor = UIColor(red: 0.0, green: 150.0, blue: 150.0, alpha: 1.0)
        
    }
    
    /// color for printing with laser cutter
    struct LaserColor {
        static var Hill:UIColor = UIColor.blackColor()
        static var Valley:UIColor = UIColor.blackColor()
        static var Fold:UIColor = UIColor.blackColor()
        static var Cut:UIColor = UIColor.blackColor()
    }
    
    init(start:CGPoint,end:CGPoint, path:UIBezierPath){
        self.start = start
        self.end = end
        self.path = path
//        self.colorOverride = plane.color
    }
    
    convenience init(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Kind, isMaster:Bool = false, feature:FoldFeature? = nil) {
        self.init(start: start, end: end, path:path)
        self.kind = kind
        self.isMaster = isMaster
        self.feature = feature

    }
    
    
    required init(coder aDecoder: NSCoder) {
        self.start = aDecoder.decodeCGPointForKey("start")
        self.end = aDecoder.decodeCGPointForKey("end")
        self.path = aDecoder.decodeObjectForKey("path") as! UIBezierPath
        self.kind = Kind(rawValue: (aDecoder.decodeObjectForKey("kind") as! String))!
        self.isMaster = aDecoder.decodeBoolForKey("isMaster")
        self.twin = aDecoder.decodeObjectForKey("twin") as! Edge
        self.adjacency = aDecoder.decodeObjectForKey("adj") as? [Edge] ?? []
        self.feature = aDecoder.decodeObjectForKey("feature") as? FoldFeature
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        aCoder.encodeCGPoint(start, forKey: "start")
        aCoder.encodeCGPoint(end, forKey: "end")
        aCoder.encodeObject(path, forKey: "path")
        aCoder.encodeObject( self.kind.rawValue, forKey:"kind")
        aCoder.encodeBool(self.isMaster, forKey: "isMaster")
        aCoder.encodeObject(self.twin, forKey: "twin")
        aCoder.encodeObject(self.adjacency, forKey: "adj")
        aCoder.encodeObject(self.feature, forKey: "feature")
    }
    
    /// makes a straight edge between two points, constructing the path as well
    class func straightEdgeBetween(start:CGPoint,end:CGPoint, kind:Edge.Kind, feature: FoldFeature) -> Edge{
        let path = UIBezierPath()
        path.moveToPoint(start)
        path.addLineToPoint(end)
        return Edge(start: start, end: end, path: path, kind:kind, feature: feature)
    }
    
    // creates a copy of path?
    class func tapTargetForPath(path:UIBezierPath, radius: CGFloat)->UIBezierPath{
        let tapTargetPath = CGPathCreateCopyByStrokingPath(path.CGPath, nil, radius, path.lineCapStyle, path.lineJoinStyle, path.miterLimit)
        let tapTarget = UIBezierPath(CGPath: tapTargetPath)
        return tapTarget
        
    }
    
    /// edge hit test
    class func hitTest(path: UIBezierPath, point:CGPoint, radius:CGFloat = kHitTestRadius) -> CGPoint? {
        var np:CGPoint? = nil
        let tapTarget = Edge.tapTargetForPath(path, radius: radius).CGPath
        if  CGPathContainsPoint(tapTarget, nil, point, false)
        {
            np = getNearestPointOnPath(point, path)
        }
        return np
    }
    
    func hitTest(point:CGPoint, radius:CGFloat = kHitTestRadius) -> CGPoint? {
        return Edge.hitTest(path, point:point, radius:radius)
    }
    
    
    /// get the color of the edge by type
    class func getColor(kind: Edge.Kind) -> UIColor
    {
        var color: UIColor!
        switch kind
        {
        case .Fold:
            color = Color.Fold
        case .Cut:
//            color = getRandomColor(0.8);
                        color = Color.Cut
        default:
            color = Color.Cut
        }
        return color
    }
    
    
    class func getLaserColor(kind: Edge.Kind) -> UIColor
    {
        var color: UIColor!
        switch kind
        {
        case .Fold:
            color = LaserColor.Fold
        case .Cut:
            color = LaserColor.Cut
        default:
            color = LaserColor.Cut
        }
        return color
    }
    
    func centerOfStraightEdge() -> CGPoint{
        
        let averaged = CGPointAdd(start,end)
        return CGPointMake(averaged.x/2, averaged.y/2)
    }
    
    func getLaserColor() -> UIColor
    {
        return Edge.getLaserColor(self.kind)
    }
    
    func getColor() -> UIColor
    {
        if self.colorOverride != nil {
            return self.colorOverride!
        } else {
            return Edge.getColor(self.kind)
        }
    }
    
    /// this is completely unecessary, but convenient
    func yDistTo(e:Edge)-> CGFloat{
        
        return abs(self.start.y - e.start.y)
        
    }
    
    func snapStart(#to:CGPoint){
        snapToPoint(true,snapTo:to)
    }
    func snapEnd(#to:CGPoint){
        snapToPoint(false,snapTo:to)
    }

    func snapToPoint (snapStart:Bool,snapTo:CGPoint) {
        let movedPoint = snapStart ? start : end

        if(snapStart){
            if(!(CGPointEqualToPoint(start,snapTo))){
                println("moved \(start) to \(snapTo)")
                start = snapTo
            }
        }
        else{
            
            if(!(CGPointEqualToPoint(end,snapTo))){
                
                println("moved \(end) to \(snapTo)")
                end = snapTo
            }
        }
        //TODO: also have to do things to the path
    }
    
    //length of a straight edge — should do something better for curves
    func length() -> CGFloat{
        return ccpDistance(start, end)
    }
    
    func edgeSplitByPoints(breakers:[CGPoint]) ->[Edge]{
        
        var edges:[Edge] = []

        let paths = Bezier.pathSplitByPoints(path, breakers: breakers)
        
        if paths.count == 1{
            return [self]
        }
        
        // make edges from paths
        for p in paths{
//            println("\(p.firstPoint()) | \(p.lastPoint())")
            let e = Edge(start: p.firstPoint(), end: p.lastPoint(), path: p, kind: self.kind, isMaster: false, feature: self.feature!)
            edges.append(e)
        }
        
        return edges
    }

    
}