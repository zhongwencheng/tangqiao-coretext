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
    config.textColor = [UIColor redColor];
    config.width = self.ctView.width;
    
    CoreTextData *data = [CTFrameParser parseContent:@"按照以上原则，我们将`CTDisplayView`中的部分内容拆开。" config:config];
    self.ctView.data = data;
    self.ctView.height = data.height;
    self.ctView.backgroundColor = [UIColor yellowColor];
}

@end
