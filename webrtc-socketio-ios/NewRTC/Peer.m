//
//  Peer.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "Peer.h"

#import "SocketIOManagerCall.h"


static NSString *kARDAppClientErrorDomain = @"WebRTCClient";
static NSInteger kARDAppClientErrorSetSDP = -4;
static NSInteger kARDAppClientErrorCreateSDP = -3;



@implementation Peer


-(instancetype) initWithWithId:(NSString *)ID
                      endPoint:(NSInteger)endPoint
               andWebRTCClient:(WebRTCClient *)webRTCClient {
    
    
    if(self = [super init]){
        
        NSLog(@"new Peer id: %@   endPoint: %@",ID , @(endPoint));
        
        self.webRTCClient = webRTCClient;
        
        self.pc = [webRTCClient.factory peerConnectionWithICEServers:webRTCClient.iceServers constraints:[self defaultPeerConnectionConstraints] delegate:self];
        
        self.ID = ID;
        self.endPoint = endPoint;
        
        [self.pc addStream:webRTCClient.localMS];
        
        if (webRTCClient.mListener && [webRTCClient.mListener respondsToSelector:@selector(onStatusChanged:)]) {
            
            [webRTCClient.mListener onStatusChanged:kWebRTCClientStateConnecting];
        }
        
    }
    
    return self;
}


// Called when creating a session.
//method นี้อาจเทียบเท่ากับ onCreateSuccess in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didCreateSessionDescription:(RTCSessionDescription *)sdp
                 error:(NSError *)error{
    dispatch_async(dispatch_get_main_queue(), ^{
    if(error){ //code from apprtc
        
        NSLog(@"error in didCreateSessionDescription: %@", error);
        
        [self.webRTCClient disconnect];
        NSDictionary *userInfo = @{
                                   NSLocalizedDescriptionKey: @"Failed to create session description.",
                                   };
        NSError *sdpError =
        [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                   code:kARDAppClientErrorCreateSDP
                               userInfo:userInfo];
        [self.webRTCClient.mListener didError:sdpError];
        NSLog(@"sdpError: %@", sdpError);
        return;
        
        
    }//else{ //success
    
    [peerConnection setLocalDescriptionWithDelegate:self sessionDescription:sdp];
    
    NSDictionary *payload = @{ @"type":sdp.type,
                               @"sdp":sdp.description};
    
    [self.webRTCClient sendMessage:self.ID type:sdp.type payload:payload];
    NSLog(@"didCreateSessionDescription Sending: SDP \n %@", sdp.description);
    // }
    
    
    });
}

// Called when setting a local or remote description.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
didSetSessionDescriptionWithError:(NSError *)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (error) {
            NSLog(@"Failed to set session description. Error: %@", error);
            [self.webRTCClient disconnect];
            NSDictionary *userInfo = @{
                                       NSLocalizedDescriptionKey: @"Failed to set session description.",
                                       };
            NSError *sdpError =
            [[NSError alloc] initWithDomain:kARDAppClientErrorDomain
                                       code:kARDAppClientErrorSetSDP
                                   userInfo:userInfo];
            [self.webRTCClient.mListener didError:sdpError];
            return;
        }
        // If we're answering and we've just set the remote offer we need to create
        // an answer and set the local description.
        //
        //        if (!_isInitiator && !_peerConnection.localDescription) {
        //            RTCMediaConstraints *constraints = [self defaultAnswerConstraints];
        //            [_peerConnection createAnswerWithDelegate:self
        //                                          constraints:constraints];
        //
        //        }
        
        
    });
}




//RTCPeerConnectionDelegate

// Triggered when the SignalingState changed.
//onSignalingChange() in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
 signalingStateChanged:(RTCSignalingState)stateChanged{
    NSLog(@"Signaling state changed: %d", stateChanged);
}


//onAddStream() in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
           addedStream:(RTCMediaStream *)stream{
    
    if (!peerConnection) {
        return;
    }
    
    NSLog(@"onAddStream: %@", stream.label);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        NSLog(@"Received %lu video tracks and %lu audio tracks",
              (unsigned long)stream.videoTracks.count,
              (unsigned long)stream.audioTracks.count);
        
        if (stream.videoTracks.count) {
            
            [self.webRTCClient.mListener onAddRemoteStream:stream endPoint:self.endPoint+1];
            
            if (self.webRTCClient.isSpeakerEnabled){
                
                [self.webRTCClient enableSpeaker]; //Use the "handsfree" speaker instead of the ear speaker.
            }
        }
    });
    
}


