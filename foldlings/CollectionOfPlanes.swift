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

class CollectionOfPlanes: Printable, Hashable {
    var description: String {
        return ",".join(planes.map({ "\($0)" }))
    }
    
    var hashValue: Int { get {
        return description.hashValue
        }
    }
    
    var planes:[Plane] = []
    var adjacency : [Plane : [Plane]] = [Plane : [Plane]]()
    
    var count:Int { get { return planes.count } }
    
    
    /// adds a plane into the graph
    /// uses the fold type edges to determine adjacency
    func addPlane(plane:Plane)
    {
        if !contains(planes, plane) {
            planes.append(plane)
        }
        
        if adjacency[plane] == nil {
            adjacency[plane] = []
        }
        
        for edge in plane.edges {
            if edge.kind == .Fold {
                for p in planes {
                    for e in p.edges! {
                        if edge == e {
                            adjacency[plane]!.append(p)
                        }
                    }
                }
            }
        }
    }
    
    func removePlane(plane:Plane)
    {
        planes = planes.filter({ $0 != plane })
        
        if adjacency[plane] != nil {
            adjacency[plane] = nil
        }
        for (k,v) in adjacency {
            adjacency[k]!.filter({ $0 != plane })
        }
    }
    
    func validateGraph() -> Bool
    {
        return true
    }
    

}

