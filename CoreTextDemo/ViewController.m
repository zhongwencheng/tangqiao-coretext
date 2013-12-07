//
//  ViewController.m
//  CoreTextDemo
//
//  Created by TangQiao on 13-12-3.
//  Copyright (c) 2013年 TangQiao. All rights reserved.
//

#import "ViewController.h"
#import "CTDisplayView.h"
#import "CTFrameParser.h"
#import "CTFrameParserConfig.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet CTDisplayView *ctView;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CTFrameParserConfig *config = [[CTFrameParserConfig alloc] init];
    config.width = self.ctView.width;
    config.textColor = [UIColor blackColor];
    
    NSString *content = @"对于上面的例子，我们给CTFrameParser增加了一个将NSString转换为CoreTextData的方法。"
            "但这样的实现方式有很多局限性，因为整个内容虽然可以定制字体大小，颜色，行高等信息，但是却不能支持定制内容中的某一部分。"
            "例如，如果我们只想让内容的前三个字显示成红色，而其它文字显示成黑色，那么就办不到了。"
            "\n\n"
            "解决的办法很简单，我们让`CTFrameParser`支持接受NSAttributeString作为参数，然后在NSAttributeString中设置好我们想要的信息。";
    NSDictionary *attr = [CTFrameParser attributesWithConfig:config];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:content
                                                                                         attributes:attr];
    [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor redColor] range:NSMakeRange(0, 7)];
    
    CoreTextData *data = [CTFrameParser parseAttributedContent:attributedString config:config];
    self.ctView.data = data;
    self.ctView.height = data.height;
    self.ctView.backgroundColor = [UIColor yellowColor];
}

@end
