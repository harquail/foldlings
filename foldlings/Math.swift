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
//    
    // control point calculation only for same end
//    var a = CGPointNormalize(CGPointSubtract(findControlPoint(edgeA.path), edgeA.start))
//    var b = CGPointNormalize(CGPointSubtract(findControlPoint(edgeB.path), edgeB.start))
    
   var a = CGPointNormalize(CGPointSubtract(findCentroid(edgeA.path), edgeA.start))
   var b = CGPointNormalize(CGPointSubtract(findCentroid(edgeB.path), edgeB.start))
//    var a = CGPointNormalize(CGPointSubtract(getFirstPoint(edgeA.path), edgeA.start))
//    var b = CGPointNormalize(CGPointSubtract(getFirstPoint(edgeB.path), edgeB.start))
//    println("new pointa: \(getFirstPoint(edgeA.path)) \n")
//    println("new pointb: \(getFirstPoint(edgeB.path)) \n")


    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    
    return atan2(det,dot) * CGFloat(180/M_PI) // atan2(y, x) or atan2(sin, cos)
    
    
}
