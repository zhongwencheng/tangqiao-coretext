//
//  CTDisplayView.m
//  CoreTextDemo
//
//  Created by TangQiao on 13-12-7.
//  Copyright (c) 2013年 TangQiao. All rights reserved.
//

#import "CTDisplayView.h"
#import "CoreTextUtils.h"

NSString *const CTDisplayViewImagePressedNotification = @"CTDisplayViewImagePressedNotification";
NSString *const CTDisplayViewLinkPressedNotification = @"CTDisplayViewLinkPressedNotification";


typedef enum CTDisplayViewState : NSInteger {
    CTDisplayViewStateNormal,       // 普通状态
    CTDisplayViewStateTouching,     // 正在按下，需要弹出放大镜
    CTDisplayViewStateSelecting     // 选中了一些文本，需要弹出复制菜单
}CTDisplayViewState;

#define ANCHOR_TARGET_TAG 1

@interface CTDisplayView()<UIGestureRecognizerDelegate>

@property (nonatomic) NSInteger selectionStartPosition;
@property (nonatomic) NSInteger selectionEndPosition;
@property (nonatomic) CTDisplayViewState state;
@property (strong, nonatomic) UIImageView *leftSelectionAnchor;
@property (strong, nonatomic) UIImageView *rightSelectionAnchor;

@end

@implementation CTDisplayView

- (id)init {
    return [self initWithFrame:CGRectZero];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupEvents];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupEvents];
    }
    return self;
}

- (void)setData:(CoreTextData *)data {
    _data = data;
    self.state = CTDisplayViewStateNormal;
}

- (void)setupAnchors {
    _leftSelectionAnchor = [self createSelectionAnchor];
    _rightSelectionAnchor = [self createSelectionAnchor];
    [self addSubview:_leftSelectionAnchor];
    [self addSubview:_rightSelectionAnchor];
}

- (UIImageView *)createSelectionAnchor {
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"red.png"]];
    imageView.frame = CGRectMake(0, 0, 5, 20);
    return imageView;
}

- (void)setState:(CTDisplayViewState)state {
    if (_state == state) {
        return;
    }
    _state = state;
    if (_state == CTDisplayViewStateNormal) {
        _selectionStartPosition = -1;
        _selectionEndPosition = -1;
        if (_leftSelectionAnchor) {
            [_leftSelectionAnchor removeFromSuperview];
            _leftSelectionAnchor = nil;
        }
        if (_rightSelectionAnchor) {
            [_rightSelectionAnchor removeFromSuperview];
            _rightSelectionAnchor = nil;
        }
    } else if (_state == CTDisplayViewStateTouching) {
        if (_leftSelectionAnchor == nil && _rightSelectionAnchor == nil) {
            [self setupAnchors];
        }
    } else if (_state == CTDisplayViewStateSelecting) {
        if (_leftSelectionAnchor == nil && _rightSelectionAnchor == nil) {
            [self setupAnchors];
        }
    }
    [self setNeedsDisplay];
}

- (void)setupEvents {
    UIGestureRecognizer * tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(userTapGestureDetected:)];
    [self addGestureRecognizer:tapRecognizer];

    UIGestureRecognizer *longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(userLongPressedGuestureDetected:)];
    [self addGestureRecognizer:longPressRecognizer];

    UIGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self
                                                    action:@selector(userPanGuestureDetected:)];
    [self addGestureRecognizer:panRecognizer];

    self.userInteractionEnabled = YES;
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    if (self.data == nil) {
        return;
    }

    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetTextMatrix(context, CGAffineTransformIdentity);
    CGContextTranslateCTM(context, 0, self.bounds.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    if (self.state == CTDisplayViewStateTouching || self.state == CTDisplayViewStateSelecting) {
        [self drawSelectionArea];
        [self drawAnchors];
    }

    CTFrameDraw(self.data.ctFrame, context);
    
    for (CoreTextImageData * imageData in self.data.imageArray) {
        UIImage *image = [UIImage imageNamed:imageData.name];
        if (image) {
            CGContextDrawImage(context, imageData.imagePosition, image.CGImage);
        }
    }
}

