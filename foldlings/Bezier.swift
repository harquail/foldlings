//
//  Path.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved

import Foundation
import CoreGraphics
import UIKit

//how fine to make the subdivisions -- is divided by the length of the line
let kBezierIncrements:CGFloat = 0.5

//the bezier path through a set of points
func pathThroughCatmullPoints(points:[NSValue], closed:Bool) -> UIBezierPath{
    //if there are enough points, draw a lovely curve
    if(points.count > 3){
        let path = UIBezierPath()
        
        //the line between the first two points, which is not part of the catmull-rom curve
        if(!closed){
            path.moveToPoint(points[0].CGPointValue())
            path.addLineToPoint(points[1].CGPointValue())
        }
        
        path.appendPath(UIBezierPath.interpolateCGPointsWithCatmullRom(points as [AnyObject], closed: closed, alpha: 1.0))
        
        //if not closed, add the line to the currrent touch point from the end
        if(!closed){
            path.addLineToPoint(points.last!.CGPointValue())
        }
        return path
    }
    else{
        //for low numbers of points, return a straight line
        let path = UIBezierPath()
        path.moveToPoint(points.first!.CGPointValue())
        path.addLineToPoint(points.last!.CGPointValue())
        return path
    }
}


///find the average point on a line
func findCentroid(path:UIBezierPath) -> CGPoint
{
    let elements = path.getPathElements()
    // if a staright line, just return endpoint
    // TODO: maybe should return center point rather than endpoint
    if elements.count <= 2{
//        println(path)
//        println("center \(path.center())")
        return path.center()
    }
    
    let points = getSubdivisions(elements, increments:25)
    var npoint:CGPoint = CGPointZero
    
    for point in points {
        npoint = CGPointAdd(npoint, point)
    }
    npoint = CGPointMake(npoint.x / CGFloat(points.count), npoint.y / CGFloat(points.count))
    
    return npoint

}

/// returns a point near the center of a bezier path
func pointNearCenterOf(path:UIBezierPath) -> CGPoint{
    
    // allocate enough room for 4 points per element
    var ps:UnsafeMutablePointer<CGPoint> = UnsafeMutablePointer<CGPoint>.alloc(4)
    var psPrev:UnsafeMutablePointer<CGPoint> = UnsafeMutablePointer<CGPoint>.alloc(4)
    let centerElement = path.elementAtIndex(path.elementCount()/2, associatedPoints: ps)
    let prevElement = path.elementAtIndex((path.elementCount()/2) - 1, associatedPoints: psPrev)

    let a = psPrev[0]
    let b = ps[0]
    let c = ps[1]
    let d = ps[2]
    //get the point at t = halfway
    let centerPoint = bezierInterpolation(CGFloat(0.5), a, b, c, d)

    // free stuff, cause we used an unsafe pointer
    ps.dealloc(4)
    psPrev.dealloc(4)

    return centerPoint
    
}

// TODO: average cgpoints



/// is the path given drawn in counterclockwise winding order
 func isCounterClockwise(path:UIBezierPath) -> Bool
{
    return !path.isClockwise()
}


/// get a path of line segments from a set of points
func linePathFromPoints(path:[CGPoint]) -> UIBezierPath
{
    var npath = UIBezierPath()
    if path.count > 0 {
        npath.moveToPoint(path[0])
        for var i = 1; i < path.count; i++
        {
            npath.addLineToPoint(path[i])
        }
        
    }
    return npath
}


