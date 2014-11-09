//
//  Plane.swift
//  foldlings
//
//  Created by Marissa Allen on 11/1/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import CoreGraphics
import SceneKit
import UIKit


class Plane: Printable {
    var edges : [Edge]!
    var name = "Plane"
    var path = UIBezierPath()
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
        
        for (i,e) in enumerate(edges){
            path.appendPath(e.path)
        }
        
        self.sanitizePath()
    }
    
    func addToPlane(edge: Edge)
    {
        edges.append(edge)
        path.appendPath(edge.path)
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


