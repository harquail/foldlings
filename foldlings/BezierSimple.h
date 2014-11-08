//
//  Bezier+Additions.h
//  foldlings
//
//  Created by Tim Tregubov on 11/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BezierSimple : NSObject

+ (float)findDistance:(CGPoint)point lineA:(CGPoint)lineA lineB:(CGPoint)lineB;
+ (NSArray *)douglasPeucker:(NSArray *)points epsilon:(float)epsilon;
+ (NSArray *)catmullRomSplineAlgorithmOnPoints:(NSArray *)points segments:(int)segments;

@end
