//
//  SVGRenderer.m
//  SVGgh
// The MIT License (MIT)

//  Copyright (c) 2011-2014 Glenn R. Howes

//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//
//  Created by Glenn Howes on 1/12/11.

#import "SVGRenderer.h"
#import "GHText.h"
#import "GHGradient.h"
#import "NSData+Base64Additions.h"
#import "SVGPathGenerator.h"
#import "SVGUtilities.h"
#import "SVGTextUtilities.h"

@class GHShapeGroup;
@interface SVGRenderer()

@property (strong, nonatomic, retain)	NSMutableDictionary*	colorMap;
@property (strong, nonatomic, retain)   NSDictionary*   namedObjects;
@property (strong, nonatomic, retain)   UIColor* currentColor;
@property (strong, nonatomic, retain)   NSString* isoLanguage;
@property (strong, nonatomic, readonly) GHShapeGroup*		contents;
+(NSDictionary*) defaultAttributes;
@end


@implementation SVGRenderer
@synthesize	transform=_transform;
@synthesize contents=_contents;

+(NSOperationQueue*) rendererQueue
{
    static  NSOperationQueue* sResult = nil;
    static dispatch_once_t  done;
    dispatch_once(&done, ^{
        sResult = [[NSOperationQueue alloc] init];
        sResult.name = @"SVGRenderer Queue";
    });
    return sResult;
}

+(NSDictionary*) defaultAttributes
{
	NSDictionary* result = DefaultSVGDrawingAttributes();
	return result;
}

-(id) initWithString:(NSString *)utf8String
{
    if(nil != (self = [super initWithString:utf8String]))
    {
		_colorMap = [[NSMutableDictionary alloc] init];
        
        CFArrayRef langs = CFLocaleCopyPreferredLanguages();
        CFStringRef langCode = CFArrayGetValueAtIndex (langs, 0);
        _isoLanguage = [[NSString stringWithString:(__bridge NSString*)langCode] substringToIndex:2];
        CFRelease(langs);
	}
	return self;
}

- (id)initWithContentsOfURL:(NSURL *)url
{
	if(nil != (self = [super initWithContentsOfURL:url]))
    {
		_colorMap = [[NSMutableDictionary alloc] init];
        
        CFArrayRef langs = CFLocaleCopyPreferredLanguages();
        CFStringRef langCode = CFArrayGetValueAtIndex (langs, 0);
        _isoLanguage = [[NSString stringWithString:(__bridge NSString*)langCode] substringToIndex:2];
        CFRelease(langs);
	}
	return self;
}

-(BOOL) hidden
{
    BOOL result = self.contents.hidden;
    return result;
}

-(CGFloat)explicitLineScaling
{
    return 1.0;
}

-(NSDictionary*) attributes
{
	NSDictionary* result = self.contents.attributes;
	return result;
}

-(GHShapeGroup*) contents
{
	if(_contents == nil && self.parserError == nil)
	{
		_contents = [[GHShapeGroup alloc] initWithDictionary:self.root];
	}
	return _contents;
}

-(NSDictionary*) namedObjects
{
    if(_namedObjects == nil)
    {
        GHShapeGroup* myContents = self.contents;
        if(myContents != nil)
        {
            NSMutableDictionary* mutableResult = [[NSMutableDictionary alloc] init];
            [myContents addNamedObjects:mutableResult];
            _namedObjects = [mutableResult copy];
        }
    }
    return _namedObjects;
}

-(void) setCurrentColor:(UIColor *)currentColor
{
    _currentColor = currentColor;
}

-(UIColor*) colorForSVGColorString:(NSString*)colorString
{
	UIColor* result = nil;
    if([colorString isEqualToString:@"currentColor"])
    {
        result = self.currentColor;
    }
    else
    {
        result = [self.colorMap objectForKey:colorString];
        if(result == nil)
        {
            result = UIColorFromSVGColorString (colorString);
            
            if(result != nil)
            {
                [self.colorMap setObject:result forKey:colorString];
            }
        }
    }
	return result;
}
				  
-(CGRect) viewRect
{
	CGRect	result = CGRectZero;
	NSString*	viewBoxString = [self.attributes objectForKey:@"viewBox"];
	NSString* viewWidth = [self.attributes objectForKey:@"width"];
	NSString* viewHeight = [self.attributes objectForKey:@"height"];
	if(([viewWidth length] > 0 && [viewWidth doubleValue] <= 0)
	   || ([viewHeight length] > 0 && [viewHeight doubleValue] <= 0))
	{
	}
	else if([viewBoxString length])
	{
		result  = SVGStringToRect(viewBoxString);
	}
	else 
	{
		if([viewWidth length] && [viewHeight length])
		{
			result = CGRectMake(0, 0, [viewWidth floatValue], [viewHeight floatValue]);
		}
	}
	return result;
}

-(id) objectAtURL:(NSString*)aLocation
{
    id  result = nil;
    if(IsStringURL(aLocation))
    {
        NSString*   theURL = ExtractURLContents(aLocation);
        if([theURL hasPrefix:@"#"])
        {
            NSString* localReference = [theURL substringFromIndex:1];
            result = [self objectNamed:localReference];
        }
    }
    return result;
}

-(id)       objectNamed:(NSString*)objectName
{
    id result = [self.namedObjects objectForKey:objectName];
    return result;
}

-(void) renderIntoContext:(CGContextRef)quartzContext
{
	CGContextSetRenderingIntent(quartzContext, kColoringRenderingIntent);
	CGContextSetInterpolationQuality(quartzContext, kCGInterpolationHigh);
    [self renderIntoContext:quartzContext withSVGContext:self];
}

-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint
{
	id<GHRenderable> result = [self.contents findRenderableObject:testPoint withSVGContext:self];
	return result;
}


-(void) renderIntoContext:(CGContextRef)quartzContext withSVGContext:(id<SVGContext>)svgContext
{
	NSDictionary* defaultAttributes = [SVGRenderer defaultAttributes];
	[GHRenderableObject	setupContext:quartzContext withAttributes:defaultAttributes  withSVGContext:svgContext];
	
	[self.contents renderIntoContext:quartzContext  withSVGContext:self];
}
-(id<GHRenderable>) findRenderableObject:(CGPoint)testPoint withSVGContext:(id<SVGContext>)svgContext
{
	id<GHRenderable> result = [self.contents findRenderableObject:testPoint withSVGContext:svgContext];
	return result;
}
-(void) addToClipForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    [self addToClipForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}
-(void) addToClipPathForContext:(CGContextRef)quartzContext  withSVGContext:(id<SVGContext>)svgContext objectBoundingBox:(CGRect) objectBox
{
    [self.contents addToClipPathForContext:quartzContext withSVGContext:svgContext objectBoundingBox:objectBox];
}
-(ClippingType) getClippingTypeWithSVGContext:(id<SVGContext>)svgContext
{
    ClippingType result = [self.contents getClippingTypeWithSVGContext:svgContext];
    return result;
}

-(CGRect) getBoundingBoxWithSVGContext:(id<SVGContext>)svgContext
{
    CGRect  result = [self viewRect];
    return result;
}

@end

