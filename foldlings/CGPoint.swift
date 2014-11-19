//
//  CGPoint.swift
//  foldlings
//
//  Created by nook on 11/19/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

import Foundation

extension CGPoint: Hashable {
    public var hashValue: Int { get {
        //        return 100000 + Int(self.x*1000) + 10000 + Int(self.y*1000)
        return "\(self.x),\(self.y)".hashValue
        }
    }
}