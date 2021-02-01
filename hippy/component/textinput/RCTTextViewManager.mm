/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTTextViewManager.h"

#import "RCTBridge.h"
#import "RCTConvert.h"
#import "RCTShadowView.h"
#import "RCTTextView.h"
#import "RCTTextField.h"
#import "RCTBaseTextInput.h"
#import "RCTShadowTextView.h"
#import "RCTFont.h"


@implementation RCTTextViewManager

RCT_EXPORT_MODULE(TextInput)

- (UIView *)view
{
    //todo: 最佳实践？
    NSNumber *mutiline = self.props[@"multiline"];
    NSNumber *authCodeAutoFill = self.props[@"authCodeAutoFill"];

    RCTBaseTextInput *theView;
    if (mutiline != nil && !mutiline.boolValue) {
        RCTTextField *textField = [[RCTTextField alloc] init];
        if (@available(iOS 12.0, *) && authCodeAutoFill.boolValue) {
            textField.authCodeAutoFill = YES;
        }
        if (self.props[@"onKeyboardWillShow"]) {
            [[NSNotificationCenter defaultCenter] addObserver:textField
                                                     selector:@selector(keyboardWillShow:)
                                                         name:UIKeyboardWillShowNotification
                                                       object:nil];
        }
        theView = textField;
    } else {
        RCTTextView *textView = [[RCTTextView alloc] init];
        if (self.props[@"onKeyboardWillShow"]) {
            [[NSNotificationCenter defaultCenter] addObserver:textView
                                                     selector:@selector(keyboardWillShow:)
                                                         name:UIKeyboardWillShowNotification
                                                       object:nil];
        }
        theView = textView;
    }

    return theView;
}


- (RCTShadowView *) shadowView {
    return [RCTShadowTextView new];
}


RCT_EXPORT_VIEW_PROPERTY(value, NSString)
RCT_EXPORT_VIEW_PROPERTY(onChangeText, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onKeyPress, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onBlur, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onFocus, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onKeyboardWillShow, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(defaultValue, NSString)
RCT_EXPORT_VIEW_PROPERTY(isNightMode, BOOL)


RCT_EXPORT_METHOD(focusTextInput:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:
     ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
         RCTBaseTextInput *view = (RCTBaseTextInput *)viewRegistry[reactTag];
         if (view == nil) return ;
         if (![view isKindOfClass:[RCTBaseTextInput class]]) {
             RCTLogError(@"Invalid view returned from registry, expecting RCTBaseTextInput, got: %@", view);
         }
         [view focus];
     }];
}

RCT_EXPORT_METHOD(blurTextInput:(nonnull NSNumber *)reactTag)
{
    [self.bridge.uiManager addUIBlock:
     ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
         RCTBaseTextInput *view = (RCTBaseTextInput *)viewRegistry[reactTag];
         if (view == nil) return ;
         if (![view isKindOfClass:[RCTBaseTextInput class]]) {
             RCTLogError(@"Invalid view returned from registry, expecting RCTBaseTextInput, got: %@", view);
         }
         [view blur];
     }];
}


RCT_EXPORT_METHOD(clear:(nonnull NSNumber *)reactTag) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RCTBaseTextInput *view = (RCTBaseTextInput *)viewRegistry[reactTag];
        if (view == nil) return ;
        if (![view isKindOfClass:[RCTBaseTextInput class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting RCTBaseTextInput, got: %@", view);
        }
        [view clearText];
    }];
}

RCT_EXPORT_METHOD(setValue:(nonnull NSNumber *)reactTag
                  text:(NSString *)text ) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RCTBaseTextInput *view = (RCTBaseTextInput *)viewRegistry[reactTag];
        if (view == nil) return ;
        if (![view isKindOfClass:[RCTBaseTextInput class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting RCTBaseTextInput, got: %@", view);
        }
        [view setValue: text];
    }];
}

RCT_EXPORT_METHOD(getValue:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback ) {
    [self.bridge.uiManager addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        RCTBaseTextInput *view = (RCTBaseTextInput *)viewRegistry[reactTag];
        if (view == nil) return ;
        if (![view isKindOfClass:[RCTBaseTextInput class]]) {
            RCTLogError(@"Invalid view returned from registry, expecting RCTBaseTextInput, got: %@", view);
        }
        NSString *stringValue = [view value];
        if (nil == stringValue) {
            stringValue = @"";
        }
        NSArray *callBack = [NSArray arrayWithObject:[NSDictionary dictionaryWithObject:stringValue forKey:@"text"]];
        callback(callBack);
    }];
}