///recunstruct a bezier path from a set of points
func pathFromPoints(path:[CGPoint]) -> UIBezierPath
{
    var npath = UIBezierPath()
    
    if path.count > 0 {
        npath.moveToPoint(path[0])
        var i = 0
        for i = 0; i < path.count-4; i=i+3
        {
            var newEnd = CGPointMake((path[i+2].x + path[i+4].x)/2.0, (path[i+2].y + path[i+4].y)/2.0 )
            npath.addCurveToPoint(newEnd, controlPoint1: path[i+1], controlPoint2: path[i+2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
        }
        switch path.count-i {
        case 4:
            npath.addCurveToPoint(path[i+3], controlPoint1: path[i+1], controlPoint2:   path[i+2])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
            break
        case 3:
            npath.addCurveToPoint(path[path.count-1], controlPoint1: path[path.count-2], controlPoint2: path[path.count-3])// add a cubic Bezier from pt[0] to pt[3], with control points pt[1] and pt[2]
            break
        default:
            npath.addLineToPoint(path[path.count-1])
            break
        }
    }
    
    return npath
}
//
/////splits the path at the point given
//func splitPath(path:UIBezierPath, withPoint point:CGPoint) -> (UIBezierPath, UIBezierPath)
//{
//    let elements = path.getPathElements()
//    let points = getSubdivisions(elements)
//    var pathOnePoints = [CGPoint]()
//    var pathTwoPoints = [CGPoint]()
//    
//    // find the nearest point
//    // this is necessary because the subdivisions are not guaranteed equal all the time
//    // but will usually be pretty exact
//    var mindist=CGFloat.max
//    var minI = 0
//    for (var i = 0; i < points.count; i++)
//    {
//        let d = CGPointGetDistance(points[i], point)
//        if (d < mindist) {
//            mindist = d
//            minI = i
//        }
//    }
//    
//    for (var i = 0; i < points.count; i++)
//    {
//        if i < minI {
//            pathOnePoints.append(points[i])
//        } else {
//            pathTwoPoints.append(points[i])
//        }
//    }
//    
//    let uipathOne = pathFromPoints(smoothPoints(pathOnePoints))
//    let uipathTwo = pathFromPoints(smoothPoints(pathTwoPoints))
//    
//    return (uipathOne, uipathTwo)
//    
//}

/// smooths a uibezierpath using douglas peucker method
func smoothPath(path:UIBezierPath) -> UIBezierPath
{
    let elements = path.getPathElements()
    let points = getSubdivisions(elements)
    let npaths = smoothPoints(points)
    return pathFromPoints(npaths)
}

/// smooths a set of point using douglas peucker method
func smoothPoints(points:[CGPoint], epsilon:Float = 0.5) -> [CGPoint]
{
    let pArray = convertToNSArray(points)
    var nArray = BezierSimple.douglasPeucker(pArray as [AnyObject], epsilon: epsilon)
    // if it is a closed shape we want to smooth the first point also so run it twice choosing a different ordering of points
    // clever if confusing
    if CGPointEqualToPoint(points[0], points[points.count-1]) {
        let midp:Int = nArray.count/2
        var closearray = Array(nArray[midp...(nArray.count-1)])
        closearray += Array(nArray[0...midp])
        nArray = BezierSimple.douglasPeucker(closearray, epsilon: epsilon)
    }
    let npaths = convertToCGPoints(nArray)
    return npaths
}


/// returns the nearest *interpolated* point on a UIBezierPath,
func getNearestPointOnPath(point:CGPoint, path:UIBezierPath) -> CGPoint
{
    let cgpath:CGPath = path.CGPath
    var bezierPoints:NSMutableArray = []
    
    let elements = path.getPathElements()
    
    // if only two elements then it must be a line so treat it that way
    if elements.count == 0 {
//        println("no elements in path returning same! \(elements)")
        return point
    }
    else if elements.count == 2
    {
        let p1:CGPoint = (elements[0] as! CGPathElementObj).points[0].CGPointValue()
        let p2:CGPoint = (elements[1] as! CGPathElementObj).points[0].CGPointValue()
        let np = nearestPointOnLine(point, p1, p2)
        return np
    } else {
        // otherwise must be a curve so get subdivisions and find nearest point
        let points = getSubdivisions(elements)
        var mindist=CGFloat.max
        var minI = 0
        for (var i = 0; i < points.count; i++)
        {
            let d = CGPointGetDistance(points[i], point)
            if (d < mindist) {
                mindist = d
                minI = i
            }
        }
        return points[minI]
    }
    
}

/// finds path elements and subdivides them
/// currently supports movepoints and addcurves
/// needs line and quad curve to be complete
func getSubdivisions(elements:NSArray, increments:CGFloat = kBezierIncrements) -> [CGPoint]{
    
    var bezierPoints = [CGPoint]();
    var subdivPoints = [CGPoint]();
    
    var index:Int = 0
    let els = elements as! [CGPathElementObj]
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
            //println("subdiv:addLine")
            let p = currPath.points[0].CGPointValue()
            bezierPoints.append(p)
            let pointsToSub:[CGPoint] = [priorPoint, p]
            subdivPoints  += subdivide(pointsToSub, increments: increments)
            priorPoint = p
            index++
        case kCGPathElementAddQuadCurveToPoint.value:
            //println("subdiv: addQuadCurve")
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
            subdivPoints  += subdivide(pointsToSub, increments: increments)
            priorPoint = p3
            index += 3
        case kCGPathElementCloseSubpath.value:
            // these contain no points
            subdivPoints.append(subdivPoints[0])
            break
        default:
            break
//            println("other: \(currPath.type)")
        }
    }
    
    return subdivPoints
    
}


