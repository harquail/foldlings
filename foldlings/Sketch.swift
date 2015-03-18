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
    
    var features:[FoldFeature]? = [] //listOfCurrentFeatures
    var currentFeature:FoldFeature? //feature currently being drawn
    var masterFeature:FoldFeature?
    
    //the folds that define a sketch
    //for now, cuts are in this array to
    let edgeAdjacencylockQueue = dispatch_queue_create("com.Foldlings.LockEdgeAdjacencyQueue", nil)
    var edges : [Edge] = []
    var tabs  : [Edge] = [] // tabbytabbbss
    var visited : [Edge]!
    var adjacency : [CGPoint : [Edge]] = [CGPoint : [Edge]]()  // a doubly connected edge list wooot! by start vertex
    var drivingEdge: Edge!
    var bEdge1: Edge!  //top
    var bEdge2: Edge!  //right
    var bEdge2point5: Edge!  //right2
    var bEdge3: Edge!  //bottom
    var bEdge4: Edge!  //left
    var bEdge4point5: Edge!  //left2
    var borderEdges: [Edge] = []
    
    var index:Int
    var name:String
    var origin:Origin
    var planes:CollectionOfPlanes = CollectionOfPlanes()
    
    // this sets templating mode, we could refactor and do a subclass for templating mode but might be quicker to do this
    var templateMode = !NSUserDefaults.standardUserDefaults().boolForKey("templateMode")
    
    var drawingBounds: CGRect = CGRectMake(0, 0, 0, 0)
    enum Origin: String {
        case UserCreated = "User"
        case Sample = "Sample"
    }
    
    
    init(at:Int, named:String, userOriginated:Bool = true)
    {
        
        index = at
        name = named
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        origin = userOriginated ? .UserCreated : .Sample
        let scaleFactor = CGFloat(0.9)
        super.init()
        
        //insert master fold and make borders into cuts
        if(templateMode){
            
            makeBorderEdgesUsingFeatures(screenWidth*scaleFactor, height: screenHeight*scaleFactor)
        }
        else{
            makeBorderEdges(screenWidth*scaleFactor, height: screenHeight*scaleFactor)
                
        }
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
            
            
            if self.adjacency[start] != nil{
                self.adjacency[start]!.append(edge)
            } else {
                self.adjacency[start] = [edge]
            }
            if self.adjacency[end] != nil {
                self.adjacency[end]!.append(twin)
            } else {
                self.adjacency[end] = [twin]
            }
            
            // this fixes double planes
            // may be overkill in terms of number of planes cleared
            //
            for e in self.adjacency[start]! {
                e.dirty = true
                if e.plane != nil { self.planes.removePlane(e.plane!) }
            }
            for e in self.adjacency[end]! {
                e.dirty = true
                if e.plane != nil { self.planes.removePlane(e.plane!) }
            }
            
        }
        
        if kind == .Tab
        {
            if !contains(tabs, edge) { tabs.append(edge) }
        }
        
        
        return edge
    }
    
    ///removes and edge from edges and adjacency
    func removeEdge(edge:Edge)
    {
        dispatch_sync(edgeAdjacencylockQueue) {
            if let plane = edge.plane { self.planes.removePlane(plane) }
            if let plane = edge.twin.plane { self.planes.removePlane(plane) }
            var twin = edge.twin
            self.edges.remove(edge)
            self.edges.remove(twin)
            self.tabs.remove(edge)
            if self.adjacency[edge.start] != nil {
                self.adjacency[edge.start] = self.adjacency[edge.start]!.filter({ $0 != edge })
                if self.adjacency[edge.start]!.count == 0 { self.adjacency[edge.start] = nil }
            }
            if self.adjacency[twin.start] != nil {
                self.adjacency[twin.start] = self.adjacency[twin.start]!.filter({ $0 != twin })
                if self.adjacency[twin.start]!.count == 0 { self.adjacency[twin.start] = nil }
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
        masterFeature = FoldFeature(start: b1, kind: .MasterCard)
        masterFeature!.endPoint = b3
        features?.append(masterFeature!)
        
        for edge in masterFeature!.getEdges(){
            addEdge(edge)
        }
        drivingEdge = masterFeature!.horizontalFolds.first
        
    }
    
    /// makes border edges
    /// NOTE: width and height here are actually aboslute positions for the lines rather than the width/height
    func makeBorderEdges(width: CGFloat, height: CGFloat){
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width;
        let screenHeight = screenSize.height;
        
        
        let halfH = height/2.0
        
        let downabit:CGFloat = -50.0
        let midLeft = CGPointMake(screenWidth-width, halfH)
        let midRight = CGPointMake(width, halfH)
        
        var path = UIBezierPath()
        path.moveToPoint(midLeft)
        path.addLineToPoint(midRight)
        // this style stuff below is ugly but whatever
        path.setLineDash([10,5], count: 2, phase:0)
        path.lineWidth = kLineWidth
        
        drivingEdge = addEdge(midLeft, end: midRight, path: path, kind: Edge.Kind.Fold, isMaster:true)
        drivingEdge.fold = .Valley
        
        //border paths
        var path1 = UIBezierPath()
        var path2 = UIBezierPath()
        var path2point5 = UIBezierPath()
        var path3 = UIBezierPath()
        var path4 = UIBezierPath()
        var path4point5 = UIBezierPath()
        
        
        
        // border points
        let b1 = CGPointMake(screenWidth-width, screenHeight-height + downabit) //topleft
        let b2 = CGPointMake(width, screenHeight-height + downabit)  //topright
        //between b2 and b3 should be a midRight
        let b3 = CGPointMake(width, height + downabit)   //bottomright
        let b4 = CGPointMake(screenWidth-width, height + downabit)  //bottomleft
        
        //border edges
        path1.moveToPoint(b1)
        path1.addLineToPoint(b2)
        bEdge1 = addEdge(b1, end: b2, path: path1, kind: Edge.Kind.Cut, isMaster:true)//top
        
        path2.moveToPoint(b2)
        path2.addLineToPoint(midRight)
        bEdge2 = addEdge(b2, end: midRight, path: path2, kind: Edge.Kind.Cut, isMaster:true)//right
        
        path2point5.moveToPoint(midRight)
        path2point5.addLineToPoint(b3)
        bEdge2point5 = addEdge(midRight, end: b3, path: path2point5, kind: Edge.Kind.Cut, isMaster:true)//right2
        
        path3.moveToPoint(b3)
        path3.addLineToPoint(b4)
        bEdge3 = addEdge(b3, end: b4, path: path3, kind: Edge.Kind.Cut, isMaster:true)//bottom
        
        path4.moveToPoint(b1)
        path4.addLineToPoint(midLeft)
        bEdge4 = addEdge(b1, end: midLeft, path: path4, kind: Edge.Kind.Cut, isMaster:true)//left
        
        path4point5.moveToPoint(midLeft)
        path4point5.addLineToPoint(b4)
        bEdge4point5 = addEdge(midLeft, end: b4, path: path4point5, kind: Edge.Kind.Cut, isMaster:true)//left2
        
        borderEdges = [bEdge1, bEdge1.twin, bEdge2, bEdge2.twin, bEdge2point5, bEdge2point5.twin,            bEdge3, bEdge3.twin, bEdge4, bEdge4.twin, bEdge4point5, bEdge4point5.twin]
        // note width here has to subtract the border
        drawingBounds =  CGRectMake(b1.x, b1.y, width - ((screenWidth - width)), height - (screenHeight - height))
    }
    
    /// does a traversal of all the edges to find all the planes
    func getPlanes()
    {
        dispatch_sync(edgeAdjacencylockQueue) {
            
            self.visited = []
            
            for (i, start) in enumerate(self.edges)//traverse edges
            {
                if start.dirty {
                    
                    var p : [Edge] = []
                    
                    var isContained = contains(self.visited, start)
                    
                    if !isContained// skipped over already visited edges
                    {
                        p.append(start)
                        
                        self.visited.append(start)
                        
                        var closest = self.getClosest(start)// get closest adjacent edge
                        
                        // check if twin has not been crossed and not in plane
                        while !CGPointEqualToPoint(closest.end, start.start) && !closest.crossed
                        {
                            p.append(closest)
                            self.visited.append(closest)
                            closest = self.getClosest(closest)
                        }
                        
                        if CGPointEqualToPoint(closest.end, start.start) && !CGPointEqualToPoint(start.start, start.end){
                            p.append(closest)
                            self.visited.append(closest)
                        }
                        
                        if !closest.crossed || CGPointEqualToPoint(start.start, start.end) {// if you didn't cross twin, make it a plane
                            var plane = Plane(edges: p)
                            self.planes.addPlane(plane, sketch: self)
                        }
                        closest.crossed = false
                    }
                }
            }
        }
    }
    
    
    //get closest adjancent edge
    // get angle between lines
    // *not* concurrency safe, only use if you have a lock
    func getClosest(current: Edge) -> Edge
    {
        var closest: Edge!
        
        if var currentAdjecency = self.adjacency[current.end] {
            if currentAdjecency.count < 2 {
                closest = currentAdjecency[0]
                closest.crossed = true
            } else {
                for next in currentAdjecency
                {
                    if current.twin === next || contains(self.visited, next){//if the current closest is twin or it's already visited, the
                        continue
                    }
                    
                    if closest == nil  // make the first edge the closest
                    {
                        closest = next
                        continue
                    }
                    
                    // compare for greater angle for closest and next
                    var curr_ang = getAngle(current, closest)
                    var next_ang = getAngle(current, next)
                    
                    if next_ang == curr_ang {
                        let curr_centroid = findCentroid(closest.path)
                        let next_centroid = findCentroid(next.path)
                        curr_ang = getAngle(current, Edge(start: closest.start, end: curr_centroid, path: closest.path))
                        next_ang = getAngle(current, Edge(start: closest.start, end: next_centroid, path: closest.path))
                        //                        println("curr_ang: \(curr_ang), next_ang: \(next_ang)")
                    }
                    
                    
                    if  next_ang < curr_ang  { // if the current angle is bigger than the next edge
                        closest = next
                    }
                }
                
                // if nil means only twin edge so return twin
                if closest == nil {
                    closest = current.twin
                    closest.crossed = true
                }
                
            }
        }
        
        return closest
    }
    
    
    /// build tabs as necessary from te planes
    func buildTabs() -> Bool {
        var retB = false
        
        for tab in tabs {
            var bottomFold:Edge? = nil
            
            let plane1 = tab.plane
            let plane2 = tab.twin.plane
            var plane:Plane?
            
            for p in [plane1, plane2] {
                if p != nil {
                    if !p!.hasEdge(bEdge1) {
                        plane = p
                        bottomFold = p!.bottomFold(tab: false)
                    }
                }
            }
            if bottomFold != nil {
                
                if bottomFold!.start.y == drivingEdge.start.y &&
                    (bottomFold!.start != drivingEdge.start) &&
                    (bottomFold!.end != drivingEdge.start) &&
                    (bottomFold!.start != drivingEdge.end) &&
                    (bottomFold!.end != drivingEdge.end)
                {
                    println("removing fold in middle of planes")
                    removeEdge(bottomFold!)
                    retB = true
                } else {
                    let distance = abs(drivingEdge.start.y  - bottomFold!.start.y)
                    let newfoldstart = CGPointMake(tab.start.x, tab.start.y-distance)
                    let newfoldend = CGPointMake(tab.end.x, tab.end.y-distance)
                    //new fold
                    let newfold = UIBezierPath()
                    newfold.moveToPoint(newfoldstart)
                    newfold.addLineToPoint(newfoldend)
                    var newFoldEdge = addEdge(newfoldstart, end: newfoldend, path: newfold, kind: Edge.Kind.Fold)
                    //left edge
                    let newleft = UIBezierPath()
                    newleft.moveToPoint(tab.start)
                    newleft.addLineToPoint(newfoldstart)
                    var newLeftEdge = addEdge(tab.start, end: newfoldstart, path:newleft, kind:Edge.Kind.Cut)
                    //right edge
                    let newright = UIBezierPath()
                    newright.moveToPoint(tab.end)
                    newright.addLineToPoint(newfoldend)
                    var newRightEdge = addEdge(tab.end, end: newfoldend, path:newright, kind:Edge.Kind.Cut)
                    
                    // move tab from tabs to edges so we don't redraw this again
                    tab.kind = .Fold
                    tab.twin.kind = .Fold
                    tabs.remove(tab)
                    tabs.remove(tab.twin)
                    retB = true
                }
            }
            
        }
        return retB
        
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
                if !borderEdges.contains(edge) && !borderEdges.contains(edge.twin){
                    r = (edge, np)
                } else {
                    r = (nil, point)
                }
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
    
    
    
    ///  sets up a grid and returns nearest point in grid
    func nearestGridPoint(point: CGPoint) -> CGPoint
    {
        
        let width = CGPointGetDistance(bEdge1.start, bEdge1.end)
        let height = CGPointGetDistance(bEdge2.start, bEdge2.end)
        let gs = CGPointGetDistance(bEdge1.start, bEdge1.end) / 25
        let gsh = gs / 2.0
        var x:CGFloat = 0.0
        var y:CGFloat = 0.0
        
        for var xi:CGFloat = 0.0; xi < width; xi=xi+gs
        {
            for var yi:CGFloat = 0.0; yi < height; yi=yi+gs
            {
                if point.x < xi + gsh && point.x > xi - gsh {
                    x = xi
                }
                if point.y < yi + gsh && point.y > yi - gsh {
                    y = yi
                }
            }
        }
        
        
        let newpoint = CGPointMake(x, y)
        return newpoint
        
    }
    
    
    
    func isTopEdge(edge:Edge) -> Bool
    {
        if(templateMode){
            if let masterF = masterFeature{
                return masterF.startPoint!.y == edge.start.y
            }
            return false
        }
        else{
            let b = edge == bEdge1 || edge == bEdge1.twin
            return b
        }
        
    }
    
    func isBottomEdge(edge:Edge) -> Bool
    {
        if(templateMode){
            if let masterF = masterFeature{
                if(masterF.endPoint != nil){
                    return masterF.endPoint!.y == edge.start.y
                }
            }
            return false
        }
        else{
            let b = edge == bEdge3 || edge == bEdge3.twin
            return b
        }
        
    }
    
}