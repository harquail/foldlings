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
- ob_descriptionForPathElement:(const CGPathElement *)element;
- (NSArray*) getPathElements;
- (CGRect) boundsForPath;

@end


#endif
