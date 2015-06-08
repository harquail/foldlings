//
//  Polygon.swift
//  foldlings
//
//  Created by nook on 6/7/15.
//  Copyright (c) 2015 Marissa Allen, Nook Harquail, Tim Tregubov.  All Rights Reserved.
//

import Foundation

class Polygon:FoldFeature{

    // the (draggable) points that define the polygon
    var points:[CGPoint] = []
    //the path through the points
    var path: UIBezierPath?
    //the intersection points calculated by featureSpansFold & used for occlusion
    var intersectionsWithDrivingFold:[CGPoint] = []
    
    //the path through polygon points
    class func pathThroughPolygonPoints(points:[CGPoint]) -> UIBezierPath? {
        var ps = points
    
        //return nil if we can't draw a path
        if(ps.isEmpty){
            return nil
        }
        
        var polyPath = UIBezierPath()
        // move to the first point & pop it off the array
        polyPath.moveToPoint(ps.shift()!)
        // draw lines between the remaining points
        points.map({polyPath.addLineToPoint($0)})
        
//        polyPath.closePath()
        
        return polyPath
    }
    
    // set intersections here
    override func featureSpansFold(fold: Edge) -> Bool {
        let ints = intersectionWithStraightEdge(fold)
        if((ints.count > 0) && (ints.count % 2 == 0)){
            return true
        }
        return false
        
    }
    
    override func splitFoldByOcclusion(edge: Edge) -> [Edge] {
        let start = edge.start
        let end = edge.end
        var returnee = [Edge]()
        
        if intersectionsWithDrivingFold.count == 0
        {
            return [edge]
        }
        
        intersectionsWithDrivingFold.sort (
            {(a:CGPoint, b:CGPoint) -> Bool in
                return (a.x < b.x)
            }
        )
        
        let firstPiece = Edge.straightEdgeBetween(start, end: intersectionsWithDrivingFold.first!, kind: .Fold, feature:self.parent!)
        returnee.append(firstPiece)
        
        var brushTip = intersectionsWithDrivingFold[0]
        
        //skip every other point, so we don't make edges inside shape
        for (var i = 1; i < intersectionsWithDrivingFold.count-1; i+=2)
        {
            brushTip = intersectionsWithDrivingFold[i]
            let brushTipTranslated = CGPointMake(intersectionsWithDrivingFold[i+1].x,brushTip.y)
            let piece = Edge.straightEdgeBetween(brushTip, end: brushTipTranslated, kind: .Fold, feature: self.parent!)
            returnee.append(piece)
        }
        
        let finalPiece = Edge.straightEdgeBetween(intersectionsWithDrivingFold.last!, end: end, kind: .Fold, feature: self.parent!)
        returnee.append(finalPiece)
        return returnee
    }
    
    func polyPointAt(point:CGPoint) -> CGPoint?{
        return nil
    }
    
    private func intersectionWithStraightEdge(edge:Edge) -> [CGPoint]{
        var intersections:[CGPoint] = []
        for e in featureEdges ?? []{
            let p = ccpPointOfSegmentIntersection(edge.start, edge.end, e.start, e.end)
            // everything that is not CGPointZero is a valid intersection
            if p != CGPointZero{
                println("int : \(p)")
                intersections.append(p)
                intersectionsWithDrivingFold.append(p)
            }
        }
        return intersections
    }
    
    func addPoint(point:CGPoint){
        var p = point
        
        if(pointClosesPoly(p)){
            p = points[0]
        }
        
        points.append(p)
        
        path = Polygon.pathThroughPolygonPoints(points)
        
        if(points.count>1){
        featureEdges?.append(Edge.straightEdgeBetween(points[points.count - 2], end: points.last!, kind: .Cut, feature: self))
            println(featureEdges)
        }
        else{
            featureEdges = []
        }
 
        
        endPoint = p
    }
    
    func pointClosesPoly(point:CGPoint) -> Bool{
        
        if(points.isEmpty){
        return false
        }
        
        return ccpDistance(points[0], point) < kHitTestRadius
    }
    
    func movePolyPoint(from:CGPoint, to:CGPoint) {
    
    }
    

    override func tapOptions() -> [FeatureOption]?{
        var options:[FeatureOption] = super.tapOptions() ?? []
        
        options.append(.DeleteFeature)
        
        if(self.isLeaf() && horizontalFolds.count >= 3){
            options.append(.MoveFolds);
        }
        
        options.append(.MovePoints)

        return options
        
    }
    
    override func containsPoint(point: CGPoint) -> Bool {
        return path?.containsPoint(point) ?? false
    }
    
}