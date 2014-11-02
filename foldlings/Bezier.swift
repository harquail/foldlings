//
//  Path.swift
//  foldlings
//
//

import Foundation
import CoreGraphics
import UIKit

let kBezierIncrements:CGFloat = 0.02

// returns the nearest *interpolated* point on a UIBezierPath,
func getNearestPointOnPath(point:CGPoint, path:UIBezierPath) -> CGPoint
{
    let cgpath:CGPath = path.CGPath;
    var bezierPoints:NSMutableArray = []
    
    let elements = path.getPathElements()
    let points = getSubdivisions(elements)
    //TODO: use nearestPointOnLine for fold line segments rather than subdividing those
    var mindist=CGFloat.max
    var minI = 0
    for (var i = 0; i < points.count; i++)
    {
        let d = dist(points[i], point)
        if (d < mindist) {
            mindist = d
            minI = i
        }
    }
    
    println("found closest point: \(points[minI]) to \(point)")
    
    return points[minI]
    
}


//finds path elements and subdivides them
// currently supports movepoints and addcurves
// needs line and quad curve to be complete
func getSubdivisions(elements:NSArray) -> [CGPoint]{
    
    var bezierPoints = [CGPoint]();
    var subdivPoints = [CGPoint]();
    
    var index:Int = 0
    let els = elements as [CGPathElementObj]
    var priorPoint:CGPoint = els[0].points[0].CGPointValue()
    var nextPoint:CGPoint = els[0].points[0].CGPointValue()
    var priorPath:CGPathElementObj = els[0]
    var currPath:CGPathElementObj = els[0]
    
    for (var i = 0; i < els.count; i++) {
        currPath = els[i]
        switch (currPath.type.value) {
        case kCGPathElementMoveToPoint.value:
            let p = currPath.points[0].CGPointValue()
            bezierPoints.append(p)
            priorPoint = p
            index++
        case kCGPathElementAddLineToPoint.value:
            println("subdiv:addLine")
            let p = currPath.points[0].CGPointValue()
            bezierPoints.append(p)
            let pointsToSub:[CGPoint] = [priorPoint, p]
            subdivPoints  += subdivide(pointsToSub)
            priorPoint = p
            index++
        case kCGPathElementAddQuadCurveToPoint.value:
            println("subdiv: addQuadCurve")
            let p1 = currPath.points[0].CGPointValue()
            let p2 = currPath.points[1].CGPointValue()
            bezierPoints.append(p1)
            bezierPoints.append(p2)
            priorPoint = p2
            index += 2
        case kCGPathElementAddCurveToPoint.value:
            let p1 = currPath.points[0].CGPointValue()
            let p2 = currPath.points[1].CGPointValue()
            let p3 = currPath.points[2].CGPointValue()
            bezierPoints.append(p1);
            bezierPoints.append(p2);
            bezierPoints.append(p3);
            let pointsToSub:[CGPoint] = [priorPoint, p1, p2, p3]
            subdivPoints  += subdivide(pointsToSub)
            priorPoint = p3
            index += 3
        default:
            println("other: \(currPath.type.value)")
        }
    }

    return subdivPoints
    
}


//only currently supports cubic curves and lines
func subdivide(points:[CGPoint]) -> [CGPoint]
{
    var npoints:[CGPoint] = [CGPoint]()
    
    switch points.count {
    case 4:
        for var t:CGFloat = 0.0; t <= 1.00001; t += kBezierIncrements {
            let point = CGPointMake(bezierInterpolation(t, points[0].x, points[1].x, points[2].x, points[3].x), bezierInterpolation(t, points[0].y, points[1].y, points[2].y, points[3].y));
            npoints.append(point);
        }
    case 2:
        let start = points[0]
        let end = points[1]
        let ste = (end.x - start.x, end.y - start.y)
        for var t:CGFloat = 0.0; t <= 1.00001; t += kBezierIncrements {
            let point = CGPointMake(start.x + ste.0*t, start.y + ste.1*t );
            npoints.append(point);
        }
    default:
        break
    }
    
    return npoints
}


// simple 4 point bezier interpolation give a t value along the curve
func bezierInterpolation(t:CGFloat, a:CGFloat, b:CGFloat, c:CGFloat, d:CGFloat) -> CGFloat {
    let t2 = t * t;
    let t3 = t2 * t;
    return a + (-a * 3 + t * (3 * a - a * t)) * t
        + (3 * b + t * (-6 * b + b * 3 * t)) * t
        + (c * 3 - c * 3 * t) * t2
        + d * t3;
}

func nearestPointOnLine(point:CGPoint, start:CGPoint, end:CGPoint) -> CGPoint
{
    let stp = (point.x - start.x, point.y - start.y)   //start->point
    let ste = (end.x - start.x, end.y - start.y)       //start->end
    
    let ste2 = square(ste.0) + square(ste.1)           //line length
    
    let stp_dot_ste = stp.0*ste.0 + stp.1*ste.1        //dot prod
    
    let t = stp_dot_ste / ste2                         //normalized distance from a to closest point
    
    return CGPointMake(start.x + ste.0*t, start.y + ste.1*t )  //the the point distance t

}