- (void)userTapGestureDetected:(UIGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    if (_state == CTDisplayViewStateNormal) {
        for (CoreTextImageData * imageData in self.data.imageArray) {
            // 翻转坐标系，因为imageData中的坐标是CoreText的坐标系
            CGRect imageRect = imageData.imagePosition;
            CGPoint imagePosition = imageRect.origin;
            imagePosition.y = self.bounds.size.height - imageRect.origin.y - imageRect.size.height;
            CGRect rect = CGRectMake(imagePosition.x, imagePosition.y, imageRect.size.width, imageRect.size.height);
            // 检测点击位置 Point 是否在rect之内
            if (CGRectContainsPoint(rect, point)) {
                NSLog(@"hint image");
                // 在这里处理点击后的逻辑
                NSDictionary *userInfo = @{ @"imageData": imageData };
                [[NSNotificationCenter defaultCenter] postNotificationName:CTDisplayViewImagePressedNotification
                                                                    object:self userInfo:userInfo];
                return;
            }
        }
        
        CoreTextLinkData *linkData = [CoreTextUtils touchLinkInView:self atPoint:point data:self.data];
        if (linkData) {
            NSLog(@"hint link!");
            NSDictionary *userInfo = @{ @"linkData": linkData };
            [[NSNotificationCenter defaultCenter] postNotificationName:CTDisplayViewLinkPressedNotification
                                                                object:self userInfo:userInfo];
            return;
        }
    } else {
        self.state = CTDisplayViewStateNormal;
    }
}

- (void)userLongPressedGuestureDetected:(UILongPressGestureRecognizer *)recognizer {
    CGPoint point = [recognizer locationInView:self];
    debugMethod();
    debugLog(@"state = %d", recognizer.state);
    debugLog(@"point = %@", NSStringFromCGPoint(point));
    if (recognizer.state == UIGestureRecognizerStateBegan ||
        recognizer.state == UIGestureRecognizerStateChanged) {
        CFIndex index = [CoreTextUtils touchContentOffsetInView:self atPoint:point data:self.data];
        if (index != -1 && index < self.data.content.length) {
            _selectionStartPosition = index;
            _selectionEndPosition = index + 3;
        }
        self.state = CTDisplayViewStateTouching;
    } else {
        if (_selectionStartPosition >= 0 && _selectionEndPosition <= self.data.content.length) {
            self.state = CTDisplayViewStateSelecting;
        } else {
            self.state = CTDisplayViewStateNormal;
        }
    }
}

- (void)userPanGuestureDetected:(UIGestureRecognizer *)recognizer {
    if (self.state == CTDisplayViewStateNormal) {
        return;
    }
    CGPoint point = [recognizer locationInView:self];
    if (recognizer.state == UIGestureRecognizerStateBegan) {
        if (_leftSelectionAnchor && CGRectContainsPoint(CGRectInset(_leftSelectionAnchor.frame, -20, -10), point)) {
            debugLog(@"try to move left anchor");
            _leftSelectionAnchor.tag = ANCHOR_TARGET_TAG;
        } else if (_rightSelectionAnchor && CGRectContainsPoint(CGRectInset(_rightSelectionAnchor.frame, -20, -10), point)) {
            debugLog(@"try to move right anchor");
            _rightSelectionAnchor.tag = ANCHOR_TARGET_TAG;
        }
    } else if (recognizer.state == UIGestureRecognizerStateChanged) {
        CFIndex index = [CoreTextUtils touchContentOffsetInView:self atPoint:point data:self.data];
        if (index == -1) {
            return;
        }
        if (_leftSelectionAnchor.tag == ANCHOR_TARGET_TAG && index < _selectionEndPosition) {
            debugLog(@"change start position to %ld", index);
            _selectionStartPosition = index;
        } else if (_rightSelectionAnchor.tag == ANCHOR_TARGET_TAG && index > _selectionStartPosition) {
            debugLog(@"change end position to %ld", index);
            _selectionEndPosition = index;
        }

    } else if (recognizer.state == UIGestureRecognizerStateEnded ||
               recognizer.state == UIGestureRecognizerStateCancelled) {
        debugLog(@"end move");
        _leftSelectionAnchor.tag = 0;
        _rightSelectionAnchor.tag = 0;
    }
    [self setNeedsDisplay];
}

