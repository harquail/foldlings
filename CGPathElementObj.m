//
//  CGPathElementObj.m
//  foldlings
//
///  a path element object to ease passing this around and pulling these out from the opaque cgpath 
//

#import "CGPathElementObj.h"

@implementation CGPathElementObj


@synthesize type = _type;
@synthesize points = _points;


- (id)initWithType: (CGPathElementType)type points: (NSArray*)points
{
    self = [super init];
    if (self) {
        self.type = type;
        self.points = points;
    }
    return self;
}


@end