/// only currently supports cubic curves and lines
func subdivide(points:[CGPoint], increments:CGFloat = kBezierIncrements) -> [CGPoint]
{
    var npoints:[CGPoint] = [CGPoint]()
    
    switch points.count {
    case 4:
        //TODO: Fix this not-super terrible, but still bad shit (pathFromPoints)
        let bounds = pathFromPoints(points).bounds
        let length = max(bounds.width, bounds.height)
        for var t:CGFloat = 0.0; t <= 1.00001; t += increments / length {
            let point = bezierInterpolation(t,points[0],points[1],points[2],points[3])
            npoints.append(point);
        }
    case 2:
        let start = points[0]
        let end = points[1]
        let length = CGPointGetDistance(start, end)
        let ste = (end.x - start.x, end.y - start.y)
        for var t:CGFloat = 0.0; t <= 1.00001; t += increments / length{
            let point = CGPointMake(start.x + ste.0*t, start.y + ste.1*t );
            npoints.append(point);
        }
    default:
        break
    }
    
    return npoints
}


//convenience method for interpolating between control points
func bezierInterpolation(t:CGFloat, a:CGPoint, b:CGPoint, c:CGPoint, d:CGPoint) -> CGPoint {
    let x = bezierInterpolation(t,a.x,b.x,c.x,d.x)
    let y = bezierInterpolation(t,a.y,b.y,c.y,d.y)
    return CGPointMake(x,y)
}

/// simple 4 point bezier interpolation give a t value along the curve
func bezierInterpolation(t:CGFloat, a:CGFloat, b:CGFloat, c:CGFloat, d:CGFloat) -> CGFloat {
    let t2 = t * t;
    let t3 = t2 * t;
    return a + (-a * 3 + t * (3 * a - a * t)) * t
        + (3 * b + t * (-6 * b + b * 3 * t)) * t
        + (c * 3 - c * 3 * t) * t2
        + d * t3;
}

/// return the nearest point on a line to the point provided
 func nearestPointOnLine(point:CGPoint, start:CGPoint, end:CGPoint) -> CGPoint
{
    let stp = (point.x - start.x, point.y - start.y)   //start->point
    let ste = (end.x - start.x, end.y - start.y)       //start->end
    
    let ste2 = square(ste.0) + square(ste.1)           //line length
    
    let stp_dot_ste = stp.0*ste.0 + stp.1*ste.1        //dot prod
    
    let t = stp_dot_ste / ste2                         //normalized distance from a to closest point
    
    return CGPointMake(start.x + ste.0*t, start.y + ste.1*t )  //the the point distance t
    
}

///helper function to convert [CGPoint] -> NSArray of NSValue CGPoints
func convertToNSArray(path:[CGPoint]) ->NSArray
{
    var arr = NSMutableArray()
    for p in path {
        arr.addObject(NSValue(CGPoint:p))
    }
    return NSArray(array:arr)
}

