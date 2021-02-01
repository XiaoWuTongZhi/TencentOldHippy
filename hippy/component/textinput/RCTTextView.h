/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import <UIKit/UIKit.h>

#import "RCTView.h"
#import "RCTBaseTextInput.h"
#import "UIView+React.h"

@class RCTEventDispatcher;

@protocol RCTUITextViewResponseDelegate <NSObject>
@required
- (void)textview_becomeFirstResponder;
- (void)textview_resignFirstResponder;
@end

@interface RCTUITextView : UITextView
@property (nonatomic, assign) BOOL textWasPasted;
@property (nonatomic, weak) id <RCTUITextViewResponseDelegate> responderDelegate;
@end

@interface RCTTextView : RCTBaseTextInput <UITextViewDelegate> {
@protected
      RCTUITextView *_textView;
}

@property (nonatomic, assign) BOOL autoCorrect;
@property (nonatomic, assign) BOOL blurOnSubmit;
@property (nonatomic, assign) BOOL clearTextOnFocus;
@property (nonatomic, assign) BOOL selectTextOnFocus;
//@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, assign) BOOL automaticallyAdjustContentInsets;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *placeholderTextColor;
@property (nonatomic, strong) UIFont *font;
@property (nonatomic, assign) NSInteger mostRecentEventCount;
@property (nonatomic, strong) NSNumber *maxLength;
@property (nonatomic, copy) RCTDirectEventBlock onKeyPress;

//@property (nonatomic, copy) RCTDirectEventBlock onChange;
@property (nonatomic, copy) RCTDirectEventBlock onContentSizeChange;
@property (nonatomic, copy) RCTDirectEventBlock onSelectionChange;
@property (nonatomic, copy) RCTDirectEventBlock onTextInput;
@property (nonatomic, copy) RCTDirectEventBlock onEndEditing;

- (void)performTextUpdate;

@property (nonatomic, copy)   NSString* value;
@property (nonatomic, strong) NSNumber* fontSize;
@property (nonatomic, strong) NSString* defaultValue;
@property (nonatomic, strong) UIColor *textColor;
@property (nonatomic, copy) RCTDirectEventBlock onChangeText;
@property (nonatomic, copy) RCTDirectEventBlock onBlur;
@property (nonatomic, copy) RCTDirectEventBlock onFocus;
@property (nonatomic, copy) RCTDirectEventBlock onKeyboardWillShow;

- (void)focus;
- (void)blur;
- (void)keyboardWillShow:(NSNotification *)aNotification;
- (void)clearText;
- (void)updateFrames;
@end
