//
//  Peer.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libjingle_peerconnection/RTCSessionDescriptionDelegate.h>

#import "WebRTCClient.h"

@interface Peer : NSObject <RTCSessionDescriptionDelegate, RTCPeerConnectionDelegate>

@property (nonatomic) RTCPeerConnection *pc;
@property (nonatomic) NSString *ID;
@property (nonatomic) NSInteger endPoint;

@property (nonatomic, weak) WebRTCClient *webRTCClient;

@property (nonatomic) RTCAudioTrack *defaultAudioTrack;

-(instancetype) initWithWithId:(NSString *)ID
                      endPoint:(NSInteger)endPoint
               andWebRTCClient:(WebRTCClient *)webRTCClient;



- (void)muteAudioIn;
- (void)unmuteAudioIn;

- (void)swapCameraToFront;
- (void)swapCameraToBack;


@end
