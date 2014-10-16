//
//  Fold.swift
//  foldlings
//
//  Created by nook on 10/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation
import CoreGraphics
import UIKit

//the direction of the fold.  For now, cuts are considered a type of fold -- will have to reconsider later
enum FoldOrientation{
    case Hill
    case Valley
    case Cut
}

//for now, only straight folds/cuts
struct Fold {
    var start: CGPoint
    var end: CGPoint
    var path = UIBezierPath()
    var orientation = FoldOrientation.Hill
    
    init(start:CGPoint,end:CGPoint) {
        self.start = start
        self.end = end
    }
}