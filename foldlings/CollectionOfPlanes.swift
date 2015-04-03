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
    var topPlane:Plane? = nil
    var bottomPlane:Plane? = nil
    
    
    /// adds a plane into the graph
    /// uses the fold type edges to determine adjacency
    func addPlane(plane:Plane, sketch:Sketch)
    {
        dispatch_sync(planeAdjacencylockQueue) {
            if isCounterClockwise(plane.path) {
                let color = plane.color
                if !contains(self.planes, plane) {
                    self.planes.append(plane)
                }
                
                if self.adjacency[plane] == nil {
                    self.adjacency[plane] = []
                }
                
                for edge in plane.edges {
                    edge.dirty = false //mark it as clean
                    if sketch.isTopEdge(edge) {
                        self.topPlane = plane
                    }
                    else if sketch.isBottomEdge(edge) {
                        self.bottomPlane = plane
                    }
                    edge.plane = plane
                    if kOverrideColor { edge.colorOverride = color }
                    if edge.kind == .Fold || edge.kind == .Tab {
                        plane.kind = .Plane
                        
                        if let p = edge.twin.plane {
                            let index = self.adjacency[plane]!.insertionIndexOf(p,  { $0.topFold()!.start.y < $1.topFold()!.start.y } )
                            self.adjacency[plane]!.insert(p, atIndex: index)
                            if self.adjacency[p] == nil {
                                self.adjacency[p] = [plane]
                            }
                            else if !self.adjacency[p]!.contains(plane) {
                                let index = self.adjacency[p]!.insertionIndexOf(plane,  { $0.topFold()!.start.y < $1.topFold()!.start.y } )
                                self.adjacency[p]!.insert(plane, atIndex: index)
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    
    /// remove a plane and set dirty on edges
    func removePlane(plane:Plane)
    {
        dispatch_sync(planeAdjacencylockQueue) {
            
            for edge in plane.edges {
                edge.dirty = true
                edge.plane = nil
            }
            
            if self.topPlane == plane { self.topPlane = nil }
            if self.bottomPlane == plane { self.bottomPlane = nil }
            
            for p in self.planes {
                if self.adjacency[p] != nil {
                    self.adjacency[p]!.remove(plane)
                }
            }
            
            self.adjacency[plane] = nil
            
            
            self.planes.remove(plane)

        }
    }
    
    //just re-init it all
    func removeAll()
    {
        dispatch_sync(planeAdjacencylockQueue) {
            self.planes =  []
            self.adjacency = [Plane : [Plane]]()
        }
    }
    
    // #TODO lol
    func validateGraph() -> Bool
    {
        
        return true
    }
    


}

