//
//  UIBezierPath+OBAdditions.h
//  foldlings
//
//  Created by Tim Tregubov on 11/1/14.
//  Copyright (c) 2014 nook. All rights reserved.
//

#ifndef foldlings_UIBezierPath_OBAdditions_h
#define foldlings_UIBezierPath_OBAdditions_h

#import <UIKit/UIKit.h>

typedef void(^OBUIBezierPathEnumerationHandler)(const CGPathElement *element);

@interface UIBezierPath (OBAdditions)

- (void)ob_enumerateElementsUsingBlock:(OBUIBezierPathEnumerationHandler)handler;
- (NSString *)ob_description;
- (NSArray*) getPathElements;

@end


#endif
