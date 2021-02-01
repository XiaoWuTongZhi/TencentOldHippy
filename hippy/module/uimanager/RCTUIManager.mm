/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTUIManager.h"

#import <AVFoundation/AVFoundation.h>
#import "RCTAnimationType.h"
#import "RCTAssert.h"
#import "RCTBridge.h"
#import "RCTBridge+Private.h"
#import "RCTComponent.h"
#import "RCTComponentData.h"
#import "RCTConvert.h"
#import "RCTDefines.h"
#import "RCTEventDispatcher.h"
#import "RCTLog.h"
#import "RCTModuleData.h"
#import "RCTModuleMethod.h"
#import "RCTRootShadowView.h"
#import "RCTRootViewInternal.h"
#import "RCTScrollableProtocol.h"
#import "RCTShadowView.h"
#import "RCTUtils.h"
#import "RCTView.h"
#import "RCTViewManager.h"
#import "UIView+React.h"
#import "RCTExtAnimationViewParams.h"
#import "RCTExtAnimationModule.h"
#import "UIView+Private.h"
#import "RCTVirtualNode.h"
#import "RCTBaseListViewProtocol.h"
#import "RCTMemoryOpt.h"

@protocol RCTBaseListViewProtocol;

static void RCTTraverseViewNodes(id<RCTComponent> view, void (^block)(id<RCTComponent>))
{
    if (view.reactTag) {
        block(view);
        
        for (id<RCTComponent> subview in view.reactSubviews) {
            RCTTraverseViewNodes(subview, block);
        }
    }
}

//static BOOL CGRectNotNAN(CGRect frame) {
//    if (isnan(frame.origin.x) ||
//        isnan(frame.origin.y) ||
//        isnan(frame.size.width) ||
//        isnan(frame.size.height)) {
//        return NO;
//    }
//    return YES;
//}

const char *RCTUIManagerQueueName = "com.tencent.hippy.ShadowQueue";
NSString *const RCTUIManagerWillUpdateViewsDueToContentSizeMultiplierChangeNotification = @"RCTUIManagerWillUpdateViewsDueToContentSizeMultiplierChangeNotification";
NSString *const RCTUIManagerDidRegisterRootViewNotification = @"RCTUIManagerDidRegisterRootViewNotification";
NSString *const RCTUIManagerDidRemoveRootViewNotification = @"RCTUIManagerDidRemoveRootViewNotification";
NSString *const RCTUIManagerRootViewKey = @"RCTUIManagerRootViewKey";


//not used function
//static UIViewAnimationCurve _currentKeyboardAnimationCurve;

//not used function
//static UIViewAnimationOptions UIViewAnimationOptionsFromRCTAnimationType(RCTAnimationType type)
//{
//  switch (type) {
//    case RCTAnimationTypeLinear:
//      return UIViewAnimationOptionCurveLinear;
//    case RCTAnimationTypeEaseIn:
//      return UIViewAnimationOptionCurveEaseIn;
//    case RCTAnimationTypeEaseOut:
//      return UIViewAnimationOptionCurveEaseOut;
//    case RCTAnimationTypeEaseInEaseOut:
//      return UIViewAnimationOptionCurveEaseInOut;
//    case RCTAnimationTypeKeyboard:
//      // http://stackoverflow.com/questions/18870447/how-to-use-the-default-ios7-uianimation-curve
//      return (UIViewAnimationOptions)(_currentKeyboardAnimationCurve << 16);
//    default:
//      RCTLogError(@"Unsupported animation type %zd", type);
//      return UIViewAnimationOptionCurveEaseInOut;
//  }
//}

@implementation RCTUIManager
{
    // Root views are only mutated on the shadow queue
    NSMutableSet<NSNumber *> *_rootViewTags;
    NSMutableArray<RCTViewManagerUIBlock> *_pendingUIBlocks;
    NSMutableArray<RCTVirtualNodeManagerUIBlock> *_pendingVirtualNodeBlocks;
    NSMutableDictionary<NSNumber *, RCTVirtualNode *> *_nodeRegistry;
    NSMutableArray<NSNumber *> *_listTags;
    NSMutableSet<UIView *> *_viewsToBeDeleted; // Main thread only
    
    NSMutableDictionary<NSNumber *, RCTShadowView *> *_shadowViewRegistry; // RCT thread only
    NSMutableDictionary<NSNumber *, UIView *> *_viewRegistry; // Main thread only
    
    // Keyed by viewName
    NSDictionary *_componentDataByName;
    
    NSMutableSet<id<RCTComponent>> *_bridgeTransactionListeners;
#if !TARGET_OS_TV
    UIInterfaceOrientation _currentInterfaceOrientation;
#endif
    
    NSMutableArray<RCTViewUpdateCompletedBlock> *_completeBlocks;
    
    NSMutableSet<NSNumber *> *_listAnimatedViewTags;
}

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE()

- (instancetype) init {
    self = [super init];
    if (self) {
        _listAnimatedViewTags = [NSMutableSet set];
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self
                   selector:@selector(didReceiveMemoryWarning)
                       name:UIApplicationDidReceiveMemoryWarningNotification
                     object:nil];
        [center addObserver:self
                   selector:@selector(appDidEnterBackground)
                       name:UIApplicationDidEnterBackgroundNotification
                     object:nil];
        [center addObserver:self selector:@selector(appWillEnterForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver: self];
}

- (void)didReceiveNewContentSizeMultiplier
{
    dispatch_async(RCTGetUIManagerQueue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:RCTUIManagerWillUpdateViewsDueToContentSizeMultiplierChangeNotification
                                                            object:self];
        [self setNeedsLayout];
    });
}

- (NSMutableArray *)completeBlocks {
    if (nil == _completeBlocks) {
        _completeBlocks = [NSMutableArray array];
    }
    return _completeBlocks;
}

- (void)interfaceOrientationWillChange:(NSNotification *)notification
{
#if !TARGET_OS_TV
    UIInterfaceOrientation nextOrientation = (UIInterfaceOrientation)[notification.userInfo[UIApplicationStatusBarOrientationUserInfoKey] integerValue];
    
    _currentInterfaceOrientation = nextOrientation;
#endif
}

- (void)statusBarOrientationChangedWithNotification:(NSNotification *)notification {
    
    NSDictionary *dimensions = RCTExportedDimensions(YES);
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
    [_bridge.eventDispatcher dispatchEvent: @"Dimensions" methodName: @"set" args:dimensions];
    [_bridge.eventDispatcher dispatchEvent:@"EventDispatcher" methodName:@"receiveNativeEvent" args:@{@"eventName": @"orientationChanged", @"extra": dimensions}];
#pragma clang diagnostic pop
}

- (void)invalidate
{
    /**
     * Called on the JS Thread since all modules are invalidated on the JS thread
     */
    
    // This only accessed from the shadow queue
    _pendingUIBlocks = nil;
    _pendingVirtualNodeBlocks = nil;
    _shadowViewRegistry = nil;
    
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSNumber *rootViewTag in self->_rootViewTags) {
            [(id<RCTInvalidating>)self->_viewRegistry[rootViewTag] invalidate];
            [self->_viewRegistry removeObjectForKey: rootViewTag];
        }
        
        for (NSNumber *reactTag in [self->_viewRegistry allKeys]) {
            id <RCTComponent> subview = self->_viewRegistry[reactTag];
            if ([subview conformsToProtocol:@protocol(RCTInvalidating)]) {
                [(id<RCTInvalidating>)subview invalidate];
            }
        }
        
        self->_rootViewTags = nil;
        self->_viewRegistry = nil;
        self->_bridgeTransactionListeners = nil;
        self->_bridge = nil;
        self->_listTags = nil;
        self->_nodeRegistry = nil;
        
        [[NSNotificationCenter defaultCenter] removeObserver:self];
    });
    [_completeBlocks removeAllObjects];
}

- (void)didReceiveMemoryWarning {
    for (UIView *view in [self->_viewRegistry allValues]) {
        if ([view conformsToProtocol:@protocol(RCTMemoryOpt)]) {
            [(id<RCTMemoryOpt>)view didReceiveMemoryWarning];
        }
    }
}

- (void)appDidEnterBackground {
    for (UIView *view in [self->_viewRegistry allValues]) {
        if ([view conformsToProtocol:@protocol(RCTMemoryOpt)]) {
            [(id<RCTMemoryOpt>)view appDidEnterBackground];
        }
    }
}

