//
//  FoldFeature.swift
//  foldlings
//
//  Created by nook on 2/20/15.
//  Copyright (c) 2015 nook. All rights reserved.
//

import Foundation

class FoldFeature{
    
    enum Type {
        case Box,
         Mirrored,
         FreeForm,
         VFold,
         Track,
         Slider
    }
    
    enum ValidityState {
        case Invalid,
        Fixable,
        Valid
    }
    
    var Planes:[Plane] = [];
    var HorizontalFolds:[Edge] = [];
    var Parent:FoldFeature?;
    var boundingBox:CGRect?;
    
}