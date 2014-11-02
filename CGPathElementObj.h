//
//  CGPathElementObj.h
//  foldlings
//
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>

@interface CGPathElementObj : NSObject

- (id)initWithType: (CGPathElementType)type points: (NSArray*)points;
@property CGPathElementType type;
@property NSArray* points;


@end