- (void)appWillEnterForeground {
    for (UIView *view in [self->_viewRegistry allValues]) {
        if ([view conformsToProtocol:@protocol(RCTMemoryOpt)]) {
            [(id<RCTMemoryOpt>)view appWillEnterForeground];
        }
    }
}

- (NSMutableDictionary<NSNumber *, RCTShadowView *> *)shadowViewRegistry
{
    // NOTE: this method only exists so that it can be accessed by unit tests
    if (!_shadowViewRegistry) {
        _shadowViewRegistry = [NSMutableDictionary new];
    }
    return _shadowViewRegistry;
}

- (NSMutableDictionary<NSNumber *, RCTVirtualNode *> *)virtualNodeRegistry
{
    // NOTE: this method only exists so that it can be accessed by unit tests
    if (!_nodeRegistry) {
        _nodeRegistry = [NSMutableDictionary new];
    }
    return _nodeRegistry;
}

- (NSMutableDictionary<NSNumber *, UIView *> *)viewRegistry
{
    // NOTE: this method only exists so that it can be accessed by unit tests
    if (!_viewRegistry) {
        _viewRegistry = [NSMutableDictionary new];
    }
    return _viewRegistry;
}

- (void)setBridge:(RCTBridge *)bridge
{
    RCTAssert(_bridge == nil, @"Should not re-use same UIIManager instance");
    
    _bridge = bridge;
    
    _shadowViewRegistry = [NSMutableDictionary new];
    _viewRegistry = [NSMutableDictionary new];
    
    _nodeRegistry = [NSMutableDictionary new];
    _pendingVirtualNodeBlocks = [NSMutableArray new];
    _listTags = [NSMutableArray new];
    
    // Internal resources
    _pendingUIBlocks = [NSMutableArray new];
    _rootViewTags = [NSMutableSet new];
    
    _bridgeTransactionListeners = [NSMutableSet new];
    
    _viewsToBeDeleted = [NSMutableSet new];
    
    // Get view managers from bridge
    NSMutableDictionary *componentDataByName = [NSMutableDictionary new];
    for (Class moduleClass in _bridge.moduleClasses) {
        if ([moduleClass isSubclassOfClass:[RCTViewManager class]]) {
            RCTComponentData *componentData = [[RCTComponentData alloc] initWithManagerClass:moduleClass
                                                                                      bridge:_bridge];
            componentDataByName[componentData.name] = componentData;
        }
    }
    
    _componentDataByName = [componentDataByName copy];
    
#if !TARGET_OS_TV
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(interfaceOrientationWillChange:)
                                                 name:UIApplicationWillChangeStatusBarOrientationNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusBarOrientationChangedWithNotification:)
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
#endif
}

dispatch_queue_t RCTGetUIManagerQueue(void)
{
    static dispatch_queue_t shadowQueue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if ([NSOperation instancesRespondToSelector:@selector(qualityOfService)]) {
            dispatch_queue_attr_t attr = dispatch_queue_attr_make_with_qos_class(DISPATCH_QUEUE_SERIAL, QOS_CLASS_USER_INTERACTIVE, 0);
            shadowQueue = dispatch_queue_create(RCTUIManagerQueueName, attr);
        } else {
            shadowQueue = dispatch_queue_create(RCTUIManagerQueueName, DISPATCH_QUEUE_SERIAL);
            dispatch_set_target_queue(shadowQueue, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0));
        }
    });
    return shadowQueue;
}

- (dispatch_queue_t)methodQueue
{
    return RCTGetUIManagerQueue();
}

- (void)registerRootView:(UIView *)rootView withSizeFlexibility:(RCTRootViewSizeFlexibility)sizeFlexibility
{
    RCTAssertMainQueue();
    
    NSNumber *reactTag = rootView.reactTag;
    RCTAssert(RCTIsReactRootView(reactTag),
              @"View %@ with tag #%@ is not a root view", rootView, reactTag);
    
#if RCT_DEBUG
    UIView *existingView = _viewRegistry[reactTag];
    RCTAssert(existingView == nil || existingView == rootView,
              @"Expect all root views to have unique tag. Added %@ twice", reactTag);
#endif
    // Register view
    _viewRegistry[reactTag] = rootView;
    
    RCTVirtualNode *node = [RCTVirtualNode createNode: reactTag viewName: @"RCTRootContentView" props: @{}];
    _nodeRegistry[reactTag] = node;
    
    CGRect frame = rootView.frame;
    
    // Register shadow view
    dispatch_async(RCTGetUIManagerQueue(), ^{
        if (!self->_viewRegistry) {
            return;
        }
        
        RCTRootShadowView *shadowView = [RCTRootShadowView new];
        shadowView.reactTag = reactTag;
        shadowView.frame = frame;
        shadowView.backgroundColor = rootView.backgroundColor;
        shadowView.viewName = NSStringFromClass([rootView class]);
        shadowView.sizeFlexibility = sizeFlexibility;
        self->_shadowViewRegistry[shadowView.reactTag] = shadowView;
        [self->_rootViewTags addObject:reactTag];
    });
    
    [[NSNotificationCenter defaultCenter] postNotificationName:RCTUIManagerDidRegisterRootViewNotification
                                                        object:self
                                                      userInfo:@{RCTUIManagerRootViewKey: rootView}];
}

- (UIView *)viewForReactTag:(NSNumber *)reactTag
{
    RCTAssertMainQueue();
    return _viewRegistry[reactTag];
}

- (void)setFrame:(CGRect)frame forView:(UIView *)view
{
    RCTAssertMainQueue();
    
    // The following variable has no meaning if the view is not a react root view
    RCTRootViewSizeFlexibility sizeFlexibility = RCTRootViewSizeFlexibilityNone;
    BOOL isRootView = NO;
    if (RCTIsReactRootView(view.reactTag)) {
        RCTRootView *rootView = (RCTRootView *)[view superview];
        if (rootView != nil) {
            sizeFlexibility = rootView.sizeFlexibility;
            isRootView = YES;
        }
    }
    
    NSNumber *reactTag = view.reactTag;
    dispatch_async(RCTGetUIManagerQueue(), ^{
        RCTShadowView *shadowView = self->_shadowViewRegistry[reactTag];
        
        if (shadowView == nil) {
            if (isRootView) {
                // todo: 走到这个逻辑不正常，请联系pennyli
            }
            RCTLogInfo(@"Could not locate shadow view with tag #%@, this is probably caused by a temporary inconsistency between native views and shadow views.", reactTag);
            return;
        }
        
        BOOL needsLayout = NO;
        if (!CGRectEqualToRect(frame, shadowView.frame)) {
            shadowView.frame = frame;
            needsLayout = YES;
        }
        
        // Trigger re-layout when size flexibility changes, as the root view might grow or
        // shrink in the flexible dimensions.
        if (RCTIsReactRootView(reactTag)) {
            RCTRootShadowView *rootShadowView = (RCTRootShadowView *)shadowView;
            if (rootShadowView.sizeFlexibility != sizeFlexibility) {
                rootShadowView.sizeFlexibility = sizeFlexibility;
                needsLayout = YES;
            }
        }
        
        if (needsLayout) {
            [self setNeedsLayout: reactTag];
        }
    });
}

- (void)setIntrinsicContentSize:(CGSize)size forView:(UIView *)view
{
    RCTAssertMainQueue();
    
    NSNumber *reactTag = view.reactTag;
    dispatch_async(RCTGetUIManagerQueue(), ^{
        RCTShadowView *shadowView = self->_shadowViewRegistry[reactTag];
        RCTAssert(shadowView != nil, @"Could not locate root view with tag #%@", reactTag);
        
        shadowView.intrinsicContentSize = size;
        
        [self setNeedsLayout];
    });
}

- (void)setBackgroundColor:(UIColor *)color forView:(UIView *)view
{
    RCTAssertMainQueue();
    
    //  NSNumber *reactTag = view.reactTag;
    //  dispatch_async(RCTGetUIManagerQueue(), ^{
    //    if (!self->_viewRegistry) {
    //      return;
    //    }
    //
    //    RCTShadowView *shadowView = self->_shadowViewRegistry[reactTag];
    //    RCTAssert(shadowView != nil, @"Could not locate root view with tag #%@", reactTag);
    //    shadowView.backgroundColor = color;
    //    [self _amendPendingUIBlocksWithStylePropagationUpdateForShadowView:shadowView];
    //    [self flushVirtualNodeBlocks];
    //    [self flushUIBlocks];
    //  });
}

