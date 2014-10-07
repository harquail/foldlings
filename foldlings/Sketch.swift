//
//  Sketch.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

//a sketch is a collection of cuts & folds
import Foundation
import CoreGraphics

class Sketch {
    
    let MINIMUM_LINE_DISTANCE = 0.5
    
    //the folds that define a sketch
    //for now, cuts are in this array too
    var folds : [Fold] = []
    
    
    func addFold(start:CGPoint,end:CGPoint){
        folds += [Fold(start: start, end: end)]
    }
    
    //fold neares to point
    func foldNearPoint(point:CGPoint)->Fold{
        
        var smallestDist = Float.infinity
        var nearestFold = Fold(start: CGPointZero, end: CGPointZero)
        
        
        
        //find the fold with the smallest distance to the given point
        for fold in folds{
            let currentDist = distanceBetween(point, startLine: fold.start, endLine: fold.end)
            if(currentDist<smallestDist){
                nearestFold=fold
                smallestDist = currentDist
            }
            
        }
        
        return nearestFold
    }
    
    //distance between a point and line
    private func distanceBetween(point:CGPoint,startLine:CGPoint, endLine:CGPoint) -> Float{
        //#TODO
        return 0.5
    }
//    func changeFoldOrientationTo(var fold:Fold,orientation:FoldOrientation){
//        fold.orientation=orientation
//    }
}

