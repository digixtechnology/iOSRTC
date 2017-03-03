//
//  WebRTCClient.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <libjingle_peerconnection/RTCMediaStream.h>
#import <libjingle_peerconnection/RTCPeerConnection.h>
#import <libjingle_peerconnection/RTCPeerConnectionFactory.h>
#import <libjingle_peerconnection/RTCMediaConstraints.h>
#import <libjingle_peerconnection/RTCVideoSource.h>
#import <libjingle_peerconnection/RTCICECandidate.h>
#import <libjingle_peerconnection/RTCICEServer.h>
#import <libjingle_peerconnection/RTCPair.h>
#import <libjingle_peerconnection/RTCVideoTrack.h>
#import <libjingle_peerconnection/RTCAudioTrack.h>
#import <libjingle_peerconnection/RTCEAGLVideoView.h>
#import <libjingle_peerconnection/RTCVideoCapturer.h>
#import <libjingle_peerconnection/RTCSessionDescription.h>

#import "PeerConnectionParameters.h"

#import "SocketIOManagerCall.h"

typedef NS_ENUM(NSInteger, WebRTCClientState) {
    // Disconnected from servers.
    kWebRTCClientStateDisconnected,
    // Connecting to servers.
    kWebRTCClientStateConnecting,
    // Connected to servers.
    kWebRTCClientStateConnected,
};

static NSUInteger const MAX_PEER = 2;

static NSString * const KEY_INIT = @"init";
static NSString * const KEY_OFFER = @"offer";
static NSString * const KEY_ANSWER = @"answer";
static NSString * const KEY_CANDIDATE = @"candidate";

static NSString *const kARDDefaultSTUNServerUrl =
@"stun:stun.l.google.com:19302";

@class WebRTCClient;
@protocol WebRTCClientDelegate <NSObject> //RtcListener

@required
- (void)onCallReady:(NSString *)callId;
- (void)onStatusChanged:(WebRTCClientState)newStatus;
- (void)onLocalStream:(RTCMediaStream *)localStream;
- (void)onAddRemoteStream:(RTCMediaStream *)remoteStream endPoint:(NSInteger) endPoint;
- (void)onRemoveRemoteStream:(NSInteger)endPoint;

- (void)didError:(NSError *) error;

@end

@class Peer;

@interface WebRTCClient : NSObject

@property (nonatomic, weak) id<WebRTCClientDelegate> mListener;

@property (nonatomic) NSMutableArray<NSNumber *> *endPoints;
@property (nonatomic) RTCPeerConnectionFactory *factory;
@property (nonatomic) NSMutableDictionary *peers;
@property (nonatomic) NSMutableArray *iceServers;
@property (nonatomic) PeerConnectionParameters *pcParams;
@property (nonatomic) RTCMediaStream *localMS;

@property (nonatomic) NSString *currentPeerConnectionID;

//ตัวแปรไม่จำเป็น
//@property (nonatomic) RTCVideoSource *videoSource;


//add later
@property(nonatomic, assign) BOOL isSpeakerEnabled;

@property(nonatomic) NSMutableArray *allKeyInPeers;




-(instancetype) initWebRTCClient:(id<WebRTCClientDelegate>)mListener
                          params:(PeerConnectionParameters *)params;

- (void)start:(NSString *)name;
- (void)sendMessage:(NSString *)to type:(NSString *)type payload:(NSDictionary *)payload;



- (void)enableSpeaker;
- (void)disableSpeaker;

-(Peer *)addPeer:(NSString *)ID endPoint:(NSInteger)endPoint;
-(void)removePeer:(NSString *)ID;

- (void)disconnect;

- (void)muteAllAudioIn;
- (void)unmuteAllAudioIn;

- (void)swapCameraToFront;
- (void)swapCameraToBack;


- (RTCVideoTrack *)createLocalVideoTrack;
- (RTCVideoTrack *)createLocalVideoTrackBackCamera;


@end
