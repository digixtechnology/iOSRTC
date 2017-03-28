//
//  SocketIOManager.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/9/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@import SocketIO;

static NSString * const socketIOURL = @"http://localhost:3000";

@interface SocketIOManagerCall : NSObject

@property (nonatomic, retain) SocketIOClient *socket;


+ (instancetype)sharedManager;

- (void)connect;

- (void)emitMessage:(NSDictionary *)messageDict;
- (void)emitReadyToStream:(NSDictionary *)messageDict;

@end
