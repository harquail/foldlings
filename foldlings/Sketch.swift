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
        var features:[FoldFeature] = [] //listOfCurrentFeatures
        var currentFeature:FoldFeature? //feature currently being drawn
        var draggedEdge:Edge? //edge being dragged
        var masterFeature:MasterCard? //the master card feature for the sketch
        
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
        var planelist : [Plane] = []
        
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
        func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind, isMaster:Bool = false, feature: FoldFeature?) -> Edge {
            return addEdge(Edge(start: start, end: end, path: path, kind: kind, isMaster:isMaster, feature: feature))
        }
        
        /// adds an edge to the adjacency graph
        func addEdge(edge: Edge) -> Edge
        {
            var path = edge.path
            var start = edge.start
            var end = edge.end
            var kind = edge.kind
            var isMaster = edge.isMaster
            var feature = edge.feature
            
            var revpath = path.bezierPathByReversingPath() // need to reverse the path for better drawing
            var twin : Edge
            
            // all feature edges belong to itself
            twin = Edge(start: end, end: start, path: revpath, kind: kind, isMaster:isMaster, feature: feature)
            
            edge.twin = twin
            twin.twin = edge
            
            // dispatch_sync(edgeAdjacencylockQueue) {
            if !contains(self.edges, edge) {
                self.edges.append(edge)
            }
            if !contains(self.edges, twin) {
                self.edges.append(twin)
            }
            
            //add twin and edge to each other's adjacency lists
            if !contains(twin.adjacency, edge) {
                twin.adjacency.insertIntoOrdered(edge, ordering: {getAngle(twin, $0) < getAngle(twin, $1)})
            }
            if !contains(edge.adjacency, twin) {
                edge.adjacency.insertIntoOrdered(twin, ordering: {getAngle(edge, $0) < getAngle(edge, $1)})
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
            
            
            //}
            
            
            return edge
        }
        
        
        ///removes and edge from edges and both adjacency lists
        func removeEdge(edge:Edge)
        {
            // dispatch_sync(edgeAdjacencylockQueue) {
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
            //}
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
                if !contains(edge.adjacency, e){
                    edge.adjacency.insertIntoOrdered(e, ordering:  {getAngle(edge, $0) < getAngle(edge, $1)})
                }
                // add to the adj of these e's twins
                if !contains(e.twin.adjacency, edge.twin){
                    e.twin.adjacency.insertIntoOrdered(edge.twin, ordering: {getAngle(e.twin, $0) < getAngle(e.twin, $1)})
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
            features.append(masterFeature!)
            
            for edge in masterFeature!.getEdges(){
                addEdge(edge)
            }
            
        }
        
        
        /// does a traversal of all the edges to find all the planes
        func getPlanes()
        {
            // dispatch_sync(edgeAdjacencylockQueue) {
            println("\ngetPlanes\n")
            println("\nedges: \(self.edges)")
            self.visited = []
            planelist = []
            for (i, start) in enumerate(self.edges)//traverse edges
            {
                //keep a fold count by plane to catch flaps and holes
                var foldcount = 0
                var folds:[Edge] = []
                
                if start.dirty {
                    var p : [Edge] = []//plane
                    var isContained = contains(self.visited, start)
                    if !isContained// skipped over already visited edges
                    {   p.append(start)
                        if start.kind == .Fold{
                            foldcount++
                            folds.append(start)
                        }
                        // set the start as top and bottom edge
                        var topEdge : Edge = start
                        var bottomEdge : Edge = start
                        
                        self.visited.append(start)
                        var closest = self.getClosest(start)// get closest adjacent edge
                        
                        // check if twin has not been crossed and not in plane
                        while !CGPointEqualToPoint(closest.end, start.start) || contains(p, closest)
                        {   p.append(closest)
                            
                            if closest.kind == .Fold{
                                foldcount++
                                folds.append(closest)
                            }
                            //mark if this is a top edge here by comparing y's, this shold be the midpoint
                            if(makeMid(closest.start.y, closest.end.y) < makeMid(topEdge.start.y, topEdge.end.y)) {
                                topEdge = closest
                            }
                            //mark if this is a bottom edge here by comparing y's, this shold be the midpoint
                            if(makeMid(closest.start.y, closest.end.y) > makeMid(bottomEdge.start.y, bottomEdge.end.y)) {
                                bottomEdge = closest
                            }
                            
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
                            
                            //set plane's top and bottom edge
                            plane.topEdge = topEdge
                            plane.bottomEdge = bottomEdge
                            
                            //set foldcount
                            plane.foldcount = foldcount
                            
                            plane.edges.map({$0.plane = plane})
                            // add planes to planelist
                            planelist.append(plane)
                            
                            //self.planes.addPlane(plane, sketch: self, folds: foldcount)
                            //                                println("\nplane complete\n")
                            //                                println("\(plane)\n")
                        }
                        closest.crossed = false
                    }
                }
            }
            // }
            self.planes.linkPlanes(planelist)
        }
        
        
        //get closest adjancent edge
        // *not* concurrency safe, only use if you have a lock
        func getClosest(current: Edge) -> Edge
        {   //println(current)
            //            printAdjList(current.adjacency, edge: current)
            
            var closest = current.twin
            //      println("adjacency count \(current.adjacency.count)")
            //println("\n current \(current.start) , \(current.end) \n")
            // printAdjList(current.adjacency, edge: current)
            
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
        /// TODO: use t-value to get the closest plane
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
            /// dispatch_sync(edgeAdjacencylockQueue) {
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
            // }
            return (list.count > 0) ? list : nil
        }
        
        
        /// returns the feature that contains the hitpoint
        func featureHitTest(point:CGPoint) -> FoldFeature
        {
            let f:FoldFeature? = nil
            outer: for feature in self.features.reverse()
            {
                for plane in feature.featurePlanes
                {
                    if plane.path.containsPoint(point) {
                        return feature
                    }
                }
            }
            println("not in a feature")
            return f!
        }
        
        
        /// check bounds for drawing
        func checkInBounds(point: CGPoint) -> Bool
        {
            return self.drawingBounds.contains(point)
        }
        
        // use the master card feature to find top edge
        // this is used to find top plane
        // TODO: refactor so that it checks a plane instead of edges
        // might be better living in plane
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
        
        func healFoldsOccludedBy(feature:FreeForm){
            
            var fragments:[Edge] = [];
            
            for edge in edges{
                if(edge.start.y == feature.drivingFold!.start.y  && (feature.intersections.contains(edge.start)  || feature.intersections.contains(edge.end))) {
                    fragments.append(edge)
                }
            }
            
            for edge in fragments{
                feature.parent?.horizontalFolds.remove(edge)
                feature.parent?.featureEdges?.remove(edge)
            }
        }
        // replaces one fold edge with an array of fold edges
        // that span the same distance
        func replaceFold(feature: FoldFeature, fold:Edge, folds:[Edge]){
            feature.horizontalFolds.remove(fold)
            feature.featureEdges?.remove(fold)
            removeEdge(fold)
            
            for fold in folds{
                feature.horizontalFolds.insertIntoOrdered(fold, ordering: {$0.start.y < $1.start.y})
            }
            
            feature.featureEdges?.extend(folds)
            folds.map({self.addEdge($0)})
        }
        
        // add any feature edges that aren't
        // already in the sketch
        // create edges, if there are none
        func addFeatureToSketch(feature: FoldFeature, parent: FoldFeature)
        {
            // get the edges
            let fEdges = feature.getEdges()
            // set edges for feature, for freeform
            feature.featureEdges = fEdges
            for edge in fEdges
            {
                if (!self.edges.contains(edge))// and if twin has a feature
                {
                    self.addEdge(edge)
                }
            }
            self.features.append(feature)
            // set the parent/child relationship
            parent.children.append(feature)
            feature.parent = parent
            getPlanes()
        }
        
        // removes any feature edges that aren't
        // already in the sketch and the parent/child
        func removeFeatureFromSketch(feature: FoldFeature){
            //remove children features
            for child in feature.children{
                removeFeatureFromSketch(child)
            }
            // remove all edges in feature
            let fEdges = feature.getEdges()
            for edge in fEdges
            {
                if (self.edges.contains(edge))
                {
                    self.removeEdge(edge)
                }
            }
            // remove parent/child relationship
            feature.parent!.children.remove(feature)
            // remove features from sketch.features
            self.features.remove(feature)
        }
        
    }
