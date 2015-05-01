////
////  Math.swift
////  foldlings
////
////


func square(a: CGFloat) -> CGFloat{
    return a * a
}

/// get the angle between two edges
func getAngle(edgeA: Edge, edgeB: Edge) ->CGFloat{
    
    
    //    // CGPoint - CGPoint
    //        var a = CGPointNormalize(CGPointSubtract(edgeA.end, edgeA.start))//this is current
    //        var b = CGPointNormalize(CGPointSubtract(edgeB.end, edgeB.start))// this one is being evaluated wrt edgeA
    ////
    // control point calculation only for same end
    //    var a = CGPointNormalize(CGPointSubtract(findControlPoint(edgeA.path), edgeA.start))
    //    var b = CGPointNormalize(CGPointSubtract(findControlPoint(edgeB.path), edgeB.start))
    
    var a = CGPointNormalize(CGPointSubtract(findCentroid(edgeA.path), edgeA.start))
    var b = CGPointNormalize(CGPointSubtract(findCentroid(edgeB.path), edgeB.start))
    //    var a = CGPointNormalize(CGPointSubtract(getFirstPoint(edgeA.path), edgeA.start))
    //    var b = CGPointNormalize(CGPointSubtract(getFirstPoint(edgeB.path), edgeB.start))
    //    println("new pointa: \(getFirstPoint(edgeA.path)) \n")
    //    println("new pointb: \(getFirstPoint(edgeB.path)) \n")
    
    println("subtract centroid a: \(CGPointSubtract(findCentroid(edgeA.path), edgeA.start))")
    println("subtract centroid b: \(CGPointSubtract(findCentroid(edgeB.path), edgeB.start))")

    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    //    CGPoint a2 = ccpNormalize(a);
    //    CGPoint b2 = ccpNormalize(b);
    //    float angle = atan2f(a2.x * b2.y - a2.y * b2.x, ccpDot(a2, b2));
    //    if( fabs(angle) < kCGPointEpsilon ) return 0.f;
    //    if dot == 0.0 {
    println("a: \(a), b: \(b)")
    println("dot product: \(dot)")
    //}
    //    if det == 0.0 {
    println("determinant: \(det)")
    //}
    var angle = atan2(det,dot) * CGFloat(180.0 / M_PI) // atan2(y, x) or atan2(sin, cos)
    if ( abs(angle) < 0.01) { return 0.0 }
    
    return angle
    
}
