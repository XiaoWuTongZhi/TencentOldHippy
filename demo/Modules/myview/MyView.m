//
//  MyView.m
//  Hippy
//
//  Created by 万致远 on 2019/4/3.
//  Copyright © 2019 Tencent. All rights reserved.
//

#import "MyView.h"
@interface MyView ()
@property (nonatomic, strong)UITextView *innerTextView;
@end

@implementation MyView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _innerTextView = [[UITextView alloc] initWithFrame:frame];
        [self addSubview:_innerTextView];
    }
    return self;
}

- (void)setText:(NSString *)text {
    _text = text;
    self.innerTextView.text =  text;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
