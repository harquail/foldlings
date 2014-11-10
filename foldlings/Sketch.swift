//
//  Sketch.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

//a sketch is a collection of cuts & folds
import Foundation
import CoreGraphics
import UIKit

class Sketch : NSObject,NSCoding  {
    
    @IBOutlet var previewButton:UIButton?
    
    
    //the folds that define a sketch
    //for now, cuts are in this array too
    var edges : [Edge] = []
    var folds : [Edge] = [] // may not need to keep this but for now
    var visited : [Edge]!
    var adjacency : [CGPoint : [Edge]] = [CGPoint : [Edge]]()
    var drivingEdge: Edge!
    var bEdge1: Edge!
    var bEdge2: Edge!
    var bEdge3: Edge!
    var bEdge4: Edge!

    var name:String
    
    var drawingBounds: CGRect = CGRectMake(0, 0, 0, 0)

//
    init(named:String)
    {
        //insert master fold and make borders into cuts
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        let halfH = screenHeight/2.0

        
        let p1 = CGPointMake(0, halfH)
        let p2 = CGPointMake(screenWidth, halfH)
        
        var path = UIBezierPath()
        path.moveToPoint(p1)
        path.addLineToPoint(p2)
        // this style stuff below is ugly but whatever
        path.setLineDash([10,5], count: 2, phase:0)
        path.lineWidth = kLineWidth
        
        drivingEdge = Edge(start: p1, end: p1, path: path, kind: Edge.Kind.Fold, isMaster: true)
        drivingEdge.fold = .Valley
        edges.append(drivingEdge)
        name = named
        
        
        let scaleFactor = CGFloat(0.9)
        super.init()
        makeBorderEdges(screenWidth*scaleFactor, height: screenHeight*scaleFactor)

    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        
        aCoder.encodeObject(edges, forKey: "edges")
        aCoder.encodeObject(folds, forKey: "folds")
        
        //convert CGPoints to NSValues
        var adjsWithValues :[NSValue:Edge] = Dictionary<NSValue,Edge>()

        for (point,edge) in adjacency{
            //TODO: wooppsssyyy
//            adjsWithValues[NSValue(CGPoint:point)]=edge
        }
        
        aCoder.encodeObject(adjsWithValues, forKey: "adj")
        aCoder.encodeObject(drivingEdge,forKey:"driving")
        aCoder.encodeObject(bEdge1,forKey:"bEdge1")
        aCoder.encodeObject(bEdge2,forKey:"bEdge2")
        aCoder.encodeObject(bEdge3,forKey:"bEdge3")
        aCoder.encodeObject(bEdge4,forKey:"bEdge4")
        aCoder.encodeObject(name, forKey:"name")
        
    }
    
    required init(coder aDecoder: NSCoder) {
        drawingBounds = CGRectMake(0, 0, 0, 0)
        self.edges = aDecoder.decodeObjectForKey("edges") as Array
        self.folds = aDecoder.decodeObjectForKey("folds") as Array
        
        //convert NSValues to CGPoints
        var adjsWithValues :[NSValue:Edge] = aDecoder.decodeObjectForKey("adj") as Dictionary<NSValue,Edge>
        for (p,e) in adjsWithValues{
            //TODO: woopssyy
//            adjacency[p.CGPointValue()]=e
        }
        
        drivingEdge = aDecoder.decodeObjectForKey("driving") as Edge
        bEdge1 = aDecoder.decodeObjectForKey("bEdge1") as Edge
        bEdge2 = aDecoder.decodeObjectForKey("bEdge2") as Edge
        bEdge3 = aDecoder.decodeObjectForKey("bEdge3") as Edge
        bEdge4 = aDecoder.decodeObjectForKey("bEdge4") as Edge
        name = aDecoder.decodeObjectForKey("name") as String
        
    }
    
    
    
