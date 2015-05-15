//
//  CollectionOfPlanes.swift
//  foldlings
//
//

import Foundation
import CoreGraphics
import UIKit

func == (lhs: CollectionOfPlanes, rhs: CollectionOfPlanes) -> Bool {
    return lhs.hashValue == rhs.hashValue
}

/// set this to false to turn off plane edge coloring
var kOverrideColor = false

class CollectionOfPlanes: Printable, Hashable {
    var description: String {
        return ",".join(planes.map({ "\($0)" }))
    }
    
    var hashValue: Int { get {
        return description.hashValue
        }
    }
    
    let planeAdjacencylockQueue = dispatch_queue_create("com.Foldlings.LockPlaneAdjacencyQueue", nil)
    
    var planes:[Plane] = []
    var adjacency : [Plane : [Plane]] = [Plane : [Plane]]()
    
    var count:Int { get { return planes.count } }
    
    // mark the topmost plane of sketch
    //    var topPlane:Plane? = nil
    //    // mark the bottommost plane of sketch
    //    var bottomPlane:Plane? = nil
    //
    var masterTop:Plane!
    var masterBottom:Plane!
    
    /// adds a plane into the graph
    /// uses the fold type edges to determine adjacency
    func addPlane(plane:Plane, sketch:Sketch, folds: Int)
    {
        // dispatch_sync(planeAdjacencylockQueue) {
        if !contains(self.planes, plane)
        {
            if isCounterClockwise(plane.path)
            {
                let color = plane.color
                self.planes.append(plane)
                //TODO: insert sorted by top edge of the plane
                plane.feature.featurePlanes.append(plane)
                //TODO: switch for types of plane based on foldcount, if statements might be better here
                switch (folds)
                {
                    
                case 0:
                    // mark plane as hole
                    plane.kind = .Hole
                    break
                    
                case 1:
                    // mark plane as flap
                    plane.kind = .Flap
                    // find fold (either bottom or top)
                    //TODO: check top edge, check bottom edge, check which one is a fold
                    let bottom = plane.bottomEdge
                    if bottom.kind == .Fold{
                        // mark as a top plane
                    }
                    let top = plane.topEdge
                    if top.kind == .Fold{
                        // mark as a bottom plane
                    }
                    
                    break
                    
                case 2:
                    
                    // mark plane as plane
                    plane.kind = .Plane
                    
                    // check if master
                    if plane.topEdge.isMaster{
                        let top = plane.topEdge
                        //if topEdge isn't a fold then it is masterTop
                        if top.kind != .Fold{
                            plane.masterTop = true
                            masterTop = plane
                        }
                            // else, it is masterBottom
                        else{
                            plane.masterBottom = true
                            masterBottom = plane
                        }
                    }
                    
                    // for regular planes
                    for edge in plane.edges
                    {
                        edge.dirty = false //mark it as clean
                        
                        // mark the topmost plane of sketch- the top plane of mastercard
                        //TODO: Change this to be based on mastercard and set this elsewhere
                        /*********************************/
                        //                        if sketch.isTopEdge(edge)
                        //                        {
                        //                            self.topPlane = plane
                        //
                        //                        }
                        //
                        //                            // mark the bottommost plane of sketch- the bottom plane of mastercard
                        //                        else if sketch.isBottomEdge(edge)
                        //                        {
                        //                            self.bottomPlane = plane
                        //                        }
                        /********************************/
                        
                        /// this could be called for flaps as well
                        // set the edges plane
                        edge.plane = plane
                        //set the color
                        if kOverrideColor { edge.colorOverride = getRandomColor(0.8) }
                        // if the path is a plane and not a hole
                        // TODO: maybe set plane parent here, so it's based on twin of top fold
                        if edge.kind == .Fold
                        {
                            
                            // if the twin has a plane, setup adjacency
                            if let p = edge.twin.plane
                            {
                                if self.adjacency[plane] == nil
                                {
                                    // println("did encounter an nil plane adjacency")
                                    //println(plane)
                                    self.adjacency[plane] = [p]
                                }
                                var adjacencylist = self.adjacency[plane]!
                                // order the adjacency list by planes' topfolds
                                adjacencylist.insertIntoOrdered(p, ordering: { $0.topEdge.start.y < $1.topEdge.start.y })
                                
                                if self.adjacency[p] == nil
                                {
                                    self.adjacency[p] = [plane]
                                }
                                    
                                    // insert plane into p's ordered (plane.twin) adjacency
                                    // p should have an adjacency if it has been in made into a plane
                                else if !self.adjacency[p]!.contains(plane)
                                {
                                    self.adjacency[p]!.insertIntoOrdered(plane, ordering: { $0.topEdge.start.y < $1.topEdge.start.y })
                                }
                            }
                        }
                        
                    }
                    
                default:
                    break
                }
                
            }
        }
    }
    
    
    
    /// remove a plane and set dirty on edges
    func removePlane(plane:Plane)
    {
        // dispatch_sync(planeAdjacencylockQueue) {
        
        for edge in plane.edges {
            edge.dirty = true
            edge.plane = nil
        }
        println("masterTop: \(masterTop)")
        println("masterbottom: \(masterBottom)")
        
        if plane.masterTop { self.masterTop = nil }
        if plane.masterBottom { self.masterBottom = nil }
        
        for p in self.planes {
            if self.adjacency[p] != nil {
                self.adjacency[p]!.remove(plane)
            }
        }
        
        self.adjacency[plane] = nil
        self.planes.remove(plane)
        
        // }
    }
    
    //just re-init it all
    func removeAll()
    {
        // dispatch_sync(planeAdjacencylockQueue) {
        self.planes =  []
        self.adjacency = [Plane : [Plane]]()
        //}
    }
    
    // #TODO lol
    func validateGraph() -> Bool
    {
        
        return true
    }
    
    
    
}