///helper function to convert NSArray of NSValue CGPoints -> [CGPoint]
func convertToCGPoints(path:NSArray) -> [CGPoint]
{
    var npath = [CGPoint]()
    for p in path
    {
        npath.append(p.CGPointValue())
    }
    
    return npath
}

// get first control point of a path
//func findControlPoint(path:UIBezierPath)-> CGPoint
//{
//    let elements = path.getPathElements()
//    let els = elements as! [CGPathElementObj]
//    var CPoint:CGPoint = els[1].points[0].CGPointValue()
//    return CPoint
//}
//
//// find the max x and y of all the points and put it into a point
//func calculateBounds(points: [CGPoint]) ->CGPoint{
//    var newX:[CGFloat] = points.map({$0.x})
//    var newY:[CGFloat] = points.map({$0.y})
//    return CGPointMake(maxElement(newX), maxElement(newY))
//}
//// gets a point on the line close to the start point
//// to be used to calculate the vector for angles
//// look at cases whether els has 2 or 4 points
//// then run through bezierInterpolation with the point and
//// take min and max  x and y to figure out bounds
//// generate t from these values 
//// return the makeCGPoint 
//func getFirstPoint(path:UIBezierPath)-> CGPoint
//{
//    var increments: CGFloat = 25.0
//    let elements = path.getPathElements()
//    let els = elements as! [CGPathElementObj]
//    var points : [CGPoint] = els[1].points.map({$0.CGPointValue()})
//    var point = CGPoint()
//    
//    switch points.count {
//    case 4:
//        let bounds:CGPoint = calculateBounds(points)
//        let length = max(bounds.x, bounds.y)
//        let t = increments / length
//        point = CGPointMake(bezierInterpolation(t, points[0].x, points[1].x, points[2].x, points[3].x), bezierInterpolation(t, points[0].y, points[1].y, points[2].y, points[3].y));
//        
//        
//    case 2:
//        let start = points[0]
//        let end = points[1]
//        let length = CGPointGetDistance(start, end)
//        let ste = (end.x - start.x, end.y - start.y)
//        let t = increments / length
//            point = CGPointMake(start.x + ste.0*t, start.y + ste.1*t );
//        
//    default:
//        break
//    }
//    return point
//}


class Bezier{

//TODO: verify that this is not introducing floating point error
    //splits a bezierpath composed of cubic curves at intersection points
    class func pathSplitByPoints(path:UIBezierPath,breakers:[CGPoint]) ->[UIBezierPath]{
        
        var closestElements = [CGPathElement](count: breakers.count, repeatedValue: CGPathElement())
        var closestElementsDists = [CGFloat](count: breakers.count, repeatedValue:CGFloat.max)
        
