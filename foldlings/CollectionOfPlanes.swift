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
    
    
    
    func addPlane(plane:Plane)
    {
        if adjacency[plane] != nil {
            adjacency[plane]!.append(plane)
        } else {
            adjacency[plane] = [plane]
        }
    }
    
    //TODO: needs to work
    func removePlane(plane:Plane)
    {
        planes = planes.filter({ $0 != plane })
    }

    

}

