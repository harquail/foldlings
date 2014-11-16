//
//  Sketch.swift
//  foldlings
//
//

//a sketch is a collection of cuts & folds
import Foundation
import CoreGraphics
import UIKit


class Sketch : NSObject,NSCoding  {
    
    @IBOutlet var previewButton:UIButton?
    
    
    //the folds that define a sketch
    //for now, cuts are in this array too
    var edges : [Edge] = []
    var folds : [Edge] = [] // may not need to keep this but for now
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

    var name:String
    var planes:CollectionOfPlanes = CollectionOfPlanes()
    
    var drawingBounds: CGRect = CGRectMake(0, 0, 0, 0)


    init(named:String)
    {
        
        name = named
        //insert master fold and make borders into cuts
        let screenSize: CGRect = UIScreen.mainScreen().bounds
        let screenWidth = screenSize.width
        let screenHeight = screenSize.height
        
        let scaleFactor = CGFloat(0.9)
        super.init()
        makeBorderEdges(screenWidth*scaleFactor, height: screenHeight*scaleFactor)
        
    }
    
    func encodeWithCoder(aCoder: NSCoder) {
        
        
        aCoder.encodeObject(edges, forKey: "edges")
        aCoder.encodeObject(folds, forKey: "folds")
        
        //convert CGPoints to NSValues
        var adjsWithValues :[NSValue:Edge] = Dictionary<NSValue,Edge>()
        
        for (point,edge) in adjacency{
            //TODO: wooppsssyyy
            //            adjsWithValues[NSValue(CGPoint:point)]=edge
        }
        
        aCoder.encodeObject(adjsWithValues, forKey: "adj")
        aCoder.encodeObject(drivingEdge,forKey:"driving")
        aCoder.encodeObject(bEdge1,forKey:"bEdge1")
        aCoder.encodeObject(bEdge2,forKey:"bEdge2")
        aCoder.encodeObject(bEdge3,forKey:"bEdge3")
        aCoder.encodeObject(bEdge4,forKey:"bEdge4")
        aCoder.encodeObject(name, forKey:"name")
        
    }
    
