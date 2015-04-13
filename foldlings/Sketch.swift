    //
    //  Sketch.swift
    //  foldlings
    //
    //
    //a sketch is a collection of cuts & folds
    import Foundation
    import CoreGraphics
    import UIKit
    
    class Sketch : NSObject  {
        
        
        @IBOutlet var previewButton:UIButton?
        
        // ************ Feature variables ****************
        var features:[FoldFeature]? = [] //listOfCurrentFeatures
        var currentFeature:FoldFeature? //feature currently being drawn
        var draggedEdge:Edge? //edge being dragged
        var masterFeature:FoldFeature?

        
        //the folds that define a sketch
        //for now, cuts are in this array to
        let edgeAdjacencylockQueue = dispatch_queue_create("com.Foldlings.LockEdgeAdjacencyQueue", nil)
        var edges : [Edge] = []
        var visited : [Edge]!
        var adjacency : [CGPoint : [Edge]] = [CGPoint : [Edge]]()  // a doubly connected edge list wooot! by start vertex
        var index:Int
        var name:String
        var origin:Origin
        var planes:CollectionOfPlanes = CollectionOfPlanes()
        var drawingBounds: CGRect = CGRectMake(0, 0, 0, 0)
        
        //determines whether the sketch is created by a user or is a saved sketch
        enum Origin: String {
            case UserCreated = "User"
            case Sample = "Sample"
        }
        
        
        init(at:Int, named:String, userOriginated:Bool = true)
        {
            index = at //index of where sketch is stored
            name = named // name of the sketch 
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenSize.width
            let screenHeight = screenSize.height
            origin = userOriginated ? .UserCreated : .Sample
            let scaleFactor = CGFloat(0.9)
            super.init()
            
            //insert master fold and make borders into cuts
            makeBorderEdgesUsingFeatures(screenWidth*scaleFactor, height: screenHeight*scaleFactor)
            
        }
        
        /// add an already-constructed edge
        func addEdge(edge:Edge) -> Edge {
            return addEdge(edge.start,end:edge.end, path:edge.path, kind: edge.kind)
        }
        
        /// adds an edge to the adjacency graph
        func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind, isMaster:Bool = false) -> Edge
        {
            var revpath = path.bezierPathByReversingPath() // need to reverse the path for better drawing
            var edge = Edge(start: start, end: end, path: path, kind: kind, isMaster:isMaster)
            var twin = Edge(start: end, end: start, path: revpath, kind: kind, isMaster:isMaster)
            edge.twin = twin
            twin.twin = edge
            
            dispatch_sync(edgeAdjacencylockQueue) {
                if !contains(self.edges, edge) {
                    self.edges.append(edge)
                }
                if !contains(self.edges, twin) {
                    self.edges.append(twin)
                }
                
                //add twin and edge to each other's adjacency lists
                if !contains(twin.adjacency, edge) {
                    let index = twin.adjacency.insertionIndexOf(edge, isOrderedBefore: {getAngle(twin, $0) < getAngle(twin, $1)})
                    twin.adjacency.insert(edge, atIndex: index)
                    
                }
                if !contains(edge.adjacency, twin) {
                    let index = edge.adjacency.insertionIndexOf(twin, isOrderedBefore: {getAngle(edge, $0) < getAngle(edge, $1)})
                    edge.adjacency.insert(twin, atIndex: index)
                }
                
                //create ordered adjacency list before appending
                if self.adjacency[end] != nil {
                    self.adjacency[end]!.append(twin)
                    var endlist  : [Edge] = self.adjacency[end]!
                    self.addEdgesToEdgeAdj(endlist, edge: edge)
                }
                else {
                    self.adjacency[end] = [twin]
                }
                
                if self.adjacency[start] != nil{
                    self.adjacency[start]!.append(edge)
                    var startlist  : [Edge] = self.adjacency[start]!
                    self.addEdgesToEdgeAdj(startlist, edge: twin)
                }
                else {
                    self.adjacency[start] = [edge]
                }
                if self.adjacency[end] != nil {
                    self.adjacency[end]!.append(twin)
                } else {
                    self.adjacency[end] = [twin]
                }
                

            }
            
            
            return edge
        }
        
        
        ///removes and edge from edges and both adjacency lists
        func removeEdge(edge:Edge)
        {
            dispatch_sync(edgeAdjacencylockQueue) {
                if let plane = edge.plane { self.planes.removePlane(plane) }
                if let plane = edge.twin.plane { self.planes.removePlane(plane) }
                var twin = edge.twin
                self.edges.remove(edge)
                self.edges.remove(twin)
                if self.adjacency[edge.start] != nil {
                    
                    // Remove edge from all of the adjacency lists
                    var edgelist  : [Edge] = self.adjacency[edge.start]!
                    self.removeEdgesFromEdgeAdj(edgelist, edge: edge)
                    
                    
                    //Remove edge from adjacency dictionary
                    self.adjacency[edge.start] = self.adjacency[edge.start]!.filter({ $0 != edge })
                    if self.adjacency[edge.start]!.count == 0 { self.adjacency[edge.start] = nil }
                }
                if self.adjacency[twin.start] != nil {
                    // Remove edge from all of the adjacency lists
                    var edgelist  : [Edge] = self.adjacency[twin.start]!
                    self.removeEdgesFromEdgeAdj(edgelist, edge: twin)
                    
                    //Remove edge from adjacency dictionary
                    self.adjacency[twin.start] = self.adjacency[twin.start]!.filter({ $0 != twin })
                    if self.adjacency[twin.start]!.count == 0 { self.adjacency[twin.start] = nil }
                }
            }
        }
        // prints the lists and the angles between them
        func printAdjList(edgelist: [Edge], edge: Edge){
            for e in edgelist{
                let angle = getAngle (edge, e)
                println("\(e.start), \(e.end), \(angle)")
            }
        }
        //adds edges from the list to the given edge's adjacency list and
        // adds the edge's twin to the twins of the edges in the list
        func addEdgesToEdgeAdj(edgeList:[Edge], edge: Edge){
            for e in edgeList {
                // add all of these outgoing edges to the edge's adjacency in order
                let ajindex = edge.adjacency.insertionIndexOf(e, isOrderedBefore: {getAngle(edge, $0) < getAngle(edge, $1)})
                
                if !contains(edge.adjacency, e){
                    edge.adjacency.insert(e, atIndex: ajindex)
                }
                // add to the adj of these e's twins
                let index = e.twin.adjacency.insertionIndexOf(edge.twin, isOrderedBefore: {getAngle(e.twin, $0) < getAngle(e.twin, $1)})
                
                if !contains(e.twin.adjacency, edge.twin){
                    e.twin.adjacency.insert(edge.twin, atIndex: index)
                }
                
                // this fixes double planes
                // may be overkill in terms of number of planes cleared
                //mark each of the edges in adj as dirty
                e.dirty = true
                //delete the plane that's associated with each edge
                if e.plane != nil {self.planes.removePlane(e.plane!) }
                
            }
            
        }
        //remove the edge from the given list
        func removeEdgesFromEdgeAdj(edgeList:[Edge], edge: Edge){
            for e in edgeList {
                // remove edge from the adj of these e.twin's
                if contains(e.twin.adjacency, edge){
                    e.twin.adjacency.remove(edge)
                }
            }
        }
        
        /// makes border edges
        /// NOTE: width and height here are actually aboslute positions for the lines rather than the width/height
        func makeBorderEdgesUsingFeatures(width: CGFloat, height: CGFloat){
            let screenSize: CGRect = UIScreen.mainScreen().bounds
            let screenWidth = screenSize.width;
            let screenHeight = screenSize.height;
            let downabit:CGFloat = -50.0
            
            // border points
            let b1 = CGPointMake(screenWidth-width, screenHeight-height + downabit) //topleft
            //        let b2 = CGPointMake(width, screenHeight-height + downabit)  //topright
            //between b2 and b3 should be a midRight
            let b3 = CGPointMake(width, height + downabit)   //bottomright
            masterFeature = MasterCard(start: b1)
            masterFeature!.endPoint = b3
            features?.append(masterFeature!)
            
            for edge in masterFeature!.getEdges(){
                addEdge(edge)
            }
//            drivingEdge = masterFeature!.horizontalFolds.first
            
        }
        
        
        /// does a traversal of all the edges to find all the planes
        func getPlanes()
        {
            
            dispatch_sync(edgeAdjacencylockQueue) {
               // println("\ngetPlanes\n")
                self.visited = []
                
                for (i, start) in enumerate(self.edges)//traverse edges
                {
                    if start.dirty {
                        var p : [Edge] = []//plane
                        var isContained = contains(self.visited, start)
                        if !isContained// skipped over already visited edges
                        {   p.append(start)
                            self.visited.append(start)
                            var closest = self.getClosest(start)// get closest adjacent edge
                            
                            // check if twin has not been crossed and not in plane
                            while !CGPointEqualToPoint(closest.end, start.start) || contains(p, closest)
                            {   p.append(closest)
                                self.visited.append(closest)
                                closest = self.getClosest(closest)
                            }
                            //if the edge is the last edge and the edge isn't start edge
                            if CGPointEqualToPoint(closest.end, start.start) && !CGPointEqualToPoint(start.start, start.end)
                            {   p.append(closest)
                                self.visited.append(closest)
                            }
                            //// if you didn't cross twin or if the edge is one point, make it a plane
                            if !closest.crossed || CGPointEqualToPoint(start.start, start.end)
                            {   var plane = Plane(edges: p)
                                self.planes.addPlane(plane, sketch: self)
                                //println("\nplane complete\n")
                                // println(plane)
                            }
                            closest.crossed = false
                        }
                    }
                }
            }
        }
        
        
        //get closest adjancent edge
        // *not* concurrency safe, only use if you have a lock
        func getClosest(current: Edge) -> Edge
        {
            var closest = current.twin
            
            // if adjacency has only twin and edge, return twin
            if current.adjacency.count < 2 {
                closest.crossed = true
                return closest
            }
            // return the edge that hasn't been visited and isn't twin
            for edge in current.adjacency{
                if !contains(self.visited, edge) && edge != current.twin && contains(edges, edge) {
                    return edge
                }
            }
            
            // if no other edges in adjacency, return twin
            closest.crossed = true
            return closest
        }
        
        
        /// look through edges and return vertex in the hit distance if found
        func vertexHitTest(point:CGPoint) -> CGPoint?
        {
            var np:CGPoint?
            var minDist = CGFloat.max
            for (k,v) in adjacency
            {
                var d = CGPointGetDistance(k, point)
                if d < minDist
                {
                    np = k
                    minDist = d
                }
            }
            
            return (minDist < kHitTestRadius*1.5) ? np : nil
        }
        
        /// returns the plane that contains the hitpoint
        func planeHitTest(point:CGPoint) -> Plane?
        {
            var p:Plane? = nil
            for plane in self.planes.planes
            {
                if plane.path.containsPoint(point) {
                    p = plane
                    break
                }
            }
            return p
        }
        
        /// returns the edge and nearest hitpoint to point given
        func edgeHitTest(point:CGPoint) -> (Edge?, CGPoint)?
        {
            var r:(Edge?,CGPoint)? = nil
            for edge in self.edges
            {
                if let np = edge.hitTest(point) {
                        r = (edge, np)
                }
            }
            
            return r
        }
        
        
        /// returns a list of edges if any of then intersect the given shape
        /// DO not call with an unclosed path
        func shapeHitTest(path: UIBezierPath) -> [Edge]?
        {
            var list = [Edge]()
            dispatch_sync(edgeAdjacencylockQueue) {
                for (k,v) in self.adjacency
                {
                    if CGPathContainsPoint(path.CGPath, nil, k, true)
                    {
                        for e in v
                        {
                            if e.path != path { list.append(e) }
                        }
                    }
                }
            }
            return (list.count > 0) ? list : nil
        }
        
        /// check bounds for drawing
        func checkInBounds(point: CGPoint) -> Bool
        {
            return self.drawingBounds.contains(point)
        }
        
        
        func isTopEdge(edge:Edge) -> Bool
        {
                if let masterF = masterFeature{
                    return masterF.startPoint!.y == edge.start.y
                }
                return false
           
            
        }
        
        func isBottomEdge(edge:Edge) -> Bool
        {
                if let masterF = masterFeature{
                    if(masterF.endPoint != nil){
                        return masterF.endPoint!.y == edge.start.y
                    }
                }
                return false
        }
        
        // #TODO: this is bad and shouldn't exist...
        /// updates sketch edges to match those generated from features
        func refreshFeatureEdges(){
            
            var featureEdges:[Edge] = []
            for feature in self.features!{
                featureEdges = feature.getEdges()
                
            }
            
            for edge in self.edges{
                if(!featureEdges.contains(edge)){
                    self.removeEdge(edge)
                }
                else{
                    println("EDGE: cache hit")
                }
            }
            
            //            print("FEATURES: \(self.features?.count)\n")
            for feature in self.features!{
                
                let edgesToAdd = feature.getEdges()
                for edge in edgesToAdd{
                    
                    //add edges that aren't already in the sketch
                    if(!self.edges.contains(edge)){
                        self.addEdge(edge)
                    }
                }
                
                //                print("SKETCH: \(self.edges.count)\n")
                
            }
        }

    }
