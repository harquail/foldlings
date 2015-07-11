////
////  Math.swift
// foldlings
//
// Copyright (c) 2014-2015 Marissa Allen, Nook Harquail, Tim Tregubov
// All Rights Reserved


func square(a: CGFloat) -> CGFloat{
    return a * a
}

/// get the angle between two edges
func getAngle(edgeA: Edge, edgeB: Edge) -> CGFloat{
    
    var centroidA:CGPoint
    var centroidB:CGPoint
    
    //since folds are always straight lines, their centroid is just their center 
    if(edgeA.kind == .Fold){
        centroidA = edgeA.centerOfStraightEdge() //edge midpoint
    }
    else{
        centroidA = findCentroid(edgeA.path)
    }
    
    if(edgeB.kind == .Fold){
        centroidB = edgeB.centerOfStraightEdge() //edge midpoint
    }
    else{
        centroidB = findCentroid(edgeB.path)
    }
    
    // get the centroid and create the vector
    var a = CGPointSubtract(centroidA, edgeA.start)
    var b = CGPointSubtract(centroidB, edgeB.start)

    let dot = a.x*b.x + a.y*b.y //  dot product
    let det = a.x*b.y - a.y*b.x // determinant
    
    var angle = atan2(det,dot) * CGFloat(180.0 / M_PI) // atan2(y, x) or atan2(sin, cos)
    if ( abs(angle) < 0.000000000000001) { return 0.0 }
    
    return angle
    
}

//func angleBetweenStraight() -> CGFloat

// returns the average of two CGFloats
func makeMid(a:CGFloat, b:CGFloat) -> CGFloat{
    return CGFloat((a + b)/2.0)
}


// rounds a cgpoint
 func round(point:CGPoint) -> CGPoint{
//    round to the nearest 0.5
    return CGPointMake(round(point.x * 2)/2, round(point.y * 2)/2)
}

func degToRad(x:CGFloat) -> CGFloat{
    return x * (CGFloat(M_PI) / CGFloat(180))
}