/**
 * Unregisters views from registries
 */
- (void)_purgeChildren:(NSArray<id<RCTComponent>> *)children
          fromRegistry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)registry
{
    for (id<RCTComponent> child in children) {
        RCTTraverseViewNodes(registry[child.reactTag], ^(id<RCTComponent> subview) {
            RCTAssert(![subview isReactRootView], @"Root views should not be unregistered");
            if ([subview conformsToProtocol:@protocol(RCTInvalidating)]) {
                [(id<RCTInvalidating>)subview invalidate];
            }
            [registry removeObjectForKey:subview.reactTag];
            
            if (registry == (NSMutableDictionary<NSNumber *, id<RCTComponent>> *)self->_viewRegistry) {
                [self->_bridgeTransactionListeners removeObject:subview];
            }
            
            // 如果是list virtual node节点，则在UI线程删除list上的视图节点
            if (registry == (NSMutableDictionary<NSNumber *, id<RCTComponent>> *)self->_nodeRegistry) {
                if ([self->_listTags containsObject: subview.reactTag]) {
                    [self->_listTags removeObject:subview.reactTag];
                    for (id<RCTComponent> node in subview.reactSubviews) {
                        [self removeNativeNode: (RCTVirtualNode *)node];
                    }
                }
            }
        });
    }
}

- (void)addUIBlock:(RCTViewManagerUIBlock)block
{
    RCTAssertThread(RCTGetUIManagerQueue(),
                    @"-[RCTUIManager addUIBlock:] should only be called from the "
                    "UIManager's queue (get this using `RCTGetUIManagerQueue()`)");
    
    if (!block || !_viewRegistry) {
        return;
    }
    
    [_pendingUIBlocks addObject:block];
}

- (void)addVirtulNodeBlock:(RCTVirtualNodeManagerUIBlock)block
{
    RCTAssertThread(RCTGetUIManagerQueue(),
                    @"-[RCTUIManager addVirtulNodeBlock:] should only be called from the "
                    "UIManager's queue (get this using `RCTGetUIManagerQueue()`)");
    
    if (!block || !_nodeRegistry) {
        return;
    }
    
    [_pendingVirtualNodeBlocks addObject:block];
}

- (void)executeBlockOnUIManagerQueue:(dispatch_block_t)block
{
    dispatch_async(RCTGetUIManagerQueue(), ^{
        if (block) {
            block();
        }
    });
}

- (RCTViewManagerUIBlock)uiBlockWithLayoutUpdateForRootView:(RCTRootShadowView *)rootShadowView
{
    RCTAssert(!RCTIsMainQueue(), @"Should be called on shadow queue");
    
    // This is nuanced. In the JS thread, we create a new update buffer
    // `frameTags`/`frames` that is created/mutated in the JS thread. We access
    // these structures in the UI-thread block. `NSMutableArray` is not thread
    // safe so we rely on the fact that we never mutate it after it's passed to
    // the main thread.
    NSSet<RCTShadowView *> *viewsWithNewFrames = [rootShadowView collectViewsWithUpdatedFrames];
    
    if (!viewsWithNewFrames.count) {
        // no frame change results in no UI update block
        return nil;
    }
    
    typedef struct {
        CGRect frame;
        BOOL isNew;
        BOOL parentIsNew;
        BOOL isHidden;
        BOOL animated;
    } RCTFrameData;
    
    // Construct arrays then hand off to main thread
    NSUInteger count = viewsWithNewFrames.count;
    NSMutableArray *reactTags = [[NSMutableArray alloc] initWithCapacity:count];
    NSMutableData *framesData = [[NSMutableData alloc] initWithLength:sizeof(RCTFrameData) * count];
    {
        NSUInteger index = 0;
        RCTFrameData *frameDataArray = (RCTFrameData *)framesData.mutableBytes;
        for (RCTShadowView *shadowView in viewsWithNewFrames) {
            reactTags[index] = shadowView.reactTag;
            frameDataArray[index++] = (RCTFrameData){
                shadowView.frame,
                shadowView.isNewView,
                shadowView.superview.isNewView,
                shadowView.isHidden,
                shadowView.animated
            };
        }
    }
    
    // These are blocks to be executed on each view, immediately after
    // reactSetFrame: has been called. Note that if reactSetFrame: is not called,
    // these won't be called either, so this is not a suitable place to update
    // properties that aren't related to layout.
    NSMutableDictionary<NSNumber *, RCTViewManagerUIBlock> *updateBlocks =
    [NSMutableDictionary new];
    for (RCTShadowView *shadowView in viewsWithNewFrames) {
        
        // We have to do this after we build the parentsAreNew array.
        shadowView.newView = NO;
        
        NSNumber *reactTag = shadowView.reactTag;
        RCTViewManager *manager = [_componentDataByName[shadowView.viewName] manager];
        RCTViewManagerUIBlock block = [manager uiBlockToAmendWithShadowView:shadowView];
        if (block) {
            updateBlocks[reactTag] = block;
        }
        
        if (shadowView.onLayout) {
            CGRect frame = shadowView.frame;
            shadowView.onLayout(@{
                                  @"layout": @{
                                          @"x": @(frame.origin.x),
                                          @"y": @(frame.origin.y),
                                          @"width": @(frame.size.width),
                                          @"height": @(frame.size.height),
                                          },
                                  });
        }
        
        if (RCTIsReactRootView(reactTag)) {
            CGSize contentSize = shadowView.frame.size;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                UIView *view = self->_viewRegistry[reactTag];
                RCTAssert(view != nil, @"view (for ID %@) not found", reactTag);
                
                RCTRootView *rootView = (RCTRootView *)[view superview];
                rootView.intrinsicSize = contentSize;
            });
        }
    }
    
    [self addVirtulNodeBlock:^(__unused RCTUIManager *uiManager, NSDictionary *virtualNodeRegistry) {
        NSInteger index = 0;
        RCTFrameData *frameDataArray = (RCTFrameData *)framesData.mutableBytes;
        for (NSNumber *reactTag in reactTags) {
            RCTVirtualNode *node = virtualNodeRegistry[reactTag];
            if (node) {
                RCTFrameData frameData = frameDataArray[index];
                [node reactSetFrame: frameData.frame];
            }
            index++;
        }
    }];
    
    // Perform layout (possibly animated)
    return ^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        
        const RCTFrameData *frameDataArray = (const RCTFrameData *)framesData.bytes;
        __block NSUInteger completionsCalled = 0;
        
        NSInteger index = 0;
        for (NSNumber *reactTag in reactTags) {
            RCTFrameData frameData = frameDataArray[index++];
            
            UIView *view = viewRegistry[reactTag];
            CGRect frame = frameData.frame;
            
            BOOL isHidden = frameData.isHidden;
            void (^completion)(BOOL) = ^(__unused BOOL finished) {
                completionsCalled++;
            };
            
            if (view.isHidden != isHidden) {
                view.hidden = isHidden;
            }
            
            RCTViewManagerUIBlock updateBlock = updateBlocks[reactTag];
            [view reactSetFrame:frame];
            if (frameData.animated) {
                if (nil == view) {
                    [self->_listAnimatedViewTags addObject:reactTag];
                }
                [uiManager.bridge.animationModule connectAnimationToView:view];
            }
            if (updateBlock) {
                updateBlock(self, viewRegistry);
            }
            completion(YES);
        }
        
    };
}

- (void)_amendPendingUIBlocksWithStylePropagationUpdateForShadowView:(RCTShadowView *)topView
{
    NSMutableSet<RCTApplierBlock> *applierBlocks = [NSMutableSet setWithCapacity:1];
    
    NSMutableSet<RCTApplierVirtualBlock> *virtualApplierBlocks = [NSMutableSet setWithCapacity:1];
    [topView collectUpdatedProperties:applierBlocks virtualApplierBlocks: virtualApplierBlocks parentProperties:@{}];
    if (applierBlocks.count) {
        [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
            for (RCTApplierBlock block in applierBlocks) {
                block(viewRegistry);
            }
        }];
        
        [self addVirtulNodeBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *,RCTVirtualNode *> *virtualNodeRegistry) {
            for (RCTApplierVirtualBlock block in virtualApplierBlocks) {
                block(virtualNodeRegistry);
            }
        }];
    }
}

