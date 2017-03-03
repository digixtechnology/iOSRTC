//
//  WebRTCClient.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "WebRTCClient.h"
#import "Peer.h"

#import <AVFoundation/AVFoundation.h>



@implementation WebRTCClient

- (instancetype)initWebRTCClient:(id<WebRTCClientDelegate>)mListener
                          params:(PeerConnectionParameters *)params{
    
    if(self = [super init]){
        
        
        [self registerNotificationCenter];
        
        
        [self initEndPoints];
        self.pcParams = params;
        self.peers = [NSMutableDictionary new];
        
        self.mListener = mListener;
        self.factory = [[RTCPeerConnectionFactory alloc] init];
        
        self.iceServers = [NSMutableArray arrayWithObject:[self defaultSTUNServer]];
        [self.iceServers addObject:[self defaultSTUNServer2]];
        
        self.isSpeakerEnabled = YES;
        
        
        
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(orientationChanged:)
                                                     name:@"UIDeviceOrientationDidChangeNotification"
                                                   object:nil];
        
        
        self.allKeyInPeers = [NSMutableArray new];
    }
    
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    [self disconnect];
}



- (void)initEndPoints {
    self.endPoints = [NSMutableArray arrayWithCapacity:MAX_PEER];
    
    for(int i = 0; i < MAX_PEER; i++){
        [self.endPoints addObject:@NO];
    }
}

- (void)start:(NSString *)name {
    [self setCamera];
    
    NSDictionary *messageDict = @{@"name":name};
    
    [[SocketIOManagerCall sharedManager] emitReadyToStream:messageDict];
    
}

- (void)setCamera {
    self.localMS =  [self createLocalMediaStream];
}

- (RTCMediaStream *)createLocalMediaStream {
    RTCMediaStream *localStream = [_factory mediaStreamWithLabel:@"ARDAMS"];
    
    RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        
        if (self.mListener && [self.mListener respondsToSelector:@selector(onLocalStream:)]) {
            [self.mListener onLocalStream:localStream];
        }
        
    }
    
    [localStream addAudioTrack:[_factory audioTrackWithID:@"ARDAMSa0"]];
    
    if (_isSpeakerEnabled){
        [self enableSpeaker];
    }
    
    return localStream;
}

- (RTCVideoTrack *)createLocalVideoTrack {
    
    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionFront) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the front camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}



#pragma mark - enable/disable speaker

- (void)enableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:nil];
    _isSpeakerEnabled = YES;
}

- (void)disableSpeaker {
    [[AVAudioSession sharedInstance] overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:nil];
    _isSpeakerEnabled = NO;
}





-(Peer *)addPeer:(NSString *)ID endPoint:(NSInteger)endPoint {
    
    Peer *peer = [[Peer alloc] initWithWithId:ID endPoint:endPoint andWebRTCClient:self];
    [self.peers setObject:peer forKey:ID];
    [self.allKeyInPeers addObject:ID];
    [self.endPoints replaceObjectAtIndex:endPoint withObject:@YES];
    
    NSLog(@"add new peer -> peers array: %@", [self.peers description]);
    
    self.currentPeerConnectionID = ID;
    
    return peer;
}


-(void)removePeer:(NSString *)ID {
    Peer *peer = [self.peers objectForKey:ID];
    
    if (self.mListener && [self.mListener respondsToSelector:@selector(onRemoveRemoteStream:)]) {
        [self.mListener onRemoveRemoteStream:peer.endPoint];
    }
    
    [peer.pc close];
    
    [self.peers removeObjectForKey:peer.ID];
    [self.allKeyInPeers removeObject:peer.ID];
    [self.endPoints replaceObjectAtIndex:peer.endPoint withObject:@NO];
}


-(NSInteger)findEndPoint {
    
    if(!self.endPoints.count){
        return 0;
    }
    
    
    for(int i = 0; i < MAX_PEER; i++){
        if ([_endPoints[i] isEqual:@NO]){
            return i;
        }
    }
    return MAX_PEER;
}

- (void)sendMessage:(NSString *)to type:(NSString *)type payload:(NSDictionary *)payload {
    NSMutableDictionary *messageDicts = [NSMutableDictionary new];
    messageDicts[@"to"] = to;
    messageDicts[@"type"] = type;
    messageDicts[@"payload"] = payload; //can be nil
    
    [[SocketIOManagerCall sharedManager] emitMessage:messageDicts];
}


#pragma mark - message handler