        // this is the end point of the previous element, which is our new start point
        var prevPoint:CGPoint = CGPointZero // TODO: this might be bad, if it ever gets used
        // first, find the closest element to each intersection point
        for var i = 0; i < Int(path.elementCount()); i++ {
            let el = path.elementAtIndex(i)
            // element 0 is always a moveto
            let points = el.points
            // for curves
            if el.type.value == kCGPathElementAddCurveToPoint.value{
                for (i,breaker) in enumerate(breakers){
                    // take 10 subdivisions
                    for j:Float in [0.0,0.1,0.2,0.3,0.4,0.5,0.6,0.7,0.8,0.9,1.0]{
                        
                        //get point at t value on curve
                        let p = CGPointMake(bezierInterpolation(CGFloat(j), prevPoint.x, points[0].x, points[1].x, points[2].x), bezierInterpolation(CGFloat(j), prevPoint.y, points[0].y, points[1].y, points[2].y));
                        
                        // set new closest element if appropriate
                        let dist = ccpDistance(p, breaker)
                        if ( dist < closestElementsDists[i]){
                            closestElementsDists[i] = dist
                            closestElements[i] = el
                        }
                        
                    }
                }
                prevPoint = el.points[2]
                
            }
            else if el.type.value == kCGPathElementMoveToPoint.value{
                prevPoint = el.points[0]
            }
            // for lines
            else if el.type.value == kCGPathElementAddLineToPoint.value{
                
                for (i,breaker) in enumerate(breakers){
                    
                    //get point at t value on line
                    let p = nearestPointOnLine(breaker, prevPoint, el.points[0])
                    
                    // set new closest element if appropriate
                    let dist = ccpDistance(p, breaker)
                    if ( dist < closestElementsDists[i]){
                        closestElementsDists[i] = dist
                        closestElements[i] = el
                    }
                }
                prevPoint = el.points[0]
            }
            
        }
        // start with an empty path
        var returnee:[UIBezierPath] = []
        returnee.append(UIBezierPath())
        //all paths must start with a move to point
        returnee.last!.moveToPoint(path.elementAtIndex(0).points[0])
        //this second loop is less bad than it looks, because elements are cached by PerformanceBezier
        for var i = 0; i < Int(path.elementCount()); i++ {
            
            let el = path.elementAtIndex(i)
            
            let points = el.points
            
            switch(el.type.value){
            case kCGPathElementMoveToPoint.value :
                prevPoint = el.points[0]
            case kCGPathElementAddLineToPoint.value :
                var splittingPointsForElement:[CGPoint] = []
                
                for (j,breaker) in enumerate(breakers){
                    // if the element contains a break point
                    if(CGPointEqualToPoint(el.points[0], closestElements[j].points[0])){
                        
                        //add the point to the splitting points
                        splittingPointsForElement.append(breaker)
                    }
                }

                if splittingPointsForElement.isEmpty{
                    returnee.last!.addLineToPoint(points[0])
                    prevPoint = el.points[0]
                }
                else{
                    returnee.append(UIBezierPath())
                    returnee.last!.moveToPoint(prevPoint)
                    returnee.last!.addLineToPoint(splittingPointsForElement[0])
                    
                    returnee.append(UIBezierPath())
                    returnee.last!.moveToPoint(splittingPointsForElement[0])
                    returnee.last!.addLineToPoint(points[0])
                    
                    splittingPointsForElement.append(points[0])
                    splittingPointsForElement.sort({return ccpDistance($0, el.points[0]) > ccpDistance($1, el.points[0])})
                    for (i,split) in enumerate(splittingPointsForElement){

                        returnee.last!.addLineToPoint(split)
                        returnee.append(UIBezierPath())
                        returnee.last!.moveToPoint(split)
                        prevPoint = split
                    }
                    
                    prevPoint = points[0]
                    
                }
            case kCGPathElementAddQuadCurveToPoint.value : println("quad")
            case kCGPathElementAddCurveToPoint.value :
                
                var splittingPointsForElement:[(p:CGPoint,t:CGFloat)] = []
                
                for (j,breaker) in enumerate(breakers){
                    // if the element contains a break point
                    if(CGPointEqualToPoint(el.points[2], closestElements[j].points[2])){
                        
                        //add the point & t value to the splitting points
                        let t = tVeryNearPointonCurve(prevPoint, originalCurve: el, p: breaker)
                        splittingPointsForElement.append((p:breaker,t:t))
                    }
                }
                
                //need to sort splitting points by t value, so we can keep subdividing the last point
                splittingPointsForElement.sort({$0.t < $1.t})
                
                //set initial curve to entire cgpathelement
                var cgObj = CGPathElementObj()
                cgObj.type = el.type
                cgObj.points =  convertToNSArray([el.points[0],el.points[1],el.points[2]]) as [AnyObject]
                
                for (i,split) in enumerate(splittingPointsForElement){
                    
                    // split the curve at t
                    let newCurves = splitCubicCurveAtT(prevPoint,originalCurve: cgObj,t: Float(split.t))
                    
                    //append the portion of the element between its startpoint and the t point
                    returnee.append(UIBezierPath())
                    returnee.last!.moveToPoint(prevPoint)
                    returnee.last!.addCurveToPoint(split.p  , controlPoint1: newCurves.0.points[0].CGPointValue(), controlPoint2: newCurves.0.points[1].CGPointValue())
                    
                    //if this is the last intersection, also append last portion of the path, from t point to end
                    if(i == splittingPointsForElement.count - 1){
                        returnee.append(UIBezierPath())
                        returnee.last!.moveToPoint(split.p)
                        returnee.last!.addCurveToPoint(newCurves.1.points[2].CGPointValue(), controlPoint1: newCurves.1.points[0].CGPointValue(), controlPoint2: newCurves.1.points[1].CGPointValue())
                    }
                    // set up curve for next interation.  The new curve goes from split to the end of the previous path element
                    prevPoint = split.p
                    cgObj.points = newCurves.1.points
                    
                }
                
                //if the element does not have any splitting points, add it to the returned path as is
                if(splittingPointsForElement.isEmpty){
                    returnee.last!.addCurveToPoint(points[2], controlPoint1: points[0], controlPoint2: points[1])
                }
                prevPoint = el.points[2]
            case kCGPathElementCloseSubpath.value :
                println("close")
                break
            default: println("unexpected")
            }
        }
        