/**
 * A method to be called from JS, which takes a container ID and then releases
 * all subviews for that container upon receipt.
 */
RCT_EXPORT_METHOD(removeSubviewsFromContainerWithID:(nonnull NSNumber *)containerID)
{
    id<RCTComponent> container = _shadowViewRegistry[containerID];
    RCTAssert(container != nil, @"container view (for ID %@) not found", containerID);
    
    NSUInteger subviewsCount = [container reactSubviews].count;
    NSMutableArray<NSNumber *> *indices = [[NSMutableArray alloc] initWithCapacity:subviewsCount];
    for (NSUInteger childIndex = 0; childIndex < subviewsCount; childIndex++) {
        [indices addObject:@(childIndex)];
    }
    
    [self manageChildren:containerID
         moveFromIndices:nil
           moveToIndices:nil
       addChildReactTags:nil
            addAtIndices:nil
         removeAtIndices:indices];
}

/**
 * Disassociates children from container. Doesn't remove from registries.
 * TODO: use [NSArray getObjects:buffer] to reuse same fast buffer each time.
 *
 * @returns Array of removed items.
 */
- (NSArray<id<RCTComponent>> *)_childrenToRemoveFromContainer:(id<RCTComponent>)container
                                                    atIndices:(NSArray<NSNumber *> *)atIndices
{
    // If there are no indices to move or the container has no subviews don't bother
    // We support parents with nil subviews so long as they're all nil so this allows for this behavior
    if (atIndices.count == 0 || [container reactSubviews].count == 0) {
        return nil;
    }
    // Construction of removed children must be done "up front", before indices are disturbed by removals.
    NSMutableArray<id<RCTComponent>> *removedChildren = [NSMutableArray arrayWithCapacity:atIndices.count];
    RCTAssert(container != nil, @"container view (for ID %@) not found", container);
    for (NSNumber *indexNumber in atIndices) {
        NSUInteger index = indexNumber.unsignedIntegerValue;
        if (index < [container reactSubviews].count) {
            [removedChildren addObject:[container reactSubviews][index]];
        }
    }
    
    // FIXME: The fatal prompt caused to feeds running in QB got redbox alert in DEBUG mode.
    //        Commented theses code temporary.
    /*
    if (RCT_DEBUG && removedChildren.count != atIndices.count) {
        NSString *message = [NSString stringWithFormat:@"removedChildren count (%tu) was not what we expected (%tu)",
                             removedChildren.count, atIndices.count];
        RCTFatal(RCTErrorWithMessage(message));
    }
    */

    return removedChildren;
}

- (void)_removeChildren:(NSArray<id<RCTComponent>> *)children
          fromContainer:(id<RCTComponent>)container
{
    for (id<RCTComponent> removedChild in children) {
        [container removeReactSubview:removedChild];
    }
}

RCT_EXPORT_METHOD(removeRootView:(nonnull NSNumber *)rootReactTag)
{
    RCTShadowView *rootShadowView = _shadowViewRegistry[rootReactTag];
    RCTAssert(rootShadowView.superview == nil, @"root view cannot have superview (ID %@)", rootReactTag);
    [self _purgeChildren:(NSArray<id<RCTComponent>> *)rootShadowView.reactSubviews
            fromRegistry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)_shadowViewRegistry];
    [_shadowViewRegistry removeObjectForKey:rootReactTag];
    [_rootViewTags removeObject:rootReactTag];
    
    [self addVirtulNodeBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,RCTVirtualNode *> *virtualNodeRegistry) {
        RCTAssertMainQueue();
        RCTVirtualNode *rootNode = virtualNodeRegistry[rootReactTag];
        [uiManager _purgeChildren:(NSArray<id<RCTComponent>> *)rootNode.reactSubviews
                     fromRegistry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)virtualNodeRegistry];
        [(NSMutableDictionary *)virtualNodeRegistry removeObjectForKey:rootReactTag];
    }];
    
    [self addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        RCTAssertMainQueue();
        UIView *rootView = viewRegistry[rootReactTag];
        [uiManager _purgeChildren:(NSArray<id<RCTComponent>> *)rootView.reactSubviews
                     fromRegistry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)viewRegistry];
        [(NSMutableDictionary *)viewRegistry removeObjectForKey:rootReactTag];
        [[NSNotificationCenter defaultCenter] postNotificationName:RCTUIManagerDidRemoveRootViewNotification
                                                            object:uiManager
                                                          userInfo:@{RCTUIManagerRootViewKey: rootView}];
    }];
}

RCT_EXPORT_METHOD(replaceExistingNonRootView:(nonnull NSNumber *)reactTag
                  withView:(nonnull NSNumber *)newReactTag)
{
    RCTShadowView *shadowView = _shadowViewRegistry[reactTag];
    RCTAssert(shadowView != nil, @"shadowView (for ID %@) not found", reactTag);
    
    RCTShadowView *superShadowView = shadowView.superview;
    RCTAssert(superShadowView != nil, @"shadowView super (of ID %@) not found", reactTag);
    
    NSUInteger indexOfView = [superShadowView.reactSubviews indexOfObject:shadowView];
    RCTAssert(indexOfView != NSNotFound, @"View's superview doesn't claim it as subview (id %@)", reactTag);
    NSArray<NSNumber *> *removeAtIndices = @[@(indexOfView)];
    NSArray<NSNumber *> *addTags = @[newReactTag];
    [self manageChildren:superShadowView.reactTag
         moveFromIndices:nil
           moveToIndices:nil
       addChildReactTags:addTags
            addAtIndices:removeAtIndices
         removeAtIndices:removeAtIndices];
}

RCT_EXPORT_METHOD(setChildren:(nonnull NSNumber *)containerTag
                  reactTags:(NSArray<NSNumber *> *)reactTags)
{
    RCTSetChildren(containerTag, reactTags,
                   (NSDictionary<NSNumber *, id<RCTComponent>> *)_shadowViewRegistry);
    
    [self addVirtulNodeBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, RCTVirtualNode *> *virtualNodeRegistry) {
        RCTSetVirtualChildren(containerTag,  reactTags, virtualNodeRegistry);
    }];
    
    [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        
        RCTSetChildren(containerTag, reactTags,
                       (NSDictionary<NSNumber *, id<RCTComponent>> *)viewRegistry);
    }];
}

static void RCTSetVirtualChildren(NSNumber *containerTag,
                                  NSArray<NSNumber *> *reactTags,
                                  NSDictionary<NSNumber *, RCTVirtualNode *> *virtualNodeRegistry)
{
    RCTVirtualNode * container = virtualNodeRegistry[containerTag];
    if (container) {
        for (NSNumber *reactTag in reactTags) {
            RCTVirtualNode* node = virtualNodeRegistry[reactTag];
            if (node) {
                node.parent = container;
                [container insertReactSubview: node atIndex: container.subNodes.count];
            }
        }
    }
}

static void RCTSetChildren(NSNumber *containerTag,
                           NSArray<NSNumber *> *reactTags,
                           NSDictionary<NSNumber *, id<RCTComponent>> *registry)
{
    
    
    id<RCTComponent> container = registry[containerTag];
    for (NSNumber *reactTag in reactTags) {
        id<RCTComponent> view = registry[reactTag];
        if (view) {
            [container insertReactSubview:view atIndex: container.reactSubviews.count];
        }
    }
}

RCT_EXPORT_METHOD(startBatch:(__unused NSString *)batchID) {
}

RCT_EXPORT_METHOD(endBatch:(__unused NSString *)batchID) {
    if (_pendingUIBlocks.count) {
        [self batchDidComplete];
    }
}

