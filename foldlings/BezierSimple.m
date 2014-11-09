//
//  Bezier+Additions.m
//  foldlings
//
//  Created by Tim Tregubov on 11/7/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

#import "BezierSimple.h"
#import "CGPoint+Vector.h"

@implementation BezierSimple

+ (float)findDistance:(CGPoint)point lineA:(CGPoint)lineA lineB:(CGPoint)lineB
{
    if ( CGPointEqualToPoint(lineA, lineB) ) { return CGPointGetDistance(point, lineA); }
    
    CGPoint v1 = CGPointMake(lineB.x - lineA.x, lineB.y - lineA.y);
    CGPoint v2 = CGPointMake(point.x - lineA.x, point.y - lineA.y);
    float lenV1 = sqrt(v1.x * v1.x + v1.y * v1.y);
    float lenV2 = sqrt(v2.x * v2.x + v2.y * v2.y);
    float angle = acos((v1.x * v2.x + v1.y * v2.y) / (lenV1 * lenV2));
    return sin(angle) * lenV2;
}

//runs the douglas peucker algorithm to simplify the curves
// if closed shape it does *not* smooth the startpoint
+ (NSArray *)douglasPeucker:(NSArray *)points epsilon:(float)epsilon
{
    int count = (int)[points count];
    if(count < 3) {
        return points;
    }
    
    //Find the point with the maximum distance
    float dmax = 0;
    int index = 0;
    for(int i = 1; i < count - 1; i++) {
        CGPoint point = [[points objectAtIndex:i] CGPointValue];
        CGPoint lineA = [[points objectAtIndex:0] CGPointValue];
        CGPoint lineB = [[points objectAtIndex:count - 1] CGPointValue];
        float d = [self findDistance:point lineA:lineA lineB:lineB];
        if(d > dmax) {
            index = i;
            dmax = d;
        }
    }
    
    //If max distance is greater than epsilon, recursively simplify
    NSArray *resultList;
    int recurseCount = 0;
    if(dmax > epsilon) {
        NSArray *recResults1 = [self douglasPeucker:[points subarrayWithRange:NSMakeRange(0, index + 1)] epsilon:epsilon];
        
        NSArray *recResults2 = [self douglasPeucker:[points subarrayWithRange:NSMakeRange(index, count - index)] epsilon:epsilon];
        
        NSMutableArray *tmpList = [NSMutableArray arrayWithArray:recResults1];
        [tmpList removeLastObject];
        [tmpList addObjectsFromArray:recResults2];
        resultList = tmpList;
        recurseCount++;
    } else {
        resultList = [NSArray arrayWithObjects:[points objectAtIndex:0], [points objectAtIndex:count - 1],nil];
    }
    
    NSLog(@"recurse: %d, dmax: %f", recurseCount, dmax);
    return resultList;
}

+ (NSArray *)catmullRomSplineAlgorithmOnPoints:(NSArray *)points segments:(int)segments
{
    int count = (int)[points count];
    if(count < 4) {
        return points;
    }
    
    float b[segments][4];
    {
        // precompute interpolation parameters
        float t = 0.0f;
        float dt = 1.0f/(float)segments;
        for (int i = 0; i < segments; i++, t+=dt) {
            float tt = t*t;
            float ttt = tt * t;
            b[i][0] = 0.5f * (-ttt + 2.0f*tt - t);
            b[i][1] = 0.5f * (3.0f*ttt -5.0f*tt +2.0f);
            b[i][2] = 0.5f * (-3.0f*ttt + 4.0f*tt + t);
            b[i][3] = 0.5f * (ttt - tt);
        }
    }
    
    NSMutableArray *resultArray = [NSMutableArray array];
    
    {
        int i = 0; // first control point
        [resultArray addObject:[points objectAtIndex:0]];
        for (int j = 1; j < segments; j++) {
            CGPoint pointI = [[points objectAtIndex:i] CGPointValue];
            CGPoint pointIp1 = [[points objectAtIndex:(i + 1)] CGPointValue];
            CGPoint pointIp2 = [[points objectAtIndex:(i + 2)] CGPointValue];
            float px = (b[j][0]+b[j][1])*pointI.x + b[j][2]*pointIp1.x + b[j][3]*pointIp2.x;
            float py = (b[j][0]+b[j][1])*pointI.y + b[j][2]*pointIp1.y + b[j][3]*pointIp2.y;
            [resultArray addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
        }
    }
    
    for (int i = 1; i < count-2; i++) {
        // the first interpolated point is always the original control point
        [resultArray addObject:[points objectAtIndex:i]];
        for (int j = 1; j < segments; j++) {
            CGPoint pointIm1 = [[points objectAtIndex:(i - 1)] CGPointValue];
            CGPoint pointI = [[points objectAtIndex:i] CGPointValue];
            CGPoint pointIp1 = [[points objectAtIndex:(i + 1)] CGPointValue];
            CGPoint pointIp2 = [[points objectAtIndex:(i + 2)] CGPointValue];
            float px = b[j][0]*pointIm1.x + b[j][1]*pointI.x + b[j][2]*pointIp1.x + b[j][3]*pointIp2.x;
            float py = b[j][0]*pointIm1.y + b[j][1]*pointI.y + b[j][2]*pointIp1.y + b[j][3]*pointIp2.y;
            [resultArray addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
        }
    }
    
    {
        int i = count-2; // second to last control point
        [resultArray addObject:[points objectAtIndex:i]];
        for (int j = 1; j < segments; j++) {
            CGPoint pointIm1 = [[points objectAtIndex:(i - 1)] CGPointValue];
            CGPoint pointI = [[points objectAtIndex:i] CGPointValue];
            CGPoint pointIp1 = [[points objectAtIndex:(i + 1)] CGPointValue];
            float px = b[j][0]*pointIm1.x + b[j][1]*pointI.x + (b[j][2]+b[j][3])*pointIp1.x;
            float py = b[j][0]*pointIm1.y + b[j][1]*pointI.y + (b[j][2]+b[j][3])*pointIp1.y;
            [resultArray addObject:[NSValue valueWithCGPoint:CGPointMake(px, py)]];
        }
    }
    // the very last interpolated point is the last control point
    [resultArray addObject:[points objectAtIndex:(count - 1)]];
    
    return resultArray;
}


@end
