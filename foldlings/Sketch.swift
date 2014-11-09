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
    
    
    //TODO:store lines
    //  edges(Fold?) in ordered array by height
    //  vertices in ordered array
    //  dict of vertices->edges(Fold)
    //  create bounding box per line.  ordered array of rects indexed same as line array

    
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
        
        drivingEdge = Edge(start: p1, end: p1, path: path, kind: Edge.Kind.Fold)
        drivingEdge.fold = .Valley
        edges.append(drivingEdge)
        name = named
        
        super.init()
        // make border into cuts
        makeBorderEdges(screenWidth, height: screenHeight)

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
        if var a = adjacency[start] {
            a.append(e)
        } else {
            adjacency[start] = [e]
        }
        if var a = adjacency[end] {
            a.append(e)
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
        
        //skip 0th fold
        initPlanes()
        
        return e
    }
    
    //TODO: needs to work
    func removeEdge(edge:Edge)
    {
        edges = edges.filter({ $0 != edge })
        initPlanes()
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
    
    func makeBorderEdges(width: CGFloat, height: CGFloat){
        
        //border paths
        var path1 = UIBezierPath()
        var path2 = UIBezierPath()
        var path3 = UIBezierPath()
        var path4 = UIBezierPath()

        // border points
        let b1 = CGPointMake(0, 0)
        let b2 = CGPointMake(width, 0)
        let b3 = CGPointMake(width, height)
        let b4 = CGPointMake(0, height)
        
        //border edges
        path1.moveToPoint(b1)
        path1.addLineToPoint(b2)
        bEdge1 = Edge(start: b1, end: b2, path: path1, kind: Edge.Kind.Cut)
        edges.append(bEdge1)
        
        path2.moveToPoint(b2)
        path2.addLineToPoint(b3)
        bEdge2 = Edge(start: b2, end: b3, path: path2, kind: Edge.Kind.Cut)
        edges.append(bEdge2)
        
        path3.moveToPoint(b3)
        path3.addLineToPoint(b4)
        bEdge3 = Edge(start: b3, end: b4, path: path3, kind: Edge.Kind.Cut)
        edges.append(bEdge3)
        
        path4.moveToPoint(b4)
        path4.addLineToPoint(b1)
        bEdge4 = Edge(start: b4, end: b1, path: path4, kind: Edge.Kind.Cut)
        edges.append(bEdge4)
    }
    
    func getPlanes() -> [Plane]
    {
        var planes : [Plane] = []
        var p = Plane()
        visited = []
 
        for (i, e) in enumerate(edges)//traverse edges
        {
            if !haveVisited(e) && i > 4 //skip over edges alreay visited and first 5 edges (temporary)
            {
                //println("edges: \(visited)")
                visited.append(e)
                let closest = getClosest(e, start: e)// get closest adjacent edge
                //visited.append(closest)
//                if i == 6{
//                    println("edges: \(visited)")
//                    println("edge: \(e)")
//                    println(haveVisited(e))
//                }
                p = makePlane(closest, first: e, plane: p)
                //save plane in planes
                planes.append(p)
                
            }
        }
        //println(planes.count)
        return planes
    }
    
    //checks if edge has already been visited
    func haveVisited(edge: Edge)-> Bool
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
        var adj = adjacency[current.end]!// find adjacent edges
        println("\(adj.count)")
        for (i, e) in enumerate(adj)
        {
            if e != current && e != start
            {
                if i == 0 // make the first edge the closest
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
}

