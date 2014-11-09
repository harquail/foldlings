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
    var edges : [Edge]!
    var name = "Plane"
//    var description: String {
//        return "this is an array of edges"
//    }
    var description: String {
        for e in edges{
            println(e)
        }
        return ""
    }
    
    init()
    {
        self.edges = []
    }
    
    init(edges : [Edge])
    {
        self.edges = edges
    }
    
    func addToPlane(edge: Edge)
    {
        edges.append(edge)
    }
    
    func inPlane(edge: Edge)-> Bool
    {
        for e in edges
        {
            if e === edge
            {
                return true
            }
        }
        return false
    }
}


