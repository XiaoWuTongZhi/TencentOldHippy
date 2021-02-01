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
#import "RCTComponent.h"
#import "RCTBaseTextInput.h"

@class RCTEventDispatcher;

@protocol RCTUITextFieldResponseDelegate <NSObject>
@required
- (void)textview_becomeFirstResponder;
- (void)textview_resignFirstResponder;
@end

@interface RCTUITextField : UITextField
@property (nonatomic, assign) BOOL textWasPasted;
@property (nonatomic, weak) id <RCTUITextFieldResponseDelegate> responderDelegate;

@property (nonatomic, copy) RCTDirectEventBlock onBlur;
@property (nonatomic, copy) RCTDirectEventBlock onFocus;
@property (nonatomic, assign) BOOL editable;
@end

@interface RCTTextField : RCTBaseTextInput<UITextFieldDelegate>
@property (nonatomic, copy) RCTDirectEventBlock onKeyPress;
@property (nonatomic, assign) BOOL autoCorrect;
//@property (nonatomic, assign) UIEdgeInsets contentInset;
@property (nonatomic, strong) UIColor *placeholderTextColor;
@property (nonatomic, strong) NSString *placeholder;
@property (nonatomic, strong) NSNumber *maxLength;
@property (nonatomic, assign) BOOL textWasPasted;
@property (nonatomic, assign) BOOL authCodeAutoFill;//验证码是否自动填充

@property (nonatomic, copy) RCTDirectEventBlock onSelectionChange;

- (void)textFieldDidChange;

@property (nonatomic, copy) RCTDirectEventBlock onChangeText;

//focus/blur
- (void)focus;
- (void)blur;
- (void)keyboardWillShow:(NSNotification *)aNotification;

@property (nonatomic, copy) RCTDirectEventBlock onBlur;
@property (nonatomic, copy) RCTDirectEventBlock onFocus;
@property (nonatomic, copy) RCTDirectEventBlock onEndEditing;
@property (nonatomic, copy) RCTDirectEventBlock onKeyboardWillShow;

@property (nonatomic, copy)   NSString* value;
@property (nonatomic, strong) NSNumber* fontSize;
@property (nonatomic, strong) NSString* defaultValue;
@property (nonatomic, copy) NSString *text;
@property (nonatomic, strong) UIColor *textColor;
- (void)clearText;
@end
