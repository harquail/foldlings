//
//  UIBezierPath+OBAdditions.m
//  foldlings
//
// from http://oleb.net/blog/2012/12/accessing-pretty-printing-cgpath-elements/
//

#import <Foundation/Foundation.h>
#import "UIBezierPath+OBAdditions.h"
#import "CoreGraphics/CoreGraphics.h"
#import "CGPathElementObj.h"


@implementation UIBezierPath (OBAdditions)


- (void)ob_enumerateElementsUsingBlock:(OBUIBezierPathEnumerationHandler)handler
{
    CGPathRef cgPath = self.CGPath;
    void CGPathEnumerationCallback(void *info, const CGPathElement *element);
    CGPathApply(cgPath, (__bridge void *)(handler), CGPathEnumerationCallback);
}

- (NSString *)ob_description
{
    CGPathRef cgPath = self.CGPath;
    CGRect bounds = CGPathGetPathBoundingBox(cgPath);
    CGRect controlPointBounds = CGPathGetBoundingBox(cgPath);
    
    NSMutableString *mutableDescription = [NSMutableString string];
    [mutableDescription appendFormat:@"%@ <%p>\n", [self class], self];
    [mutableDescription appendFormat:@"  Bounds: %@\n", NSStringFromCGRect(bounds)];
    [mutableDescription appendFormat:@"  Control Point Bounds: %@\n", NSStringFromCGRect(controlPointBounds)];
    
    [self ob_enumerateElementsUsingBlock:^(const CGPathElement *element) {
        [mutableDescription appendFormat:@"    %@\n", [self ob_descriptionForPathElement:element]];
    }];
    
    return [mutableDescription copy];
}

- (NSArray*) getPathElements
{
    NSMutableArray* elements = [[NSMutableArray alloc] init];
    
    [self ob_enumerateElementsUsingBlock:^(const CGPathElement *element) {
        
        NSMutableArray* points = [[NSMutableArray alloc] init];
        for (int i = 0; i < sizeof(element->points); i++)
        {
            [points addObject:[NSValue valueWithCGPoint:element->points[i]]];
        }
        CGPathElementObj* pe = [[CGPathElementObj alloc] initWithType:element->type points:points];
        [elements addObject:pe];
    }];
    
    return [elements copy];
    
}

- (NSString *)ob_descriptionForPathElement:(const CGPathElement *)element
{
    NSString *description = nil;
    switch (element->type) {
        case kCGPathElementMoveToPoint: {
            CGPoint point = element ->points[0];
            description = [NSString stringWithFormat:@"%f %f %@", point.x, point.y, @"moveto"];
            break;
        }
        case kCGPathElementAddLineToPoint: {
            CGPoint point = element ->points[0];
            description = [NSString stringWithFormat:@"%f %f %@", point.x, point.y, @"lineto"];
            break;
        }
        case kCGPathElementAddQuadCurveToPoint: {
            CGPoint point1 = element->points[0];
            CGPoint point2 = element->points[1];
            description = [NSString stringWithFormat:@"%f %f %f %f %@", point1.x, point1.y, point2.x, point2.y, @"quadcurveto"];
            break;
        }
        case kCGPathElementAddCurveToPoint: {
            CGPoint point1 = element->points[0];
            CGPoint point2 = element->points[1];
            CGPoint point3 = element->points[2];
            description = [NSString stringWithFormat:@"%f %f %f %f %f %f %@", point1.x, point1.y, point2.x, point2.y, point3.x, point3.y, @"curveto"];
            break;
        }
        case kCGPathElementCloseSubpath: {
            description = @"closepath";
            break;
        }
    }
    return description;
}

@end

void CGPathEnumerationCallback(void *info, const CGPathElement *element)
{
    OBUIBezierPathEnumerationHandler handler = (__bridge OBUIBezierPathEnumerationHandler)(info);
    if (handler) {
        handler(element);
    }
}