- (void)drawAnchors {
    if (_selectionStartPosition < 0 || _selectionEndPosition > self.data.content.length) {
        return;
    }
    CTFrameRef textFrame = self.data.ctFrame;
    CFArrayRef lines = CTFrameGetLines(self.data.ctFrame);
    if (!lines) {
        return;
    }

    // 翻转坐标系
    CGAffineTransform transform =  CGAffineTransformMakeTranslation(0, self.bounds.size.height);
    transform = CGAffineTransformScale(transform, 1.f, -1.f);

    CFIndex count = CFArrayGetCount(lines);
    // 获得每一行的origin坐标
    CGPoint origins[count];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), origins);
    for (int i = 0; i < count; i++) {
        CGPoint linePoint = origins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange range = CTLineGetStringRange(line);

        if ([self isPosition:_selectionStartPosition inRange:range]) {
            CGFloat ascent, descent, leading, offset;
            offset = CTLineGetOffsetForStringIndex(line, _selectionStartPosition, NULL);
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGPoint origin = CGPointMake(linePoint.x + offset, linePoint.y + ascent);
            origin = CGPointApplyAffineTransform(origin, transform);
            _leftSelectionAnchor.origin = origin;
        }
        if ([self isPosition:_selectionEndPosition inRange:range]) {
            CGFloat ascent, descent, leading, offset;
            offset = CTLineGetOffsetForStringIndex(line, _selectionEndPosition, NULL);
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGPoint origin = CGPointMake(linePoint.x + offset, linePoint.y + ascent);
            origin = CGPointApplyAffineTransform(origin, transform);
            _rightSelectionAnchor.origin = origin;
            break;
        }
    }
}

- (void)drawSelectionArea {
    if (_selectionStartPosition < 0 || _selectionEndPosition > self.data.content.length) {
        return;
    }
    CTFrameRef textFrame = self.data.ctFrame;
    CFArrayRef lines = CTFrameGetLines(self.data.ctFrame);
    if (!lines) {
        return;
    }
    CFIndex count = CFArrayGetCount(lines);
    // 获得每一行的origin坐标
    CGPoint origins[count];
    CTFrameGetLineOrigins(textFrame, CFRangeMake(0,0), origins);
    for (int i = 0; i < count; i++) {
        CGPoint linePoint = origins[i];
        CTLineRef line = CFArrayGetValueAtIndex(lines, i);
        CFRange range = CTLineGetStringRange(line);
        // 1. start和end在一个line,则直接弄完break
        if ([self isPosition:_selectionStartPosition inRange:range] && [self isPosition:_selectionEndPosition inRange:range]) {
            CGFloat ascent, descent, leading, offset, offset2;
            offset = CTLineGetOffsetForStringIndex(line, _selectionStartPosition, NULL);
            offset2 = CTLineGetOffsetForStringIndex(line, _selectionEndPosition, NULL);
            CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGRect lineRect = CGRectMake(linePoint.x + offset, linePoint.y - descent, offset2 - offset, ascent + descent);
            [self fillSelectionAreaInRect:lineRect];
            break;
        }

        // 2. start和end不在一个line
        // 2.1 如果start在line中，则填充Start后面部分区域
        if ([self isPosition:_selectionStartPosition inRange:range]) {
            CGFloat ascent, descent, leading, width, offset;
            offset = CTLineGetOffsetForStringIndex(line, _selectionStartPosition, NULL);
            width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGRect lineRect = CGRectMake(linePoint.x + offset, linePoint.y - descent, width - offset, ascent + descent);
            [self fillSelectionAreaInRect:lineRect];
        } // 2.2 如果 start在line前，end在line后，则填充整个区域
        else if (_selectionStartPosition < range.location && _selectionEndPosition >= range.location + range.length) {
            CGFloat ascent, descent, leading, width;
            width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGRect lineRect = CGRectMake(linePoint.x, linePoint.y - descent, width, ascent + descent);
            [self fillSelectionAreaInRect:lineRect];
        } // 2.3 如果start在line前，end在line中，则填充end前面的区域,break
        else if (_selectionStartPosition < range.location && [self isPosition:_selectionEndPosition inRange:range]) {
            CGFloat ascent, descent, leading, width, offset;
            offset = CTLineGetOffsetForStringIndex(line, _selectionEndPosition, NULL);
            width = CTLineGetTypographicBounds(line, &ascent, &descent, &leading);
            CGRect lineRect = CGRectMake(linePoint.x, linePoint.y - descent, offset, ascent + descent);
            [self fillSelectionAreaInRect:lineRect];
        }
    }
}

- (BOOL)isPosition:(NSInteger)position inRange:(CFRange)range {
    if (position >= range.location && position < range.location + range.length) {
        return YES;
    } else {
        return NO;
    }
}

- (void)fillSelectionAreaInRect:(CGRect)rect {
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetFillColorWithColor(context, [[UIColor blueColor] CGColor]);
    CGContextFillRect(context, rect);
}

@end
