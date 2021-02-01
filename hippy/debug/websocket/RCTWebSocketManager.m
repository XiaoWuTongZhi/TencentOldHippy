/**
 * Copyright (c) 2015-present, Facebook, Inc.
 * All rights reserved.
 *
 * This source code is licensed under the BSD-style license found in the
 * LICENSE file in the root directory of this source tree. An additional grant
 * of patent rights can be found in the PATENTS file in the same directory.
 */

#import "RCTDefines.h"
#import "RCTWebSocketManager.h"
#import "RCTConvert.h"
#import "RCTLog.h"
#import "RCTUtils.h"
#import "RCTSRWebSocket.h"

static NSUInteger socketIndex = 0;

#pragma mark - RCTWebSocketManager

@interface RCTWebSocketManager()<RCTSRWebSocketDelegate>

@property (nonatomic, strong) NSMutableDictionary<NSNumber *, RCTSRWebSocket *> *sockets;
@property (nonatomic, strong) dispatch_queue_t queue;

@end

@implementation RCTWebSocketManager

RCT_EXPORT_MODULE(websocket)

- (dispatch_queue_t)methodQueue
{
  return _queue;
}

- (instancetype)init
{
    if ((self = [super init])) {
        _sockets = [NSMutableDictionary new];
        _queue = dispatch_queue_create("com.tencent.hippy.WebSocketManager", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)invalidate
{
    for (RCTSRWebSocket *socket in _sockets.allValues) {
        socket.delegate = nil;
        [socket close];
    }
}

RCT_EXPORT_METHOD(connect:(NSDictionary *)params resolver:(RCTPromiseResolveBlock)resolve rejecter:(RCTPromiseRejectBlock)reject) {
    NSDictionary *headers = params[@"headers"];
    NSString *url = params[@"url"];
    NSString *protocols = headers[@"Sec-WebSocket-Protocol"];
    NSArray<NSString *> *protocolArray = [protocols componentsSeparatedByString:@","];
    RCTSRWebSocket *socket = [[RCTSRWebSocket alloc] initWithURL:[NSURL URLWithString:url] protocols:protocolArray];
    socket.delegate = self;
    socket.socketID = socketIndex++;
    NSNumber *socketId = @(socket.socketID);
    [_sockets setObject:socket forKey:socketId];
    resolve(@{@"code": @(0), @"id": socketId});
    [socket open];
}

RCT_EXPORT_METHOD(close:(NSDictionary *)params) {
    NSNumber *socketId = params[@"id"];
    NSNumber *code = params[@"code"];
    NSString *reason = params[@"reason"];
    RCTSRWebSocket *socket = [_sockets objectForKey:socketId];
    if (socket) {
        [socket closeWithCode:[code integerValue] reason:reason];
    }
}

RCT_EXPORT_METHOD(send:(NSDictionary *)params) {
    NSNumber *socketId = params[@"id"];
    NSString *data = params[@"data"];
    RCTSRWebSocket *socket = [_sockets objectForKey:socketId];
    if (socket) {
        [socket send:data];
    }
}

- (void)webSocket:(RCTSRWebSocket *)webSocket didReceiveMessage:(id)message {
    dispatch_async(_queue, ^{
        [self sendEventType:@"onMessage" socket:webSocket data:@{@"type":@"text", @"data": message}];
    });
}

- (void)webSocketDidOpen:(RCTSRWebSocket *)webSocket {
    dispatch_async(_queue, ^{
        [self sendEventType:@"onOpen" socket:webSocket data:@{}];
    });
}

- (void)webSocket:(RCTSRWebSocket *)webSocket didFailWithError:(NSError *)error {
    NSString *errString = [error localizedFailureReason];
    [self sendEventType:@"onError" socket:webSocket data:@{@"error": errString}];
    [_sockets removeObjectForKey:@(webSocket.socketID)];
}

- (void)webSocket:(RCTSRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean {
    NSDictionary *data = @{@"code": @(code), @"reason": reason};
    [self sendEventType:@"onClose" socket:webSocket data:data];
    [_sockets removeObjectForKey:@(webSocket.socketID)];
}

- (void)webSocket:(RCTSRWebSocket *)webSocket didReceivePong:(NSData *)pongPayload {
    
}

- (void)sendEventType:(NSString *)type socket:(RCTSRWebSocket *)socket data:(id)data {
    for (NSNumber *key in [_sockets allKeys]) {
        RCTSRWebSocket *canSocket = [_sockets objectForKey:key];
        if (canSocket == socket) {
            NSDictionary *params = @{@"id": key, @"type": type, @"data": data?:@{}};
            [self sendEvent:@"hippyWebsocketEvents" params:params];
            break;
        }
    }
}

@end