        return returnee
    }
    
    
    // searches for the nearest interpolation point to p on curve
    class func tVeryNearPointonCurve(previousPoint:CGPoint,originalCurve:CGPathElement,p:CGPoint) -> CGFloat
    {
        
        //    Calculate the parameterized value along the curve (between 0.0 and 1.0) of the touch. To do this you can calculate a set of points at regular intervals (0.1, 0.2, 0.3 etc.) and then find the two closest points to your touch points and repeat the parameterization between these points if you want more accuracy (0.21, 0.22, 0.23, etc.). This will result in a number between 0.0 and 1.0 along the curve segment representing where you touched.
        let maxRecursionDepth = 3
        return Bezier.approachT(0.000,endT: 1.000,start: previousPoint,ctrl1: originalCurve.points[0],ctrl2: originalCurve.points[1],end: originalCurve.points[2],goal:p,recursionDepth: maxRecursionDepth)
    }
    
    //recursive search for nearest t value
   private class func approachT (startT:CGFloat,endT:CGFloat,start:CGPoint,ctrl1:CGPoint,ctrl2:CGPoint,end:CGPoint,goal:CGPoint, recursionDepth:Int) -> CGFloat{
        
        //calculate 5 t values
        let divisions = CGFloat(4.0000)
        let step = abs(endT - startT)/divisions
        
        if(recursionDepth > 0){
            
            var closestPointOnCurve = (t:CGFloat(0),p:CGPointZero,dist:CGFloat.max)
            var secondClosest = (t:CGFloat(1.0),p:CGPointZero,dist:CGFloat.max)
            
            //get the two closest points, between which we will make our next set of divisions
            for(var t = startT; t <= endT; t += step){
                let p = bezierInterpolation(t, start, ctrl1, ctrl2, end)
                let distToGoal = ccpDistance(p,goal)
                
                if(distToGoal < secondClosest.dist){
                    secondClosest = closestPointOnCurve
                    closestPointOnCurve = (t:t,p:p,dist:distToGoal)
                }
            }
            
            //recurse with new t values, decremented recursion value, and everything else the same
            
            return Bezier.approachT(min(closestPointOnCurve.t,secondClosest.t),endT: max(closestPointOnCurve.t,secondClosest.t),start: start,ctrl1: ctrl1,ctrl2: ctrl2,end: end, goal:goal,recursionDepth: recursionDepth - 1)
            
            
        }
        else{
            // base case: return the average of the t values of the two closest points
            
            return (startT + endT)/2
        }
    }
    
    
    // splits a cubic bezier curve at a fraction of its length.  Pseudocode from stackoverflow
    //    This bit is difficult to explain in text, but there's a good visualization on this page about half-way down under the heading Subdividing a Bezier curve. Use the slider under the diagram to see how it works, here's my textual explanation: You need to subdivide the straight lines between the control points of your curve segment proportional to the parameterized value you calculated in step 1. So if you calculated 0.4, you have four points (A, B, C, D) plus the split-point on the curve closest to your touch at 0.4 along the curve, we'll call this split-point point S:
    private class func splitCubicCurveAtT(previousPoint:CGPoint,originalCurve:CGPathElementObj,t:Float) -> (CGPathElementObj,CGPathElementObj){
        