- (void)onMessageWithNoti:(NSNotification *)noti{
    
    NSLog(@"onMessageWithNoti");
    
    NSDictionary *json = [noti object];
    
    if(!json){
        return;
    }
    
    NSString *from = [json objectForKey:@"from"];
    NSString *type = [json objectForKey:@"type"];
    
    NSDictionary *payloadDict = nil;
    if(![type isEqualToString:KEY_INIT]){
        payloadDict = [json objectForKey:@"payload"];
    }
    
    
    BOOL isPeersContainsKeyFrom = [self isPeersContainsKeyFrom:from peers:_peers];
    
    if(!isPeersContainsKeyFrom){
        NSInteger endPoint = [self findEndPoint];
        
        if(endPoint != MAX_PEER){
            
            
            Peer *peer = [self addPeer:from endPoint:endPoint];
            [peer.pc addStream:self.localMS];
            
            NSLog(@"addPeerFrom:%@ endPoint:%@", from, @(endPoint));
            NSLog(@"add stream");
            
            [self executeCommandByType:type peerId:from payload:payloadDict];
            
        }
        
    }else{
        NSLog(@"executeCommandByType:%@ peerId:%@", type, from);
        [self executeCommandByType:type peerId:from payload:payloadDict];
    }
    
}

- (BOOL)isPeersContainsKeyFrom:(NSString *)from peers:(NSMutableDictionary *)peers {
    
    NSArray *allKeys = [self.peers allKeys];
    NSLog(@"key in peers: %@", [allKeys description]);
    
    for(int i = 0; i < allKeys.count ; i++){
        if([allKeys[i] isEqualToString:from]){
            return YES;
        }
    }
    
    return NO;
}


- (void)executeCommandByType:(NSString *)type peerId:(NSString *)peerId payload:(NSDictionary *)payload {
    
    NSLog(@"excuteCommandByType: %@ peerId: %@", type, peerId);
    
    if([type isEqualToString:KEY_INIT]){
        [self createOfferCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_OFFER]){
        [self createAnswerCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_ANSWER]){
        [self setRemoteSDPCommand:peerId payload:payload];
    }else if([type isEqualToString:KEY_CANDIDATE]){
        [self addIceCandidateCommand:peerId payload:payload];
    }
}


- (void)onIdWithNoti:(NSNotification *)noti{
    
    NSLog(@"onIdWithNoti");
    
    if(![noti.object isKindOfClass:[NSString class]]){
        return;
    }
    
    NSString *ID = noti.object;
    
    if (self.mListener && [self.mListener respondsToSelector:@selector(onCallReady:)]) {
        [self.mListener onCallReady:ID];
    }
}


#pragma mark - execute command

-(void)createOfferCommand:(NSString *)peerId payload:(NSDictionary *)payload {
    NSLog(@"CreateOfferCommand");
    Peer *peer = [self.peers objectForKey:peerId];
    [peer.pc createOfferWithDelegate:peer constraints:[self defaultOfferConstraints]];
    
}
-(void)createAnswerCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    NSLog(@"CreateAnswerCommand");
    Peer *peer = [self.peers objectForKey:peerId];
    
    NSString *type = [payload objectForKey:@"type"];
    NSString *sdpPayload = [payload objectForKey:@"sdp"];
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdpPayload];
    
    [peer.pc setRemoteDescriptionWithDelegate:peer sessionDescription:sdp];
    [peer.pc createAnswerWithDelegate:peer constraints:[self defaultAnswerConstraints]];
}



-(void)setRemoteSDPCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    NSLog(@"SetRemoteSDPCommand");
    Peer *peer = [self.peers objectForKey:peerId];
    
    NSString *type = [payload objectForKey:@"type"];
    NSString *sdpPayload = [payload objectForKey:@"sdp"];
    
    RTCSessionDescription *sdp = [[RTCSessionDescription alloc] initWithType:type sdp:sdpPayload];
    [peer.pc setRemoteDescriptionWithDelegate:peer sessionDescription:sdp];
}


-(void)addIceCandidateCommand:(NSString *)peerId payload:(NSDictionary *)payload{
    NSLog(@"AddIceCandidateCommand");
    Peer *peer = [self.peers objectForKey:peerId];
    RTCPeerConnection *pc = peer.pc;
    
    if(pc.remoteDescription){
        
        NSString *ID = [payload objectForKey:@"id"];
        NSInteger label = [[payload objectForKey:@"label"] integerValue];
        NSString *candidatePayload = [payload objectForKey:KEY_CANDIDATE];
        
        RTCICECandidate *candidate = [[RTCICECandidate alloc] initWithMid:ID index:label sdp:candidatePayload];
        [pc addICECandidate:candidate];
        
        
    }
}

#pragma mark - state viewcontroller must call




