//
//  Math.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

//copypasta from apple tutorial
import Foundation
import CoreGraphics

func dist(a: CGPoint, b: CGPoint) -> CGFloat{
    
    let xDist = (b.x - a.x)
    let yDist = (b.y - a.y)
    
    return sqrt(square(xDist) + square(yDist))
}

func square(a: CGFloat) -> CGFloat{
    return a * a
}


struct Vector2D  {
    var x: Double = 0.0
    var y: Double = 0.0
    
    
    mutating func add (v: Vector2D) {
        x += v.x
        y += v.y
    }
    
    mutating func mult (m: Double) {
        x *= m
        y *= m
    }
    
    mutating func sub (v: Vector2D) {
        x -= v.x
        y -= v.y
    }
    
    mutating func div (m: Double) {
        if m != 0.0 {
            x /= m
            y /= m
        }
    }
    
    mutating func normalize () {
        let mag = self.mag()
        if mag != 0.0 {
            self.div(mag);
        }
    }
    
    func dist(b: Vector2D) -> Double {
        let diff = self - b
        return diff.mag()
    }
    
    func mag() -> Double {
        return sqrt(x * x + y * y)
    }
    
    mutating func limit(max: Double) {
        let mag = self.mag();
        if mag > 0 {
            x *= max/mag;
            y *= max/mag;
        }
    }
    
    mutating func setMag(v:Double){
        self.normalize()
        self.mult(v)
    }
}

func + (left: Vector2D, right: Vector2D) -> Vector2D {
    return Vector2D(x: left.x + right.x, y: left.y + right.y)
}

func - (left: Vector2D, right: Vector2D) -> Vector2D {
    return Vector2D(x: left.x + right.x, y: left.y + right.y)
}

prefix func - (vector: Vector2D) -> Vector2D {
    return Vector2D(x: -vector.x, y: -vector.y)
}

func += (inout left: Vector2D, right: Vector2D){
    return left = left + right
}

func -= (inout left: Vector2D, right: Vector2D){
    left = left + right
}

func == (lhs: Vector2D, rhs: Vector2D) -> Bool {
    return lhs.x == rhs.x && lhs.y == rhs.y
}

extension Vector2D: Hashable {
    var hashValue: Int { get {
        return 100000 + Int(x) + 10000 + Int(y)
        }
    }
}
extension CGPoint: Hashable {
    public var hashValue: Int { get {
        return 100000 + Int(self.x) + 10000 + Int(self.y)
        }
    }
}


struct Vector3D{
    var x: Double = 0.0
    var y: Double = 0.0
    var z: Double = 0.0

    mutating func add (v: Vector3D) {
        x += v.x
        y += v.y
        z += v.z
    }
    
    mutating func mult (m: Double) {
        x *= m
        y *= m
        z *= m
    }
    
    mutating func sub (v: Vector3D) {
        x -= v.x
        y -= v.y
        z -= v.z

    }
    
    mutating func div (m: Double) {
        if m != 0.0 {
            x /= m
            y /= m
            z /= m

        }
    }
    
    mutating func normalize () {
        let mag = self.mag()
        if mag != 0.0 {
            self.div(mag);
        }
    }
    
    func dist(b: Vector3D) -> Double {
        let diff = self - b
        return diff.mag()
    }
    
    func mag() -> Double {
        return sqrt(x * x + y * y + z*z)
    }
    
    mutating func limit(max: Double) {
        let mag = self.mag();
        if mag > 0 {
            x *= max/mag;
            y *= max/mag;
            z *= max/mag;

        }
    }
    
    mutating func setMag(v:Double){
        self.normalize()
        self.mult(v)
    }
}

func + (left: Vector3D, right: Vector3D) -> Vector3D {
    return Vector3D(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

func - (left: Vector3D, right: Vector3D) -> Vector3D {
    return Vector3D(x: left.x + right.x, y: left.y + right.y, z: left.z + right.z)
}

prefix func - (vector: Vector3D) -> Vector3D {
    return Vector3D(x: -vector.x, y: -vector.y, z: -vector.z)
}

func += (inout left: Vector3D, right: Vector3D){
    return left = left + right
}

func -= (inout left: Vector3D, right: Vector3D){
    left = left + right
}