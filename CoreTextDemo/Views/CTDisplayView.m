//
//  CTDisplayView.m
//  CoreTextDemo
//
//  Created by TangQiao on 13-12-7.
//  Copyright (c) 2013年 TangQiao. All rights reserved.
//

#import "CTDisplayView.h"
#import "CoreText/CoreText.h"

@implementation CTDisplayView

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathAddRect(path, NULL, self.bounds);
    
    NSAttributedString *attString = [[NSAttributedString alloc] initWithString:@"Hello World!"];
    CTFramesetterRef framesetter =
    CTFramesetterCreateWithAttributedString((CFAttributedStringRef)attString);
    CTFrameRef frame =
    CTFramesetterCreateFrame(framesetter,
                             CFRangeMake(0, [attString length]), path, NULL);
    
    CTFrameDraw(frame, context);
    
    CFRelease(frame);
    CFRelease(path);
    CFRelease(framesetter);
}

@end
