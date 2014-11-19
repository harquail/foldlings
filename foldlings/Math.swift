////
////  Math.swift
////  foldlings
////
////
//
////copypasta from apple tutorial
//import Foundation
//import CoreGraphics
//
//func dist(a: CGPoint, b: CGPoint) -> CGFloat{
//    
//    let xDist = (b.x - a.x)
//    let yDist = (b.y - a.y)
//    
//    return sqrt(square(xDist) + square(yDist))
//}
//
func square(a: CGFloat) -> CGFloat{
    return a * a
}
//
//
func getAngle(edgeA: Edge, edgeB: Edge) ->CGFloat{
    
    let a = CGPointNormalize(CGPointSubtract(edgeA.end, edgeA.start) )// CGPoint - CGPoint
    let b = CGPointNormalize(CGPointSubtract(edgeB.end, edgeB.start) )
    
    let x1 = a.x
    let x2 = b.x
    let y1 = a.y
    let y2 = b.y
    
    let dot = x1*x2 + y1*y2 //  dot product
    let det = x1*y2 - y1*x2 // determinant
    
    return atan2(det,dot) * CGFloat(180/M_PI) // atan2(y, x) or atan2(sin, cos)
}

//struct Vector2D  {
//    var x: Double = 0.0
//    var y: Double = 0.0
//    
//    
//    mutating func add (v: Vector2D) {
//        x += v.x
//        y += v.y
//    }
//    
//    mutating func mult (m: Double) {
//        x *= m
//        y *= m
//    }
//    
//    mutating func sub (v: Vector2D) {
//        x -= v.x
//        y -= v.y
//    }
//    
//    mutating func div (m: Double) {
//        if m != 0.0 {
//            x /= m
//            y /= m
//        }
//    }
//    
//    mutating func normalize () {
//        let mag = self.mag()
//        if mag != 0.0 {
//            self.div(mag);
//        }
//    }
//    
//    func dist(b: Vector2D) -> Double {
//        let diff = self - b
//        return diff.mag()
//    }
//    
//    func mag() -> Double {
//        return sqrt(x * x + y * y)
//    }
//    
//    mutating func limit(max: Double) {
//        let mag = self.mag();
//        if mag > 0 {
//            x *= max/mag;
//            y *= max/mag;
//        }
//    }
//    
//    mutating func setMag(v:Double){
//        self.normalize()
//        self.mult(v)
//    }
//}
//
//func + (left: Vector2D, right: Vector2D) -> Vector2D {
//    return Vector2D(x: left.x + right.x, y: left.y + right.y)
//}
//
//func - (left: Vector2D, right: Vector2D) -> Vector2D {
//    return Vector2D(x: left.x + right.x, y: left.y + right.y)
//}
//
//prefix func - (vector: Vector2D) -> Vector2D {
//    return Vector2D(x: -vector.x, y: -vector.y)
//}
//
//func += (inout left: Vector2D, right: Vector2D){
//    return left = left + right
//}
//
//func -= (inout left: Vector2D, right: Vector2D){
//    left = left + right
//}
//
//func == (lhs: Vector2D, rhs: Vector2D) -> Bool {
//    return lhs.x == rhs.x && lhs.y == rhs.y
//}
//
//extension Vector2D: Hashable {
//    var hashValue: Int { get {
//        return 100000 + Int(x) + 10000 + Int(y)
//        }
//    }
//}

//
//
//struct Vector3D{
//    var x: Double = 0.0
//    var y: Double = 0.0
//    var z: Double = 0.0
//
//    mutating func add (v: Vector3D) {
//        x += v.x
//        y += v.y
//        z += v.z
//    }
//    
//    mutating func mult (m: Double) {
//        x *= m
//        y *= m
//        z *= m
//    }
//    
//    mutating func sub (v: Vector3D) {
//        x -= v.x
//        y -= v.y
//        z -= v.z
//
//    }
//    
//    mutating func div (m: Double) {
//        if m != 0.0 {
//            x /= m
//            y /= m
//            z /= m
//
//        }
//    }
//    
//    mutating func normalize () {
//        let mag = self.mag()
//        if mag != 0.0 {
//            self.div(mag);
//        }
//    }
//    
//    func dist(b: Vector3D) -> Double {
//        let diff = self - b
//        return diff.mag()
//    }
//    
//    func mag() -> Double {
//        return sqrt(x * x + y * y + z*z)
//    }
//    
//    mutating func limit(max: Double) {
//        let mag = self.mag();
//        if mag > 0 {
//            x *= max/mag;
//            y *= max/mag;
//            z *= max/mag;
//
//        }
//    }
//    
//    mutating func setMag(v:Double){
//        self.normalize()
//        self.mult(v)
//    }
//}
//
//func + (left: Vector3D, right: Vector3D) -> Vector3D {
//    return Vector3D(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
//}
//
//func - (left: Vector3D, right: Vector3D) -> Vector3D {
//    return Vector3D(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
//}
//
//prefix func - (vector: Vector3D) -> Vector3D {
//    return Vector3D(x: -vector.x, y: -vector.y, z: -vector.z)
//}
//
//func += (inout left: Vector3D, right: Vector3D){
//    return left = left + right
//}
//
//func -= (inout left: Vector3D, right: Vector3D){
//    left = left + right
//}
//
//
//
