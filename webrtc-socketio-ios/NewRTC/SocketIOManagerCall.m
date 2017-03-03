//
//  SocketIOManager.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/9/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "SocketIOManagerCall.h"



@implementation SocketIOManagerCall

+ (instancetype)sharedManager {
    static SocketIOManagerCall *sharedSocketIOManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSocketIOManager = [[SocketIOManagerCall alloc] init];
    });
    return sharedSocketIOManager;
}

- (instancetype)init {
    
    if (self = [super init]) {
        
        
        NSMutableDictionary *options = [NSMutableDictionary new];
        options[@"log"] = @YES;
        options[@"forcePolling"] = @YES;
        
        NSURL* url = [[NSURL alloc] initWithString:socketIOURL];
        self.socket = [[SocketIOClient alloc] initWithSocketURL:url config:options];

    }
    
    return self;
}


- (void)connect {
    
    [self onConnect];
    [self onDisconnect];
    
    [self onId];
    [self onMessage];
    
    [self.socket connect];
}

- (void)onConnect {
    [self.socket on:@"connect" callback:^(NSArray* data, SocketAckEmitter* ack) {
        NSLog(@"socketiocall connected");
    }];
}

- (void)onDisconnect {
    [self.socket on:@"disconnect" callback:^(NSArray * data, SocketAckEmitter * ack) {
        NSLog(@"socketiocall disconnect");
    }];
}

- (void)onMessage {
    
    [self.socket on:@"message" callback:^(NSArray * arrayResponse, SocketAckEmitter * ack) {
        
        if(arrayResponse.count == 0){
            return;
        }
        
        NSDictionary *json = arrayResponse[0];
        NSLog(@"WSS->C: %@", [json description]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onMessage" object:json];
        
    }];

}

- (void)onId {
    [self.socket on:@"id" callback:^(NSArray * arrayResponse, SocketAckEmitter * ack) {
        
        if(arrayResponse.count == 0){
            return;
        }
        
        NSDictionary *json = arrayResponse[0];
        NSLog(@"Receive socketio -> id: %@", [json description]);
        
        [[NSNotificationCenter defaultCenter] postNotificationName:@"onId" object:json];
        
    }];
}

- (void)emitMessage:(NSDictionary *)messageDict {
    
    if(!messageDict){
        return;
    }
    
    [self.socket emit:@"message" with:@[messageDict]];
}

- (void)emitReadyToStream:(NSDictionary *)messageDict {
    
    if(!messageDict){
        return;
    }
    
    [self.socket emit:@"readyToStream" with:@[messageDict]];

}


- (void)dealloc {
    // Should never be called, but just here for clarity really.
}
@end
