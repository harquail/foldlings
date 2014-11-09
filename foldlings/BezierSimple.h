//
//  Bezier+Additions.h
//  foldlings
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface BezierSimple : NSObject

+ (float)findDistance:(CGPoint)point lineA:(CGPoint)lineA lineB:(CGPoint)lineB;
+ (NSArray *)douglasPeucker:(NSArray *)points epsilon:(float)epsilon;
+ (NSArray *)catmullRomSplineAlgorithmOnPoints:(NSArray *)points segments:(int)segments;

@end