    required init(coder aDecoder: NSCoder) {
        drawingBounds = CGRectMake(0, 0, 0, 0)
        self.edges = aDecoder.decodeObjectForKey("edges") as Array
        self.folds = aDecoder.decodeObjectForKey("folds") as Array
        
        //convert NSValues to CGPoints
        var adjsWithValues :[NSValue:Edge] = aDecoder.decodeObjectForKey("adj") as Dictionary<NSValue,Edge>
        for (p,e) in adjsWithValues{
            //TODO: woopssyy
            //            adjacency[p.CGPointValue()]=e
        }
        
        drivingEdge = aDecoder.decodeObjectForKey("driving") as Edge
        bEdge1 = aDecoder.decodeObjectForKey("bEdge1") as Edge
        bEdge2 = aDecoder.decodeObjectForKey("bEdge2") as Edge
        bEdge3 = aDecoder.decodeObjectForKey("bEdge3") as Edge
        bEdge4 = aDecoder.decodeObjectForKey("bEdge4") as Edge
        name = aDecoder.decodeObjectForKey("name") as String
        
    }
    
    
    /// add an already-constructed edge
    func addEdge(edge:Edge) -> Edge {
        
        return addEdge(edge.start,end:edge.end, path:edge.path, kind: edge.kind)
    
    }

    
    func addEdge(start:CGPoint,end:CGPoint, path:UIBezierPath, kind: Edge.Kind, isMaster:Bool = false) -> Edge
    {
        var revpath = path.bezierPathByReversingPath() // need to reverse the path for better drawing
        var edge = Edge(start: start, end: end, path: path, kind: kind, isMaster:isMaster)
        var twin = Edge(start: end, end: start, path: revpath, kind: kind, isMaster:isMaster)
        edge.twin = twin
        twin.twin = edge
        
        if !contains(edges, edge) {
            edges.append(edge)
        }
        if !contains(edges, twin) {
            edges.append(twin)
        }

        
        if adjacency[start] != nil{
            adjacency[start]!.append(edge)
        } else {
            adjacency[start] = [edge]
        }
        if adjacency[end] != nil {
            adjacency[end]!.append(twin)
        } else {
            adjacency[end] = [twin]
        }
        
        // keep folds in ascending order by start position y height from bottom up
        // note y starts at 0 on top of screen
        // inefficient? who cares
        if kind == .Fold
        {
            if edge !== drivingEdge && !contains(folds, edge) //NOTE: driving fold not in folds
            {
                folds.append(edge)
                folds.sort({ $0.start.y > $1.start.y })
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
        if !edge.isMaster {
            var twin = edge.twin
            edges = edges - edge
            edges = edges - twin
            folds = folds - edge
            tabs  = tabs - edge
            if adjacency[edge.start] != nil {
                adjacency[edge.start] = adjacency[edge.start]!.filter({ $0 != edge })
                if adjacency[edge.start]!.count == 0 { adjacency[edge.start] = nil }
            }
            if adjacency[twin.start] != nil {
                adjacency[twin.start] = adjacency[twin.start]!.filter({ $0 != twin })
                if adjacency[twin.start]!.count == 0 { adjacency[twin.start] = nil }
            }

        }
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
        
        drivingEdge = addEdge(midLeft, end: midRight, path: path, kind: Edge.Kind.Fold, isMaster:false)
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
        
        // note width here has to subtract the border
        drawingBounds =  CGRectMake(b1.x, b1.y, width - ((screenWidth - width)), height - (screenHeight - height))
    }
    
    
    /// does a traversal of all the edges to find all the planes
    func getPlanes()
    {
        planes.removeAll()
        visited = []
        
        for (i, start) in enumerate(edges)//traverse edges
        {
            var p : [Edge] = []
            if contains(visited, start){// skipped over already visited edges
                continue
            }
                
            else
            {
                p.append(start)
                visited.append(start)
                
                var closest = getClosest(start)// get closest adjacent edge

                // check if twin has not been crossed and not in plane
                while !CGPointEqualToPoint(closest.end, start.start) && !closest.crossed
                {
                    p.append(closest)
                    visited.append(closest)
                    closest = getClosest(closest)
                }

                if CGPointEqualToPoint(closest.end, start.start) && !CGPointEqualToPoint(start.start, start.end){
                    p.append(closest)
                    visited.append(closest)
                }
                
                if !closest.crossed || CGPointEqualToPoint(start.start, start.end) {// if you didn't cross twin, make it a plane
                    var plane = Plane(edges: p)
                    for e in p
                    {
                        e.plane = plane
                        if e.kind == .Fold || e.kind == .Tab{
                            plane.kind = .Plane
                            if (e.kind == .Fold){
                                plane.orientation = .Vertical
                            }
                        }
                    }
                    
                    //if one edge hole, ensure that hole is right direction
                    if CGPointEqualToPoint(start.start, start.end) && !isCounterClockwise(plane.path){
                        plane.path = plane.path.bezierPathByReversingPath()
                    }
                    planes.addPlane(plane)
                }
                closest.crossed = false
            }
        }
    }
    
    
    //get closest adjancent edge
    // get angle between lines
    func getClosest(current: Edge) -> Edge
    {
        var closest: Edge!

        if adjacency[current.end]!.count < 2 {
            closest = adjacency[current.end]![0]
            closest.crossed = true
            return closest
        }
        
        for next in adjacency[current.end]!
        {
            if current.twin === next || contains(visited, next){//if the current closest is twin or it's already visited, the 
                continue
            }
            
            if closest == nil  // make the first edge the closest
            {
                closest = next
                continue
            }

            // compare for greater angle for closest and next
            let curr_ang = getAngle(current, closest)
            let next_ang = getAngle(current, next)
            
            if  next_ang < curr_ang // if the current angle is bigger than the next edge
            {
                closest = next
            }
        }
        
        // if nil means only twin edge so return twin
        if closest == nil {
            closest = current.twin
            closest.crossed = true
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
                        bottomFold = p!.bottomFold()
                    }
                }
            }
            if bottomFold != nil {
                
                if bottomFold!.start.y == drivingEdge.start.y {
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
                    tabs = tabs - tab
                    tabs = tabs - tab.twin
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
    
    /// returns the edge and nearest hitpoint to point given
    func edgeHitTest(point:CGPoint) -> (Edge, CGPoint)?
    {
        var r:(Edge,CGPoint)? = nil
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
        for (k,v) in adjacency
        {
            if CGPathContainsPoint(path.CGPath, nil, k, true)
            {
                for e in v
                {
                    if e.path != path { list.append(e) }
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
    
    
    // returns true if this plane is equal to the border edges plane
    func checkBorderPlane(plane:Plane) -> Bool
    {
        var listOfPlanePoints:[CGPoint] = [CGPoint]()
        for edge in plane.edges {
            listOfPlanePoints.append(edge.start)
            listOfPlanePoints.append(edge.end)
        }
        
        var listOfBorderPoints:[CGPoint] = [CGPoint]()
        listOfBorderPoints.append(self.bEdge1.start)
        listOfBorderPoints.append(self.bEdge1.end)
        
        listOfBorderPoints.append(self.bEdge3.start)
        listOfBorderPoints.append(self.bEdge3.end)
        
        listOfBorderPoints.append(self.drivingEdge.start)
        listOfBorderPoints.append(self.drivingEdge.end)
        
        listOfPlanePoints = listOfPlanePoints.unique()
        
        let intersection = listOfBorderPoints.intersection(listOfPlanePoints)
        let b = intersection.count == listOfPlanePoints.count && intersection.count == listOfBorderPoints.count
        
//        println("checking plane to borders: \(b), \(intersection.count)")
        return b
    }
    
    
}