        //    Calculate a temporary point T which is 0.4 along the line B→C
        
        let a = previousPoint
        let b = originalCurve.points[0].CGPointValue()
        let c = originalCurve.points[1].CGPointValue()
        let d = originalCurve.points[2].CGPointValue()
        //t a b c d
        let s = bezierInterpolation(CGFloat(t), a, b, c, d)
        
        //Calculate a temporary point T which is 0.4 along the line B→C
        let temp = ccpLerp(b,c,t)
        //    Let point A1 be equal to point A
        let a1 = a
        //    Calculate point B1 which is 0.4 along the line A→B
        let b1 = ccpLerp(a1,b,t)
        //    Calculate point C1 which is 0.4 along the line B1→T
        let c1 = ccpLerp(b1,temp,t)
        //    Let point D1 be equal to the split point S
        let d1 = s
        //    Let point D2 be equal to point D
        let d2 = d
        //    Calculate point C2 which is 0.4 along the line C→D
        let c2 = ccpLerp(c,d,t)
        //    Calculate point B2 which is 0.4 along the line T→C2
        let b2 = ccpLerp(temp,c2,t)
        //    Let point A2 be equal to the split point S
        let a2 = s
        
        let leg1 = CGPathElementObj(type: kCGPathElementAddCurveToPoint, points: convertToNSArray([b1,c1,d1]) as [AnyObject])
        let leg2 = CGPathElementObj(type: kCGPathElementAddCurveToPoint, points: convertToNSArray([b2,c2,d2]) as [AnyObject])
        
        return (leg1,leg2)
    }
    
    class func endingElementsOf(path:UIBezierPath) -> String{
        
        let elementCount = path.elementCount()
        var first:CGPathElement = path.elementAtIndex(0)
        var last:CGPathElement = path.elementAtIndex(elementCount-1)
        var returnee:String = ""
        
        returnee.extend("edge with \(elementCount) elements:")
        returnee.extend("\t first:")
        withUnsafePointer(&first, { (ptr: UnsafePointer<CGPathElement>) -> Void in
            returnee.extend("\t\t\(UIBezierPath().ob_descriptionForPathElement(ptr))")
        })
       returnee.extend("\t last:")
        withUnsafePointer(&last, { (ptr: UnsafePointer<CGPathElement>) -> Void in
            returnee.extend("\t\t\(UIBezierPath().ob_descriptionForPathElement(ptr))")
        })
        return returnee
    }
    
    class func selfIntersections(path:UIBezierPath){
    
        // allocate enough room for 4 points per element
        var pI:CGPoint = CGPointZero
        var pIPrev:CGPoint = CGPointZero

        var pJ:CGPoint = CGPointZero
        var pJPrev:CGPoint = CGPointZero
        
        for (var i=0; i<path.elementCount(); i++){
            
            pIPrev = pI
            // this assigns pI
            let elemntI = path.elementAtIndex(i, associatedPoints: &pI)

            for (var j=0; j<path.elementCount(); j++){
                if(i == j){
                    continue
                }
                
                pJPrev = pJ
                // this assigns pJ
                let elemntJ = path.elementAtIndex(j, associatedPoints: &pJ)
                
                let intersection = ccpPointOfSegmentIntersection(pIPrev, pI, pJPrev, pJ)
                if(!CGPointEqualToPoint(intersection, CGPointZero)){
                    
                    let intersectionAtEnd = [pIPrev,pI,pJPrev,pJ].find({CGPointEqualToPoint($0,intersection)})
                    if let intersect = intersectionAtEnd{
                        continue
                    }
                    println("!! pIPrev: \(pIPrev) | pJPrev \(pJPrev) !!")
                    println(intersection)
                    println("!! pI: \(pI) | pJ \(pJ) !!")
                    println("----------------------")

                }
                else{
//                    print(".")
                }
                
            }
        }
        
    }
    
}

