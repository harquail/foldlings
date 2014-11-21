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
var kOverrideColor = true

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
    var folds:[Edge]  = []
    
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
                            self.adjacency[plane]!.append(p)
                            self.adjacency[plane]!.sort { $0.topFold()!.start.y < $1.topFold()!.start.y }
                            
                            if self.adjacency[p] == nil {
                                self.adjacency[p] = [plane]
                            }
                            else if !self.adjacency[p]!.contains(plane) {
                                self.adjacency[p]!.append(plane)
                                self.adjacency[p]!.sort { $0.topFold()!.start.y < $1.topFold()!.start.y }
                            }
                        }
                    }
                }
            }
        }
        
    }
    
    func removePlane(plane:Plane)
    {
        dispatch_sync(planeAdjacencylockQueue) {
            self.planes = self.planes.filter({ $0 != plane })
            
            if self.adjacency[plane] != nil {
                self.adjacency[plane] = nil
            }
            for (k,v) in self.adjacency {
                self.adjacency[k]!.filter({ $0 != plane })
            }
        }
    }
    
    //just re-init it all
    func removeAll()
    {
        dispatch_sync(planeAdjacencylockQueue) {
            self.planes =  []
            self.adjacency = [Plane : [Plane]]()
            self.folds = []
        }
    }
    
    // #TODO lol
    func validateGraph() -> Bool
    {
        
        return true
    }
    
        

}