    func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind) -> Edge
    {
        var e = Edge(start: start, end: end, path: path, kind: kind)
        edges.append(e)
        //TODO: more here to work correctly
        if adjacency[start] != nil{
            adjacency[start]!.append(e)
        } else {
            adjacency[start] = [e]
        }
        if adjacency[end] != nil {
            adjacency[end]!.append(e)
        } else {
            adjacency[end] = [e]
        }
        
        // keep folds in ascending order by start position y height from bottom up
        // note y starts at 0 on top of screen
        // inefficient? who cares
        if kind == .Fold
        {
            if e !== drivingEdge //NOTE: driving fold not in folds
            {
                folds.append(e)
                folds.sort({ $0.start.y > $1.start.y })
            }
        }
        
        // check if our new edge is a hole that encloses other edges
        if CGPointEqualToPoint(e.start, e.end)
        {
            if let collisions = shapeHitTest(path)
            {
                for collidingEdge in collisions {
                    self.removeEdge(collidingEdge)
                }
            }
        }
        
        //skip 0th fold
        initPlanes()
        
        return e
    }
    
    //TODO: needs to work
    func removeEdge(edge:Edge)
    {
        if !edge.isMaster {
            edge.path.removeAllPoints()
            edges = edges.filter({ $0 != edge })
            if adjacency[edge.start] != nil {
                adjacency[edge.start] = adjacency[edge.start]!.filter({ $0 != edge })
            }
            if adjacency[edge.end] != nil {
                adjacency[edge.end] = adjacency[edge.end]!.filter({ $0 != edge })
            }

            initPlanes()
        }
    }
    
    func initPlanes()
    {
        //TODO: this is a placeholder, not how you actually do it
        for var i = 0; i < folds.count; i++ {
            if (i % 2) == 0 {
                folds[i].fold = .Valley
            } else {
                folds[i].fold = .Hill
            }
        }

    }
    
    /// makes border edges 
    /// NOTE: width and height here are actually aboslute positions for the lines rather than the width/height
    func makeBorderEdges(width: CGFloat, height: CGFloat){
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        
        //border paths
        var path1 = UIBezierPath()
        var path2 = UIBezierPath()
        var path3 = UIBezierPath()
        var path4 = UIBezierPath()

        // border points
        let downabit:CGFloat = -50.0
        let b1 = CGPointMake(screenWidth-width, screenHeight-height + downabit) //topleft
        let b2 = CGPointMake(width, screenHeight-height + downabit)  //topright
        let b3 = CGPointMake(width, height + downabit)   //bottomright
        let b4 = CGPointMake(screenWidth-width, height + downabit)  //bottomleft
        
        //border edges
        path1.moveToPoint(b1)
        path1.addLineToPoint(b2)
        bEdge1 = Edge(start: b1, end: b2, path: path1, kind: Edge.Kind.Cut, isMaster:true)
        edges.append(bEdge1)
        
        path2.moveToPoint(b2)
        path2.addLineToPoint(b3)
        bEdge2 = Edge(start: b2, end: b3, path: path2, kind: Edge.Kind.Cut, isMaster:true)
        edges.append(bEdge2)
        
        path3.moveToPoint(b3)
        path3.addLineToPoint(b4)
        bEdge3 = Edge(start: b3, end: b4, path: path3, kind: Edge.Kind.Cut, isMaster:true)
        edges.append(bEdge3)
        
        path4.moveToPoint(b4)
        path4.addLineToPoint(b1)
        bEdge4 = Edge(start: b4, end: b1, path: path4, kind: Edge.Kind.Cut, isMaster:true)
        edges.append(bEdge4)
        
        // note width here has to subtract the border
        drawingBounds =  CGRectMake(b1.x, b1.y, width - ((screenWidth - width)), height - (screenHeight - height))
    }
    
    func getPlanes() -> [Plane]
    {
        var planes : [Plane] = []
        var p = Plane()
        visited = []
 
        for (i, e) in enumerate(edges)//traverse edges
        {

            if !inVisited(e) && i > 4 //skip over edges alreay visited and first 5 edges (temporary)
            {
                visited.append(e)
                let closest = getClosest(e, start: e)// get closest adjacent edge
                p = makePlane(closest, first: e, plane: p)
                //save plane in planes
                planes.append(p)
                
            }
        }
        //println(planes.count)
        return planes
    }
    
    //checks if edge has already been visited
    func inVisited(edge: Edge)-> Bool
    {
        for e in visited
        {
            if (e.start == edge.start && e.end == edge.end)||(e.start == edge.end && e.end == edge.start)
            {
                return true
            }
        }
        return false
    }
    
    // uses adjacency to make a plane given an edge
    func makePlane(edge: Edge, first: Edge, plane: Plane) -> Plane// recursive
    {
        if edge != first && !plane.inPlane(edge)// and if the edge is not already in the plane
        {
            let closest = getClosest(edge, start: first)// get closest adjacent edge
            plane.addToPlane(closest)
            visited.append(closest)
            return makePlane(closest, first: first, plane: plane)
        }
        //sanitize plane
        return plane
    }

    
    //get closest adjancent edge
    // get angle between lines
    func getClosest(current: Edge, start: Edge) -> Edge
    {
        var closest: Edge!
        for e in adjacency[current.end]!
        {
            if e != current && e != start
            {
                if closest == nil  // make the first edge the closest
                {
                    closest = e
                }
                // compare for greater angle
                else if getAngle(start.end, start.start, closest.end) < getAngle(start.end, start.start, e.end)
                {
                    let ang1 = getAngle(start.end, start.start, closest.end)
                    let ang2 = getAngle(start.end, start.start, e.end)
                    closest = e
                }
            }
        }
        return closest
    }
    
    /// look through edges and return vertex in the hit distance if found
    func vertexHitTest(point:CGPoint) -> CGPoint?
    {
        var np:CGPoint?
        var minDist = CGFloat.max
        for (k,v) in adjacency
        {
            var d = CGPointGetDistance(k, point)
            if d < minDist
            {
                np = k
                minDist = d
            }
        }
        
        return (minDist < kHitTestRadius*1.5) ? np : nil
    }
    
    /// returns the edge and nearest hitpoint to point given
    func edgeHitTest(point:CGPoint) -> (Edge, CGPoint)?
    {
        var r:(Edge,CGPoint)? = nil
        for edge in self.edges
        {
            if let np = edge.hitTest(point) {
                r = (edge, np)
            }
        }

        return r
    }
    
    /// returns a list of edges if any of then intersect the given shape
    /// DO not call with an unclosed path
    func shapeHitTest(path: UIBezierPath) -> [Edge]?
    {
        var list = [Edge]()
        for (k,v) in adjacency
        {
            if CGPathContainsPoint(path.CGPath, nil, k, true)
            {
                for e in v
                {
                    if e.path != path { list.append(e) }
                }
            }
        }
        return (list.count > 0) ? list : nil
    }
    
    /// check bounds for drawing
    func checkInBounds(point: CGPoint) -> Bool
    {
        return self.drawingBounds.contains(point)
    }
    
    
    /// alter
    func alterEdgePoints(fromPoint:CGPoint, toPoint:CGPoint, constrainHeight:Bool = false)
    {
        //TODO: this should allow modifying all edges
        for (k,v) in adjacency
        {
            
        }
    }

    
}

