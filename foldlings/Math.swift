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
    
//returns random angle instead of real one
//    return CGFloat(arc4random_uniform(UInt32.max))/CGFloat(UInt32.max) * CGFloat(M_PI) * 2.0
    
    let a = CGPointNormalize(CGPointSubtract(edgeA.end, edgeA.start) )// CGPoint - CGPoint
    let b = CGPointNormalize(CGPointSubtract(edgeB.end, edgeB.start) )
    
//    let x1 = a.x
//    let x2 = b.x
//    let y1 = a.y
//    let y2 = b.y
    
    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    //solution #1
    return atan2(det,dot) * CGFloat(180/M_PI) // atan2(y, x) or atan2(sin, cos)

    //solution #2 -bad
//    let angleRad = acos( (a.x * b.x + a.y * b.y) / ( sqrt(a.x*a.x + a.y*a.y) * sqrt(b.x*b.x + b.y*b.y) ) )
//    return angleRad * CGFloat(180/M_PI);
    
    //solution #3 - compare y-values
    

    
}

