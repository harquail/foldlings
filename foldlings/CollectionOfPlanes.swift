



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
    
    var count:Int { get { return planes.count } }
    
    var masterTop:Plane!
    var masterBottom:Plane!
    
    //This builds a graph of planes from a list of planes
    // based on the topfold
    func linkPlanes(planelist: [Plane])
    {
        for (i, plane) in enumerate(planelist)
        {
            // set top and bottom edge and the feature
            let bottom = plane.bottomEdge
            let top = plane.topEdge
            
            plane.feature = top.feature
            let feature = plane.feature
            
            // Save the Clockwise holes and add to parent plane
            // For 3d rendering
            if plane.path.isClockwise(){

                
                if !(feature is MasterCard) && plane.foldcount == 0{
                    
                    // get parent plane and add to parent's children
                    var featureParentPlanes = plane.feature.parent!.featurePlanes
                    // add to master plane list
                    for p in plane.edges{
                        p.feature = feature
                    }
                    
                    // mark as hole
                    plane.kind = .Hole
                    
                    // get the start point of hole
                    var start = plane.edges[0].start
                    // set parent plane that satisfies the hitTest
                    for p in featureParentPlanes{
                        // test if point is in plane
                        var path = p.path
                        if path.containsPoint(start){
                            plane.parent = p
                            p.children.append(plane)
                            
                        }
                    }
                }
                
            }
                
            else
            {
                // add to master list and assign feature edges
                planes.append(plane)
                plane.edges.map({$0.feature = feature})
                
                let foldCount = plane.foldcount
                
                switch(foldCount)
                {
                    //Holes for 2D rendering
                case 0:
                    plane.kind = .Hole
                    plane.color = UIColor.whiteColor()
                    
                    //Flaps
                case 1:
                    // find fold (either bottom or top)
                    // check top edge, check bottom edge, check which one is a fold
                    
                    // one fold is a flap
                    plane.kind = .Flap
                    
                    // check if master
                    if feature is MasterCard
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
                            masterTop.children.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)} )
                        }
                        plane.color = getOrientationColorTrans(plane.orientation == .Horizontal)
                        
                    }
                        
                        // set any children/parent relationship
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
                    
                    
                    
                    //insert sorted by top edge of the plane into featurePlanes list
                    feature.featurePlanes.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)})
                    
                    // Plane
                default:
                    
                    // more than one fold is a plane
                    plane.kind = .Plane
                    // check if master
                    if feature is MasterCard
                    {
                        //if topEdge isn't a fold then it is masterTop
                        if top.kind != .Fold{
                            plane.masterTop = true
                            masterTop = plane
                            plane.color = getOrientationColorTrans(plane.orientation == .Horizontal)
                        }
                            
                            // else, it is masterBottom
                            // just set this parent specifically
                        else
                        {
                            plane.masterBottom = true
                            masterBottom = plane
                            plane.orientation = .Horizontal
                            plane.color = getOrientationColorTrans(plane.orientation == .Horizontal)
                        }
                        
                    }
                    
                    // set the parent and the children
                    // make sure that this doesn't include MasterBottom
                    if top.kind == .Fold
                    {
                        // set parent plane
                        let parent = top.twin.plane
                        
                        plane.parent = parent
                        
                        // insert into parent's children
                        parent!.children.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)} )
                        
                        
                        // if the parent is .Vertical,
                        //change the orientation of the plane to .Horizontal
                        if parent!.orientation == .Vertical {
                            plane.orientation = .Horizontal
                        }
                        plane.color = getOrientationColorTrans(plane.orientation == .Horizontal)
                        
                    }
                    
                    //insert sorted by top edge of the plane into featurePlanes list
                    feature.featurePlanes.insertIntoOrdered(plane, ordering: {makeMid($0.topEdge.start.y, $0.topEdge.end.y) < makeMid($1.topEdge.start.y, $1.topEdge.end.y)})
                    
                }
            }
            
        }
    }
    
    /// remove a plane and set dirty on edges
    func removePlane(plane:Plane)
    {
        
        for edge in plane.edges {
            edge.dirty = true
            edge.plane = nil
        }
        
        if plane.masterTop { self.masterTop = nil }
        if plane.masterBottom { self.masterBottom = nil }
        
        // remove the plane from children's parent
        if plane.children.count > 0{
            for p in plane.children {
                removePlane(p)
            }
        }
        
        if plane.parent != nil {
            plane.parent.children.remove(plane)
        }
        self.planes.remove(plane)
        
    }
    
    //just re-init it all
    func removeAll()
    {
        // dispatch_sync(planeAdjacencylockQueue) {
        self.planes =  []
        //}
    }
    
    
}

