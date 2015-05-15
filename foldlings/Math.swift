////
////  Math.swift
////  foldlings
////
////


func square(a: CGFloat) -> CGFloat{
    return a * a
}

/// get the angle between two edges
func getAngle(edgeA: Edge, edgeB: Edge) -> CGFloat{
    
    // get the centroid and create the vector
    var a = CGPointSubtract(findCentroid(edgeA.path), edgeA.start)
    var b = CGPointSubtract(findCentroid(edgeB.path), edgeB.start)

    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    var angle = atan2(det,dot) * CGFloat(180.0 / M_PI) // atan2(y, x) or atan2(sin, cos)
    if ( abs(angle) < 0.000000000000001) { return 0.0 }
    
    return angle
    
}
// returns the average of two CGFloats
func makeMid(a:CGFloat, b:CGFloat) -> CGFloat{
    return CGFloat((a + b)/2.0)
}