RCT_EXPORT_METHOD(manageChildren:(nonnull NSNumber *)containerTag
                  moveFromIndices:(NSArray<NSNumber *> *)moveFromIndices
                  moveToIndices:(NSArray<NSNumber *> *)moveToIndices
                  addChildReactTags:(NSArray<NSNumber *> *)addChildReactTags
                  addAtIndices:(NSArray<NSNumber *> *)addAtIndices
                  removeAtIndices:(NSArray<NSNumber *> *)removeAtIndices)
{
    [self _manageChildren:containerTag
          moveFromIndices:moveFromIndices
            moveToIndices:moveToIndices
        addChildReactTags:addChildReactTags
             addAtIndices:addAtIndices
          removeAtIndices:removeAtIndices
                 registry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)_shadowViewRegistry];
    
    [self addVirtulNodeBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *,RCTVirtualNode *> *virtualNodeRegistry) {
        [uiManager _manageChildren:containerTag
                   moveFromIndices:moveFromIndices
                     moveToIndices:moveToIndices
                 addChildReactTags:addChildReactTags
                      addAtIndices:addAtIndices
                   removeAtIndices:removeAtIndices
                          registry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)virtualNodeRegistry];
        
    }];
    
    [self addUIBlock:^(RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry){
        [uiManager _manageChildren:containerTag
                   moveFromIndices:moveFromIndices
                     moveToIndices:moveToIndices
                 addChildReactTags:addChildReactTags
                      addAtIndices:addAtIndices
                   removeAtIndices:removeAtIndices
                          registry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)viewRegistry];
    }];
}

- (void)_manageChildren:(NSNumber *)containerTag
        moveFromIndices:(NSArray<NSNumber *> *)moveFromIndices
          moveToIndices:(NSArray<NSNumber *> *)moveToIndices
      addChildReactTags:(NSArray<NSNumber *> *)addChildReactTags
           addAtIndices:(NSArray<NSNumber *> *)addAtIndices
        removeAtIndices:(NSArray<NSNumber *> *)removeAtIndices
               registry:(NSMutableDictionary<NSNumber *, id<RCTComponent>> *)registry
{
    id<RCTComponent> container = registry[containerTag];
    RCTAssert(moveFromIndices.count == moveToIndices.count, @"moveFromIndices had size %tu, moveToIndices had size %tu", moveFromIndices.count, moveToIndices.count);
    RCTAssert(addChildReactTags.count == addAtIndices.count, @"there should be at least one React child to add");
    
    // Removes (both permanent and temporary moves) are using "before" indices
    NSArray<id<RCTComponent>> *permanentlyRemovedChildren =
    [self _childrenToRemoveFromContainer:container atIndices:removeAtIndices];
    NSArray<id<RCTComponent>> *temporarilyRemovedChildren =
    [self _childrenToRemoveFromContainer:container atIndices:moveFromIndices];
    BOOL isUIViewRegistry = registry == (NSMutableDictionary<NSNumber *, id<RCTComponent>> *)_viewRegistry;
    [self _removeChildren:permanentlyRemovedChildren fromContainer:container];
    
    [self _removeChildren:temporarilyRemovedChildren fromContainer:container];
    [self _purgeChildren:permanentlyRemovedChildren fromRegistry:registry];
    
    // Figure out what to insert - merge temporary inserts and adds
    NSMutableDictionary *destinationsToChildrenToAdd = [NSMutableDictionary dictionary];
    for (NSInteger index = 0, length = temporarilyRemovedChildren.count; index < length; index++) {
        destinationsToChildrenToAdd[moveToIndices[index]] = temporarilyRemovedChildren[index];
    }
    for (NSInteger index = 0, length = addAtIndices.count; index < length; index++) {
        id<RCTComponent> view = registry[addChildReactTags[index]];
        if (view) {
            destinationsToChildrenToAdd[addAtIndices[index]] = view;
        }
    }
    
    if (!isUIViewRegistry) {
        isUIViewRegistry = ((id)registry == (id)_nodeRegistry);
    }
    
    NSArray<NSNumber *> *sortedIndices =
    [destinationsToChildrenToAdd.allKeys sortedArrayUsingSelector:@selector(compare:)];
    for (NSNumber *reactIndex in sortedIndices) {
        NSInteger insertAtIndex = reactIndex.integerValue;
        
        // When performing a delete animation, views are not removed immediately
        // from their container so we need to offset the insertion index if a view
        // that will be removed appears earlier than the view we are inserting.
        if (isUIViewRegistry && _viewsToBeDeleted.count > 0) {
            for (NSInteger index = 0; index < insertAtIndex; index++) {
                UIView *subview = ((UIView *)container).reactSubviews[index];
                if ([_viewsToBeDeleted containsObject:subview]) {
                    insertAtIndex++;
                }
            }
        }
        
        if (((id)registry == (id)_nodeRegistry)) {
            RCTVirtualNode*node = destinationsToChildrenToAdd[reactIndex];
            node.parent = container;
        }
        
        [container insertReactSubview:destinationsToChildrenToAdd[reactIndex]
                              atIndex:insertAtIndex];
    }
}

RCT_EXPORT_METHOD(createView:(nonnull NSNumber *)reactTag
                  viewName:(NSString *)viewName
                  rootTag:(__unused NSNumber *)rootTag
                  props:(NSDictionary *)props)
{
    RCTComponentData *componentData = _componentDataByName[viewName];
    RCTShadowView *shadowView = [componentData createShadowViewWithTag:reactTag];
    if (componentData == nil) {
        RCTLogError(@"No component found for view with name \"%@\"", viewName);
    }
    id isAnimated = props[@"useAnimation"];
    //这里的view props不仅有useAnimation，而且在某层还有animationId
    //通过animationId与AnimationModule的createModule的animation绑定在一起
    if (isAnimated && [isAnimated isKindOfClass: [NSNumber class]]) {
        RCTExtAnimationModule *animationModule = self.bridge.animationModule;
        props = [animationModule bindAnimaiton:props viewTag: reactTag rootTag: rootTag];
        shadowView.animated = [(NSNumber *)isAnimated boolValue];;
    } else {
        shadowView.animated = NO;
    }
    
    NSMutableDictionary *newProps = [NSMutableDictionary dictionaryWithDictionary: props];
    [newProps setValue: rootTag forKey: @"rootTag"];
    
    // Register shadow view
    if (shadowView) {
        shadowView.reactTag = reactTag;
        shadowView.viewName = viewName;
        shadowView.props = props;
        shadowView.rootTag = rootTag;
        [componentData setProps:newProps forShadowView:shadowView];
        _shadowViewRegistry[reactTag] = shadowView;
    }
    
    // Shadow view is the source of truth for background color this is a little
    // bit counter-intuitive if people try to set background color when setting up
    // the view, but it's the only way that makes sense given our threading model
    
    // Dispatch view creation directly to the main thread instead of adding to
    // UIBlocks array. This way, it doesn't get deferred until after layout.
    
    [self addUIBlock:^(RCTUIManager *uiManager, __unused NSDictionary<NSNumber *,UIView *> *viewRegistry) {
        
        RCTVirtualNode *node = uiManager->_nodeRegistry[reactTag];
        
        if ([node isListSubNode] && [node cellNode] && !viewRegistry[[[node cellNode] reactTag]]) {
            return ;
        }
        
        UIView *view = [componentData createViewWithTag:reactTag initProps: newProps];
        if (view) {
            view.viewName = viewName;
            [componentData setProps:props forView:view]; // Must be done before bgColor to prevent wrong default
            
            if ([view respondsToSelector:@selector(reactBridgeDidFinishTransaction)]) {
                [uiManager->_bridgeTransactionListeners addObject:view];
            }
            uiManager->_viewRegistry[reactTag] = view;
        }
        
        if ([node isKindOfClass:[RCTVirtualList class]]) {
            if ([view conformsToProtocol: @protocol(RCTBaseListViewProtocol)]) {
                id <RCTBaseListViewProtocol> listview = (id<RCTBaseListViewProtocol>)view;
                listview.node = (RCTVirtualList *)node;
                [uiManager->_listTags addObject:reactTag];
            }
        }
    }];
    
    [self addVirtulNodeBlock:^(RCTUIManager *uiManager, __unused NSDictionary<NSNumber *,RCTVirtualNode *> *virtualNodeRegistry) {
        RCTVirtualNode *node = [componentData createVirtualNode: reactTag props: newProps];
        if(node) {
            node.rootTag = rootTag;
            uiManager->_nodeRegistry[reactTag] = node;
        }
    }];
}