// Triggered when a remote peer close a stream.

//onRemoveStream in android
- (void)peerConnection:(RTCPeerConnection *)peerConnection
         removedStream:(RTCMediaStream *)stream{
    
    NSLog(@"onRemoveStream: %@", stream.label);
    [self.webRTCClient removePeer:self.ID];
    
}

// Triggered when renegotiation is needed, for example the ICE has restarted.
- (void)peerConnectionOnRenegotiationNeeded:(RTCPeerConnection *)peerConnection{
}

// Called any time the ICEConnectionState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
  iceConnectionChanged:(RTCICEConnectionState)newState{
    
    if(newState == RTCICEConnectionDisconnected){
        [self.webRTCClient removePeer:self.ID];
        [self.webRTCClient.mListener onStatusChanged:kWebRTCClientStateDisconnected];
        NSLog(@"ICEConnection State Disconnected");
    }
}

// Called any time the ICEGatheringState changes.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
   iceGatheringChanged:(RTCICEGatheringState)newState{
    
    if(newState == RTCICEGatheringNew){
        NSLog(@"ICE gathering state changed: new");
    }else if(newState == RTCICEGatheringGathering){
        NSLog(@"ICE gathering state changed: gathering");
    }else if(newState == RTCICEGatheringComplete){
        NSLog(@"ICE gathering state changed: complete");
    }
    
}

// New Ice candidate have been found.
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       gotICECandidate:(RTCICECandidate *)candidate{
    
    
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if(candidate){
            
            NSLog(@"iceCandidate: %@", candidate.description);
            
            NSDictionary *payload = @{@"label":@(candidate.sdpMLineIndex),
                                      @"id":candidate.sdpMid,
                                      KEY_CANDIDATE:candidate.sdp
                                      };
            
            [self.webRTCClient sendMessage:self.ID type:KEY_CANDIDATE payload:payload];
            
        }else{
            NSLog(@"End of candidates");
        }
    });
}

// New data channel has been opened.
- (void)peerConnection:(RTCPeerConnection*)peerConnection
    didOpenDataChannel:(RTCDataChannel*)dataChannel{
}




#pragma mark - Audio mute/unmute
- (void)muteAudioIn {
    NSLog(@"peer -> audio muted");
    
    RTCMediaStream *localStream = self.pc.localStreams[0];
    
    //remove old stream from peerconnection
    [self.pc removeStream:localStream];
    
    //keep it for unmute later
    self.defaultAudioTrack = localStream.audioTracks[0];
    
    //remove audio from stream
    [localStream removeAudioTrack:localStream.audioTracks[0]];
    
    
    [self.pc addStream:localStream];
}

- (void)unmuteAudioIn {
    NSLog(@"audio unmuted");
    RTCMediaStream *localStream = self.pc.localStreams[0];
    
    //clear old stream from peerconnection
    [self.pc removeStream:localStream];
    
    //add audio again
    [localStream addAudioTrack:self.defaultAudioTrack];
    
    //add new stream
    [self.pc addStream:localStream];
    
}


- (void)swapCameraToFront{
    RTCMediaStream *localStream = self.pc.localStreams[0];
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self.webRTCClient createLocalVideoTrack];
    
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [self.webRTCClient.mListener onLocalStream:localStream];
    }
    [self.pc removeStream:localStream];
    [self.pc addStream:localStream];
}

- (void)swapCameraToBack{
    
    NSLog(@"swapCameraToBack in Peer");
    
    RTCMediaStream *localStream = self.pc.localStreams[0];
    [self.pc removeStream:localStream];
    
    
    [localStream removeVideoTrack:localStream.videoTracks[0]];
    
    RTCVideoTrack *localVideoTrack = [self.webRTCClient createLocalVideoTrackBackCamera];
    
    if (localVideoTrack) {
        [localStream addVideoTrack:localVideoTrack];
        [self.webRTCClient.mListener onLocalStream:localStream];
    }

    
    
    
    [self.pc addStream:localStream];
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


@end
