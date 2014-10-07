//
//  Math.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

//copypasta from apple tutorial
import Foundation

struct Vector2D{
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