- (void) updateViewsFromParams:(NSArray<RCTExtAnimationViewParams *> *)params completion:(RCTViewUpdateCompletedBlock)block{
    NSMutableSet *rootTags = [NSMutableSet set];
    for (RCTExtAnimationViewParams *param in params) {
        //rdm上报param.rootTag有nil的可能
        if (param.rootTag) {
            [rootTags addObject: param.rootTag];
        } else {
            RCTAssert(NO, @"param.rootTag不应该为nil，保留现场，找mengyanluo");
        }
        [self updateView:param.reactTag viewName:nil props:param.updateParams];
        if (block) {
            [[self completeBlocks] addObject:block];
        }
    }
    
    for (NSNumber *rootTag in rootTags) {
        [self _layoutAndMount: rootTag];
    }
}

RCT_EXPORT_METHOD(updateView:(nonnull NSNumber *)reactTag
                  viewName:(NSString *)viewName // not always reliable, use shadowView.viewName if available
                  props:(NSDictionary *)props)
{
    RCTShadowView *shadowView = _shadowViewRegistry[reactTag];
    RCTComponentData *componentData = _componentDataByName[shadowView.viewName ?: viewName];
    
    id isAnimated = props[@"useAnimation"];
    if (isAnimated && [isAnimated isKindOfClass: [NSNumber class]]) {
        RCTExtAnimationModule *animationModule = self.bridge.animationModule;
        props = [animationModule bindAnimaiton:props viewTag:reactTag rootTag: shadowView.rootTag];
        shadowView.animated = [(NSNumber *)isAnimated boolValue];;
    } else {
        shadowView.animated = NO;
    }
    
    NSDictionary *newProps = props;
    NSDictionary *virtualProps = props;
    if (shadowView) {
        newProps = [shadowView mergeProps: props];
        virtualProps = shadowView.props;
        [componentData setProps:newProps forShadowView:shadowView];
    }
    
    [self addVirtulNodeBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *,RCTVirtualNode *> *virtualNodeRegistry) {
        RCTVirtualNode *node = virtualNodeRegistry[reactTag];
        node.props = virtualProps;
    }];
    
    [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[reactTag];
        [componentData setProps:newProps forView:view];
    }];
}


RCT_EXPORT_METHOD(dispatchViewManagerCommand:(nonnull NSNumber *)reactTag
                  commandID:(NSInteger)commandID
                  commandArgs:(NSArray<id> *)commandArgs)
{
    RCTShadowView *shadowView = _shadowViewRegistry[reactTag];
    RCTComponentData *componentData = _componentDataByName[shadowView.viewName];
    Class managerClass = componentData.managerClass;
    RCTModuleData *moduleData = [_bridge moduleDataForName:RCTBridgeModuleNameForClass(managerClass)];
    id<RCTBridgeMethod> method = moduleData.methods[commandID];
    
    NSArray *args = [@[reactTag] arrayByAddingObjectsFromArray:commandArgs];
    [method invokeWithBridge:_bridge module:componentData.manager arguments:args];
}

- (void)partialBatchDidFlush
{
    if (self.unsafeFlushUIChangesBeforeBatchEnds) {
        [self flushVirtualNodeBlocks];
        [self flushUIBlocks];
    }
}

- (void)batchDidComplete
{
    [self _layoutAndMount];
}

/**
 * Sets up animations, computes layout, creates UI mounting blocks for computed layout,
 * runs these blocks and all other already existing blocks.
 */
- (void)_layoutAndMount
{
    // Gather blocks to be executed now that all view hierarchy manipulations have
    // been completed (note that these may still take place before layout has finished)
    for (RCTComponentData *componentData in _componentDataByName.allValues) {
        RCTViewManagerUIBlock uiBlock = [componentData uiBlockToAmendWithShadowViewRegistry:_shadowViewRegistry];
        [self addUIBlock:uiBlock];
    }
    
    // Perform layout
    for (NSNumber *reactTag in _rootViewTags) {
        RCTRootShadowView *rootView = (RCTRootShadowView *)_shadowViewRegistry[reactTag];
        [self addUIBlock:[self uiBlockWithLayoutUpdateForRootView:rootView]];
        [self _amendPendingUIBlocksWithStylePropagationUpdateForShadowView:rootView];
    }
    
    [self addUIBlock:^(RCTUIManager *uiManager, __unused NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        /**
         * TODO(tadeu): Remove it once and for all
         */
        for (id<RCTComponent> node in uiManager->_bridgeTransactionListeners) {
            [node reactBridgeDidFinishTransaction];
        }
    }];
    
    [self flushVirtualNodeBlocks];
    
    [self flushUIBlocks];
    
}

- (void)_layoutAndMount:(NSNumber *)reactTag
{
    RCTRootShadowView *rootView = (RCTRootShadowView *)_shadowViewRegistry[reactTag];
    if (![rootView isKindOfClass: [RCTRootShadowView class]]) {
        if (![_bridge isBatchActive]) {
            [self _layoutAndMount];
        }
        return;
    }
    
    // Gather blocks to be executed now that all view hierarchy manipulations have
    // been completed (note that these may still take place before layout has finished)
    for (RCTComponentData *componentData in _componentDataByName.allValues) {
        RCTViewManagerUIBlock uiBlock = [componentData uiBlockToAmendWithShadowViewRegistry:_shadowViewRegistry];
        [self addUIBlock:uiBlock];
    }
    
    // Perform layout
    [self addUIBlock:[self uiBlockWithLayoutUpdateForRootView:rootView]];
    [self _amendPendingUIBlocksWithStylePropagationUpdateForShadowView:rootView];
    
    [self addUIBlock:^(RCTUIManager *uiManager, __unused NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        /**
         * TODO(tadeu): Remove it once and for all
         */
        for (id<RCTComponent> node in uiManager->_bridgeTransactionListeners) {
            [node reactBridgeDidFinishTransaction];
        }
    }];
    
#ifdef QBNativeListENABLE
    [self flushVirtualNodeBlocks];
#endif
    
    [self flushUIBlocks];
    
    [self flushUpdateCompletedBlocks];
}

- (void)flushUpdateCompletedBlocks {
    if ([_completeBlocks count]) {
        NSArray<RCTViewUpdateCompletedBlock> *tmpBlocks = [NSArray arrayWithArray:_completeBlocks];
        __weak RCTUIManager *weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            RCTUIManager *sSelf = weakSelf;
            [tmpBlocks enumerateObjectsUsingBlock:^(RCTViewUpdateCompletedBlock  _Nonnull obj, __unused NSUInteger idx, __unused BOOL *stop) {
                obj(sSelf);
            }];
        });
        [_completeBlocks removeAllObjects];
    }
}

- (void)flushUIBlocks
{
    RCTAssertThread(RCTGetUIManagerQueue(),@"flushUIBlocks can only be called from the shadow queue");
    
    // First copy the previous blocks into a temporary variable, then reset the
    // pending blocks to a new array. This guards against mutation while
    // processing the pending blocks in another thread.
    NSArray<RCTViewManagerUIBlock> *previousPendingUIBlocks = _pendingUIBlocks;
    _pendingUIBlocks = [NSMutableArray new];
    __weak RCTUIManager *weakManager = self;
    if (previousPendingUIBlocks.count) {
        // Execute the previously queued UI blocks
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakManager) {
                RCTUIManager *uiManager = weakManager;
                @try {
                    for (RCTViewManagerUIBlock block in previousPendingUIBlocks) {
                        block(uiManager, uiManager->_viewRegistry);
                    }
                    
                    [uiManager flushListView];
                }
                @catch (NSException *exception) {
                    RCTLogError(@"Exception thrown while executing UI block: %@", exception);
                }
            }
        });
    }
}

- (void)flushVirtualNodeBlocks
{
    RCTAssertThread(RCTGetUIManagerQueue(),
                    @"flushUIBlocks can only be called from the shadow queue");
    
    // First copy the previous blocks into a temporary variable, then reset the
    // pending blocks to a new array. This guards against mutation while
    // processing the pending blocks in another thread.
    NSArray<RCTVirtualNodeManagerUIBlock> *previousPendingVirtualNodeBlocks = _pendingVirtualNodeBlocks;
    _pendingVirtualNodeBlocks = [NSMutableArray new];
    
    
    if (previousPendingVirtualNodeBlocks.count) {
        // Execute the previously queued UI blocks
        dispatch_async(dispatch_get_main_queue(), ^{
            @try {
                for (RCTVirtualNodeManagerUIBlock block in previousPendingVirtualNodeBlocks) {
                    block(self, self->_nodeRegistry);
                }
            }
            @catch (NSException *exception) {
                RCTLogError(@"Exception thrown while executing UI block: %@", exception);
            }
        });
    }
}