RCT_EXPORT_SHADOW_PROPERTY(text, NSString)
RCT_EXPORT_SHADOW_PROPERTY(placeholder, NSString)

RCT_REMAP_VIEW_PROPERTY(autoCapitalize, textView.autocapitalizationType, UITextAutocapitalizationType)
RCT_EXPORT_VIEW_PROPERTY(autoCorrect, BOOL)
RCT_EXPORT_VIEW_PROPERTY(blurOnSubmit, BOOL)
RCT_EXPORT_VIEW_PROPERTY(clearTextOnFocus, BOOL)
RCT_REMAP_VIEW_PROPERTY(color, textView.textColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(textAlign, textView.textAlignment, NSTextAlignment)
RCT_REMAP_VIEW_PROPERTY(editable, textView.editable, BOOL)
RCT_REMAP_VIEW_PROPERTY(enablesReturnKeyAutomatically, textView.enablesReturnKeyAutomatically, BOOL)
RCT_REMAP_VIEW_PROPERTY(keyboardType, textView.keyboardType, UIKeyboardType)
RCT_REMAP_VIEW_PROPERTY(keyboardAppearance, textView.keyboardAppearance, UIKeyboardAppearance)
RCT_EXPORT_VIEW_PROPERTY(maxLength, NSNumber)
RCT_EXPORT_VIEW_PROPERTY(onChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onContentSizeChange, RCTBubblingEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onSelectionChange, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onTextInput, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(onEndEditing, RCTDirectEventBlock)
RCT_EXPORT_VIEW_PROPERTY(placeholder, NSString)
RCT_EXPORT_VIEW_PROPERTY(placeholderTextColor, UIColor)
RCT_REMAP_VIEW_PROPERTY(returnKeyType, textView.returnKeyType, UIReturnKeyType)
RCT_REMAP_VIEW_PROPERTY(secureTextEntry, textView.secureTextEntry, BOOL)
RCT_REMAP_VIEW_PROPERTY(selectionColor, tintColor, UIColor)
RCT_EXPORT_VIEW_PROPERTY(selectTextOnFocus, BOOL)
RCT_EXPORT_VIEW_PROPERTY(selection, RCTTextSelection)
RCT_EXPORT_VIEW_PROPERTY(text, NSString)


RCT_CUSTOM_SHADOW_PROPERTY(fontSize, NSNumber, RCTShadowTextView) {
    view.font = [RCTFont updateFont:view.font withSize:json];
}

RCT_CUSTOM_SHADOW_PROPERTY(fontWeight, NSString, RCTShadowTextView) {
    view.font = [RCTFont updateFont:view.font withWeight:json];
}

RCT_CUSTOM_SHADOW_PROPERTY(fontStyle, NSString, RCTShadowTextView)
{
    view.font = [RCTFont updateFont:view.font withStyle:json]; // defaults to normal
}

RCT_CUSTOM_SHADOW_PROPERTY(fontFamily, NSString, RCTShadowTextView)
{
    view.font = [RCTFont updateFont:view.font withFamily:json];
}



RCT_CUSTOM_VIEW_PROPERTY(fontSize, NSNumber, RCTBaseTextInput)
{
    UIFont *theFont = [RCTFont updateFont:view.font withSize:json ?: @(defaultView.font.pointSize)];
    view.font = theFont;
}
RCT_CUSTOM_VIEW_PROPERTY(fontWeight, NSString, __unused RCTBaseTextInput)
{
    UIFont *theFont = [RCTFont updateFont:view.font withWeight:json]; // defaults to normal
    view.font = theFont;
}
RCT_CUSTOM_VIEW_PROPERTY(fontStyle, NSString, __unused RCTBaseTextInput)
{
    UIFont *theFont = [RCTFont updateFont:view.font withStyle:json];
    view.font = theFont; // defaults to normal
}
RCT_CUSTOM_VIEW_PROPERTY(fontFamily, NSString, RCTBaseTextInput)
{
    view.font = [RCTFont updateFont:view.font withFamily:json ?: defaultView.font.familyName];
}

- (RCTViewManagerUIBlock)uiBlockToAmendWithShadowView:(RCTShadowView *)shadowView
{
    NSNumber *reactTag = shadowView.reactTag;
    UIEdgeInsets padding = shadowView.paddingAsInsets;
    return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTBaseTextInput *> *viewRegistry) {
        viewRegistry[reactTag].contentInset = padding;
    };
}
@end

