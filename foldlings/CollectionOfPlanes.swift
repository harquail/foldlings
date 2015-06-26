



//
//  CollectionOfPlanes.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

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
    
   // let planeAdjacencylockQueue = dispatch_queue_create("com.Foldlings.LockPlaneAdjacencyQueue", nil)
    
    var planes:[Plane] = []
    //var adjacency : [Plane : [Plane]] = [Plane : [Plane]]()
    
    var count:Int { get { return planes.count } }
    
    var masterTop:Plane!
    var masterBottom:Plane!
    
    //This builds a graph of planes from a list of planes
    // based on the topfold
    func linkPlanes(planelist: [Plane])
    {
       // println("planelist count: \(planelist.count)")
        
        for (i, plane) in enumerate(planelist)
        {
            if isCounterClockwise(plane.path)
            {

                planes.append(plane)
                
                let bottom = plane.bottomEdge
                let top = plane.topEdge
                
                //insert sorted by top edge of the plane into featurePlanes list
                plane.feature = top.feature
                let feature = plane.feature
                //TODO: Mark edges as clean

                plane.edges.map({$0.feature = feature})

                feature.featurePlanes.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)})
                

                let foldCount = plane.foldcount
                
                switch(foldCount)
                {
                case 0:
                    // no folds is a hole
                    plane.kind = .Hole
                    // this plane's parent is it's feature parent fyi
                    plane.parent = top.twin.plane // TODO: may have to change
                    // insert into parent's children
                    plane.parent.children.append(plane)
                    
                    println(plane)
                    println(plane.parent)
                    
                case 1:
                    // find fold (either bottom or top)
                    // check top edge, check bottom edge, check which one is a fold
                    
                    // one fold is a flap
                    plane.kind = .Flap
                    
                    // check if master
                    if top.isMaster
                    {
                        //if topEdge isn't a fold then it is masterTop
                        if top.kind != .Fold{
                            plane.masterTop = true
                            masterTop = plane
                        }
                            
                            // else, it is masterBottom
                        else
                        {
                            plane.masterBottom = true
                            masterBottom = plane
                            plane.orientation = .Horizontal

                        }
                    }
                        
                    else if bottom.kind == .Fold
                    {
                        // set parent plane
                        let parent = bottom.twin.plane
                        

                        plane.parent = parent
                        // insert into parent's children
                        parent!.children.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)} )
                        
                    }
                        
                    else if top.kind == .Fold
                    {
                        

                        // set parent plane
                        let parent = top.twin.plane
                        plane.parent = parent
                        // insert into parent's children
                        parent!.children.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)} )
                    }
                default:
                    
                    // more than one fold is a plane
                    plane.kind = .Plane
                    // check if master
                    if top.isMaster
                    {
                        //if topEdge isn't a fold then it is masterTop
                        if top.kind != .Fold{
                            plane.masterTop = true
                            masterTop = plane
                            plane.color = getOrientationColor(plane.orientation == .Horizontal)
                        }
                            
                            // else, it is masterBottom
                            // just set this parent specifically
                        else
                        {
                            plane.masterBottom = true
                            masterBottom = plane
                            plane.orientation = .Horizontal
                            plane.color = getOrientationColor(plane.orientation == .Horizontal)
                        }

                    }

                        // set the parent and the children
                        // make sure that this doesn't include MasterBottom
                    else if top.kind == .Fold
                    {
                        // set parent plane
                        let parent = top.twin.plane
                        
                        plane.parent = parent
                        

//                        println("plane: \(plane.topEdge)")
//                        println("parent: \(parent!.topEdge)")
                        // insert into parent's children
                        parent!.children.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)} )
                        

                        // if the parent is .Vertical,
                        //change the orientation of the plane to .Horizontal
                        if parent!.orientation == .Vertical {
                            plane.orientation = .Horizontal
                        }
                        plane.color = getOrientationColor(plane.orientation == .Horizontal)

                    }
                    
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
        
//        println("masterTop: \(masterTop)")
//        println("masterbottom: \(masterBottom)")
        
        if plane.masterTop { self.masterTop = nil }
        if plane.masterBottom { self.masterBottom = nil }
        
        // remove the plane from children's parent 
        for p in plane.children {
            removePlane(p)
        }
        // remove remove plane from parent
        
        
//        for p in self.planes {
//            if self.adjacency[p] != nil {
//                self.adjacency[p]!.remove(plane)
//            }
//        }
//        
//        self.adjacency[plane] = nil
        if plane.parent != nil {
            plane.parent.children.remove(plane)
        }
        self.planes.remove(plane)
        
        // }
    }
    
    //just re-init it all
    func removeAll()
    {
        // dispatch_sync(planeAdjacencylockQueue) {
        self.planes =  []
        //}
    }
    
    // #TODO lol
    func validateGraph() -> Bool
    {
        
        return true
    }
    
    //returns parent of the plane
    func getParent(plane: Plane) -> Plane
    {
        return plane
    }
    
}

