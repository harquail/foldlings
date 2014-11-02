//
//  Plane.swift
//  foldlings
//
//  Created by Marissa Allen on 11/1/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit


class Plane: Printable {
    var name = "Plane"
    var description: String {
        return "this is an array of edges"
    }
    
    var edges : [Edge] = []
    
    init(edges : [Edge]){
        self.edges = edges
    }
    
    func addToPlane(edge: Edge){
        edges.append(edge)
    }
}