- (void)flushListView
{
    if (_listTags.count != 0) {
        [_listTags enumerateObjectsUsingBlock:^(NSNumber * _Nonnull tag, __unused NSUInteger idx, __unused BOOL * stop) {
            RCTVirtualList *listNode = (RCTVirtualList *)self->_nodeRegistry[tag];
            if (listNode.needFlush) {
                id <RCTBaseListViewProtocol> listView = (id <RCTBaseListViewProtocol>)self->_viewRegistry[tag];
                if([listView flush]) {
                    listNode.needFlush = NO;
                }
            }
        }];
    }
}

- (void)setNeedsLayout
{
    // If there is an active batch layout will happen when batch finished, so we will wait for that.
    // Otherwise we immidiately trigger layout.
    if (![_bridge isBatchActive]) {
        [self _layoutAndMount];
    }
}

- (void)setNeedsLayout:(NSNumber *)reactTag
{
    // If there is an active batch layout will happen when batch finished, so we will wait for that.
    // Otherwise we immidiately trigger layout.
    if (![_bridge isBatchActive]) {
        [self _layoutAndMount: reactTag];
    }
}


RCT_EXPORT_METHOD(measure:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
    [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[reactTag];
        if (!view) {
            // this view was probably collapsed out
            RCTLogWarn(@"measure cannot find view with tag #%@", reactTag);
            callback(@[]);
            return;
        }
        
        // If in a <Modal>, rootView will be the root of the modal container.
        UIView *rootView = viewRegistry[view.rootTag];
        if (!rootView) {
            RCTLogWarn(@"measure cannot find view's root view with tag #%@", reactTag);
            callback(@[]);
            return;
        }
        
        // By convention, all coordinates, whether they be touch coordinates, or
        // measurement coordinates are with respect to the root view.
        CGRect frame = view.frame;
        CGPoint pagePoint = [view.superview convertPoint:frame.origin toView:rootView];
        
        callback(@[
                   @(frame.origin.x),
                   @(frame.origin.y),
                   @(frame.size.width),
                   @(frame.size.height),
                   @(pagePoint.x),
                   @(pagePoint.y)
                   ]);
    }];
}

RCT_EXPORT_METHOD(measureInWindow:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
    [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[reactTag];
        if (!view) {
            // this view was probably collapsed out
            RCTLogWarn(@"measure cannot find view with tag #%@", reactTag);
            callback(@[]);
            return;
        }
        //这里的逻辑QB版本和内部开源版以及github版本不一样
        //QB这个方法已经被多个业务使用，如果修改会导致诸多QB业务修改
        //因此保留原样，增加measureInAppWindow方法实现获取view在window上坐标的能力
        UIView *rootView = viewRegistry[view.rootTag];
        if (!rootView) {
            RCTLogWarn(@"measure cannot find view's root view with tag #%@", reactTag);
            callback(@[]);
            return;
        }
        
        CGRect windowFrame = [rootView convertRect:view.frame fromView:view.superview];

        callback(@[@{@"width":@(CGRectGetWidth(windowFrame)),
                     @"height": @(CGRectGetHeight(windowFrame)),
                     @"x":@(windowFrame.origin.x),
                     @"y":@(windowFrame.origin.y)}]);
    }];
}

//这个方法只有QB版本有
RCT_EXPORT_METHOD(measureInAppWindow:(nonnull NSNumber *)reactTag
                  callback:(RCTResponseSenderBlock)callback)
{
    [self addUIBlock:^(__unused RCTUIManager *uiManager, NSDictionary<NSNumber *, UIView *> *viewRegistry) {
        UIView *view = viewRegistry[reactTag];
        if (!view) {
            // this view was probably collapsed out
            RCTLogWarn(@"measure cannot find view with tag #%@", reactTag);
            callback(@[]);
            return;
        }
                
        CGRect windowFrame = [view.window convertRect:view.frame fromView:view.superview];
        callback(@[@{@"width":@(CGRectGetWidth(windowFrame)),
                     @"height": @(CGRectGetHeight(windowFrame)),
                     @"x":@(windowFrame.origin.x),
                     @"y":@(windowFrame.origin.y)}]);
    }];
}

- (NSDictionary<NSString *, id> *)constantsToExport
{
    NSMutableDictionary<NSString *, NSDictionary *> *allJSConstants = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSDictionary *> *directEvents = [NSMutableDictionary new];
    NSMutableDictionary<NSString *, NSDictionary *> *bubblingEvents = [NSMutableDictionary new];
    
    [_componentDataByName enumerateKeysAndObjectsUsingBlock:
     ^(NSString *name, RCTComponentData *componentData, __unused BOOL *stop) {
         
         NSMutableDictionary<NSString *, id> *constantsNamespace =
         [NSMutableDictionary dictionaryWithDictionary:allJSConstants[name]];
         
         // Add manager class
         constantsNamespace[@"Manager"] = RCTBridgeModuleNameForClass(componentData.managerClass);
         
         // Add native props
         NSDictionary<NSString *, id> *viewConfig = [componentData viewConfig];
         constantsNamespace[@"NativeProps"] = viewConfig[@"propTypes"];
         
         // Add direct events
         for (NSString *eventName in viewConfig[@"directEvents"]) {
             if (!directEvents[eventName]) {
                 directEvents[eventName] = @{
                                             @"registrationName": [eventName stringByReplacingCharactersInRange:(NSRange){0, 3} withString:@"on"],
                                             };
             }
             if (RCT_DEBUG && bubblingEvents[eventName]) {
                 RCTLogError(@"Component '%@' re-registered bubbling event '%@' as a "
                             "direct event", componentData.name, eventName);
             }
         }
         
         // Add bubbling events
         for (NSString *eventName in viewConfig[@"bubblingEvents"]) {
             if (!bubblingEvents[eventName]) {
                 NSString *bubbleName = [eventName stringByReplacingCharactersInRange:(NSRange){0, 3} withString:@"on"];
                 bubblingEvents[eventName] = @{
                                               @"phasedRegistrationNames": @{
                                                       @"bubbled": bubbleName,
                                                       @"captured": [bubbleName stringByAppendingString:@"Capture"],
                                                       }
                                               };
             }
             if (RCT_DEBUG && directEvents[eventName]) {
                 RCTLogError(@"Component '%@' re-registered direct event '%@' as a "
                             "bubbling event", componentData.name, eventName);
             }
         }
         
         allJSConstants[name] = constantsNamespace;
     }];
    
#if !TARGET_OS_TV
    _currentInterfaceOrientation = [RCTSharedApplication() statusBarOrientation];
#endif
    [allJSConstants addEntriesFromDictionary:@{
                                               @"customBubblingEventTypes": bubblingEvents,
                                               @"customDirectEventTypes": directEvents,
                                               @"Dimensions": RCTExportedDimensions(NO)
                                               }];
    
    return allJSConstants;
}

static NSDictionary *RCTExportedDimensions(BOOL rotateBounds)
{
    RCTAssertMainQueue();
    
    // Don't use RCTScreenSize since it the interface orientation doesn't apply to it
    CGRect screenSize = UIScreen.mainScreen.bounds;
    CGFloat statusBarHeight = CGRectGetHeight(UIApplication.sharedApplication.statusBarFrame);

    return @{
        @"window": @{
                @"width": @(screenSize.size.width),
                @"height": @(screenSize.size.height),
                @"scale": @(RCTScreenScale()),
                @"statusBarHeight": @(statusBarHeight),
        },
        @"screen": @{
                @"width": @(screenSize.size.width),
                @"height": @(screenSize.size.height),
                @"scale": @(RCTScreenScale()),
                @"fontScale": @(1),
                @"statusBarHeight": @(statusBarHeight)
        }
    };
}


- (void)rootViewForReactTag:(NSNumber *)reactTag withCompletion:(void (^)(UIView *view))completion
{
    RCTAssertMainQueue();
    RCTAssert(completion != nil, @"Attempted to resolve rootView for tag %@ without a completion block", reactTag);
    
    if (reactTag == nil) {
        completion(nil);
        return;
    }
    
    dispatch_async(RCTGetUIManagerQueue(), ^{
        NSNumber *rootTag = [self _rootTagForReactTag:reactTag];
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView *rootView = nil;
            if (rootTag != nil) {
                rootView = [self viewForReactTag:rootTag];
            }
            completion(rootView);
        });
    });
}