- (void)onDestroy{
    
    //comment is code in android
    
    for(Peer *peer in self.peers){
        [peer.pc close]; //peer.pc.dispose
    }
    
    //videoSource.dispose();
    //factory.dispose();
    //client.close();
    
    [[SocketIOManagerCall sharedManager].socket disconnect];
}


- (void)registerNotificationCenter{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onMessageWithNoti:) name:@"onMessage" object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onIdWithNoti:) name:@"onId" object:nil];
    
}


- (void)disconnect {
    //send message bye
    //clear data
    
}







- (void)orientationChanged:(NSNotification *)notification {
    if(!self.currentPeerConnectionID){
        return;
    }
    
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    if (UIDeviceOrientationIsLandscape(orientation) || UIDeviceOrientationIsPortrait(orientation)) {
        //Remove current video track
        RTCPeerConnection *peerConnection = [self.peers objectForKey:self.currentPeerConnectionID];
        
        RTCMediaStream *localStream = peerConnection.localStreams[0];
        [localStream removeVideoTrack:localStream.videoTracks[0]];
        
        RTCVideoTrack *localVideoTrack = [self createLocalVideoTrack];
        if (localVideoTrack) {
            [localStream addVideoTrack:localVideoTrack];
            
            
            [self.mListener onLocalStream:localStream];
        }
        
        
        [peerConnection removeStream:localStream];
        [peerConnection addStream:localStream];
    }
}



#pragma mark - Audio mute/unmute
- (void)muteAllAudioIn {
    NSLog(@"all keys in peers: %@", [self.peers allKeys].description);
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer muteAudioIn];
    }
    
    
}

- (void)unmuteAllAudioIn {
    
    NSLog(@"all keys in peers: %@", [self.peers allKeys].description);
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer unmuteAudioIn];
    }
    
    if (_isSpeakerEnabled) {
        [self enableSpeaker];
    }

}


#pragma mark - swap camera

- (RTCVideoTrack *)createLocalVideoTrackBackCamera {
    RTCVideoTrack *localVideoTrack = nil;
#if !TARGET_IPHONE_SIMULATOR && TARGET_OS_IPHONE
    //AVCaptureDevicePositionFront
    NSString *cameraID = nil;
    for (AVCaptureDevice *captureDevice in
         [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo]) {
        if (captureDevice.position == AVCaptureDevicePositionBack) {
            cameraID = [captureDevice localizedName];
            break;
        }
    }
    NSAssert(cameraID, @"Unable to get the back camera id");
    
    RTCVideoCapturer *capturer = [RTCVideoCapturer capturerWithDeviceName:cameraID];
    RTCMediaConstraints *mediaConstraints = [self defaultMediaStreamConstraints];
    RTCVideoSource *videoSource = [_factory videoSourceWithCapturer:capturer constraints:mediaConstraints];
    localVideoTrack = [_factory videoTrackWithID:@"ARDAMSv0" source:videoSource];
#endif
    return localVideoTrack;
}

- (void)swapCameraToFront {
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer swapCameraToFront];
    }
    
}

- (void)swapCameraToBack {
    NSLog(@"swapCameraToBack in WebRTCClient");
    
    for(NSString *ID in self.allKeyInPeers) {
        Peer *peer = [self.peers objectForKey:ID];
        [peer swapCameraToBack];
    }
}

#pragma mark - Defaults

- (RTCMediaConstraints *)defaultMediaStreamConstraints {
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultAnswerConstraints {
    return [self defaultOfferConstraints];
}

- (RTCMediaConstraints *)defaultOfferConstraints {
    NSArray *mandatoryConstraints = @[
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveAudio" value:@"true"],
                                      [[RTCPair alloc] initWithKey:@"OfferToReceiveVideo" value:@"true"]
                                      ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:mandatoryConstraints
     optionalConstraints:nil];
    return constraints;
}

- (RTCMediaConstraints *)defaultPeerConnectionConstraints {
    NSArray *optionalConstraints = @[
                                     [[RTCPair alloc] initWithKey:@"DtlsSrtpKeyAgreement" value:@"true"]
                                     ];
    RTCMediaConstraints* constraints =
    [[RTCMediaConstraints alloc]
     initWithMandatoryConstraints:nil
     optionalConstraints:optionalConstraints];
    return constraints;
}

- (RTCICEServer *)defaultSTUNServer {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:kARDDefaultSTUNServerUrl];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}

- (RTCICEServer *)defaultSTUNServer2 {
    NSURL *defaultSTUNServerURL = [NSURL URLWithString:@"stun:23.21.150.121"];
    return [[RTCICEServer alloc] initWithURI:defaultSTUNServerURL
                                    username:@""
                                    password:@""];
}








@end




