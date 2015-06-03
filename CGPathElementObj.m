//
//  CGPathElementObj.m
//  foldlings
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
