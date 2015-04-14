//
//  UIBezierPath+OBAdditions.h
//  foldlings
//
//

#ifndef foldlings_UIBezierPath_OBAdditions_h
#define foldlings_UIBezierPath_OBAdditions_h

#import <UIKit/UIKit.h>

typedef void(^OBUIBezierPathEnumerationHandler)(const CGPathElement *element);

@interface UIBezierPath (OBAdditions)

- (void)ob_enumerateElementsUsingBlock:(OBUIBezierPathEnumerationHandler)handler;
- (NSString *)ob_description;
- (NSArray*) getPathElements;
- (CGRect) boundsForPath;

@end


#endif
