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
    
    // CGPoint - CGPoint
    let a = CGPointNormalize(CGPointSubtract(edgeA.end, edgeA.start) )//this is current
    let b = CGPointNormalize(CGPointSubtract(edgeB.end, edgeB.start) )// this one is being evaluated wrt edgeA
    
//    let x1 = a.x
//    let x2 = b.x
//    let y1 = a.y
//    let y2 = b.y
    
    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    //solution #1
    var angle = atan2(det,dot) * CGFloat(180/M_PI) // atan2(y, x) or atan2(sin, cos)

    if angle < 0{
        angle = angle + 360
    }
    return angle

    //solution #2 -bad
//    let angleRad = acos( (a.x * b.x + a.y * b.y) / ( sqrt(a.x*a.x + a.y*a.y) * sqrt(b.x*b.x + b.y*b.y) ) )
//    return angleRad * CGFloat(180/M_PI);
    
    
}
//solution #3 - compare y-values
//finds the leftmost point between two points for and edge
func isLeftmost(next: Edge, closest: Edge, current: Edge)->Bool{
    let close_controlpt = findControlPoint(closest.path)//get nearest control point
    let next_controlpt = findControlPoint(next.path)
    
    let a = CGPointNormalize(CGPointSubtract(close_controlpt, current.start) )//this is current
    let b = CGPointNormalize(CGPointSubtract(next_controlpt, current.start) )// this one is being evaluated wrt edgeA
    // check the x-values and then compare y-values
    // abs values for x-values and check y-values
    
    // dot them twice
    // get orthogonal from vector
    // switch x and y then make x negative
    // let ortho = 
    // let dot = a.x*b.x + a.y*b.y //  dot product
    
    // let dotortho = ortho.x*b.x + ortho.y*b.y //  dot product
    // add them together?
    
    
    // call getAngle twice 
    let a1 = getAngle(closest, current)
    let a2 = getAngle(next, current)


    
    return false
}