- (NSNumber *)_rootTagForReactTag:(NSNumber *)reactTag
{
    RCTAssert(!RCTIsMainQueue(), @"Should be called on shadow queue");
    
    if (reactTag == nil) {
        return nil;
    }
    
    if (RCTIsReactRootView(reactTag)) {
        return reactTag;
    }
    
    NSNumber *rootTag = nil;
    RCTShadowView *shadowView = _shadowViewRegistry[reactTag];
    while (shadowView) {
        RCTShadowView *parent = [shadowView reactSuperview];
        if (!parent && RCTIsReactRootView(shadowView.reactTag)) {
            rootTag = shadowView.reactTag;
            break;
        }
        shadowView = parent;
    }
    
    return rootTag;
}

static UIView *_jsResponder;

+ (UIView *)JSResponder
{
    return _jsResponder;
}

- (UIView *)updateNode:(RCTVirtualNode *)oldNode withNode:(RCTVirtualNode *)node
{
    UIView *result = nil;
    @try {
        UIView *cachedView = self->_viewRegistry[node.reactTag];
        if (cachedView) {
            return cachedView;
        }
        
        if (oldNode == nil) {
            return nil;
        }
        
        NSDictionary *diff = [oldNode diff: node];
        
        if (diff == nil) {
            RCTAssert(diff != nil, @"updateView two view node data struct is different");
        }
        
        NSDictionary *update = diff[@"update"];
        NSDictionary *insert = diff[@"insert"];
        NSArray *remove = diff[@"remove"];
        NSDictionary *tags = diff[@"tag"];
        
        for (NSNumber *tag in remove) {
            UIView *view = self->_viewRegistry[tag];
            [view.superview clearSortedSubviews];
            [view.superview removeReactSubview:view];
            [self removeNativeNodeView: view];
        }
        
        result = [node createView:^UIView *(RCTVirtualNode *subNode) {
            NSNumber *subTag = subNode.reactTag;
            UIView *subview = nil;
            
            if (update[subTag]) { // 更新props
                RCTVirtualNode *oldSubNode = self->_nodeRegistry[update[subTag]];
                subview = self->_viewRegistry[oldSubNode.reactTag];
                if (subview == nil) {
                    RCTLogInfo(@"update node error");
                    NSString *viewName = subNode.viewName;
                    NSNumber *tag = subNode.reactTag;
                    NSDictionary *props = subNode.props;
                    RCTComponentData *componentData = self->_componentDataByName[viewName];
                    subview = [componentData createViewWithTag: tag initProps: props];
                    [componentData setProps: props forView: subview];
                    self->_viewRegistry[tag] = subview;
                } else {
                    RCTComponentData *componentData = self->_componentDataByName[oldSubNode.viewName];
                    NSDictionary *oldProps = oldSubNode.props;
                    NSDictionary *newProps = subNode.props;
                    newProps = [self mergeProps: newProps oldProps: oldProps];
                    [componentData setProps: newProps forView: subview];
                    [subview.layer removeAllAnimations];
                    [subview didUpdateWithNode: subNode];
                }
            } else if (insert[subTag]) { // 插入
                subview = self->_viewRegistry[subTag];
                if (subview == nil) {
                    subview = [self createViewFromNode:subNode];
                }
            }
            
            if (tags[subTag]) { // 更新tag
                NSNumber *oldSubTag = tags[subTag];
                subview = self->_viewRegistry[oldSubTag];
                if (subview == nil) {
                    RCTLogInfo(@"update node tag error");
                    NSString *viewName = subNode.viewName;
                    NSNumber *tag = subNode.reactTag;
                    NSDictionary *props = subNode.props;
                    RCTComponentData *componentData = self->_componentDataByName[viewName];
                    subview = [componentData createViewWithTag: tag initProps: props];
                    [componentData setProps: props forView: subview];
                    self->_viewRegistry[tag] = subview;
                } else {
                    [subview sendDetachedFromWindowEvent];
                    [subview.layer removeAllAnimations];
                    subview.reactTag = subTag;
                    [self->_viewRegistry removeObjectForKey: oldSubTag];
                    self->_viewRegistry[subTag] = subview;
                    [subview sendAttachedToWindowEvent];
                }
            }
            
            if (!CGRectEqualToRect(subview.frame, subNode.frame)) {
                [subview reactSetFrame: subNode.frame];
            }
            
            return subview;
            
        } insertChildrens:^(UIView *container, NSArray<UIView *> *childrens) {
            NSInteger index = 0;
            for (UIView *subview in childrens) {
                [container removeReactSubview: subview];
                [container insertReactSubview: subview atIndex: index];
                index++;
            }
            [container didUpdateReactSubviews];
        }];
        
    } @catch (NSException *exception) {
        MttRCTException(exception);
    }
    return result;
}

- (UIView *)createViewFromNode:(RCTVirtualNode *)node
{
    UIView *result = nil;
    NSMutableArray *tranctions = [NSMutableArray new];
#ifndef RCT_DEBUG
    @try {
#endif
        result = [node createView:^UIView *(RCTVirtualNode *subNode) {
            NSString *viewName = subNode.viewName;
            NSNumber *tag = subNode.reactTag;
            NSDictionary *props = subNode.props;
            RCTComponentData *componentData = self->_componentDataByName[viewName];
            UIView *view = [componentData createViewWithTag: tag initProps: props];
            [componentData setProps: props forView: view];
            self->_viewRegistry[tag] = view;
            CGRect frame = subNode.frame;
            //如果native端的RCTRootView.frame发生改变，会触发重新布局，RCTShadowView会更新frame。
            //但是RCTVirtualNode来不及更新frame。
            //这里优先使用RCTShadowView.frame绘制view
//            RCTShadowView *shadowView = self->_shadowViewRegistry[tag];
//            if (shadowView && CGRectNotNAN(shadowView.frame)) {
//                frame = shadowView.frame;
//            }
            [view reactSetFrame:frame];
            if ([view respondsToSelector: @selector(reactBridgeDidFinishTransaction)]) {
                [tranctions addObject: view];
            }
            //            [self callCacheUIFunctionCallIfNeed: tag];
            if ([self->_listAnimatedViewTags containsObject:tag]) {
                [self.bridge.animationModule connectAnimationToView:view];
            }
            return view;
        } insertChildrens:^(UIView *container, NSArray<UIView *> *childrens) {
            NSInteger index = 0;
            for (UIView *view in childrens) {
                [container insertReactSubview: view atIndex: index++];
            }
            [container didUpdateReactSubviews];
        }];
        
        for (UIView *view in tranctions) {
            [view reactBridgeDidFinishTransaction];
        }
#ifndef RCT_DEBUG
    } @catch (NSException *exception) {
        MttRCTException(exception);
    }
#endif
    return result;
}

- (void)removeNativeNode:(RCTVirtualNode *)node
{
    [node removeView:^(NSNumber *tag) {
        [self->_listAnimatedViewTags removeObject:tag];
        [self->_viewRegistry removeObjectForKey: tag];
    }];
}

- (void)removeNativeNodeView:(UIView *)nodeView
{
    [nodeView removeView:^(NSNumber *reactTag) {
        if (reactTag) {
            [self->_listAnimatedViewTags removeObject:reactTag];
            [self->_viewRegistry removeObjectForKey: reactTag];
        }
    }];
}

- (NSDictionary *)mergeProps:(NSDictionary *)newProps oldProps:(NSDictionary *)oldProps
{
    NSMutableDictionary *tmpProps = [NSMutableDictionary dictionaryWithDictionary: newProps];
    [oldProps enumerateKeysAndObjectsUsingBlock:^(NSString *  _Nonnull key, __unused id  _Nonnull obj, __unused BOOL *stop) {
        if (tmpProps[key] == nil) {
            tmpProps[key] = (id)kCFNull;
        }
    }];
    return tmpProps;
}

@end

@implementation RCTBridge (RCTUIManager)

- (RCTUIManager *)uiManager
{
    return [self moduleForClass:[RCTUIManager class]];
}

@end


