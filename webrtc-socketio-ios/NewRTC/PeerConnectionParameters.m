//
//  PeerConnectionParameters.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "PeerConnectionParameters.h"



@implementation PeerConnectionParameters

-(instancetype) initWithParams:(BOOL)videoCallEnabled
                      loopback:(BOOL)loopback
                    videoWidth:(NSInteger)videoWidth
                   videoHeight:(NSInteger)videoHeight
                      videoFps:(NSInteger)videoFps
             videoStartBitrate:(NSInteger)videoStartBitrate
                    videoCodec:(NSString *)videoCodec
      videoCodecHwAcceleration:(BOOL)videoCodecHwAcceleration
             audioStartBitrate:(NSInteger)audioStartBitrate
                    audioCodec:(NSString*)audioCodec
           cpuOveruseDetection:(BOOL)cpuOveruseDetection{

    if( self = [super init]){
    
        self.videoCallEnabled = videoCallEnabled;
        self.loopback = loopback;
        self.videoWidth = videoWidth;
        self.videoHeight = videoHeight;
        self.videoFps = videoFps;
        self.videoStartBitrate = videoStartBitrate;
        self.videoCodec = videoCodec;
        self.videoCodecHwAcceleration = videoCodecHwAcceleration;
        self.audioCodec = audioCodec;
        self.cpuOveruseDetection = cpuOveruseDetection;
    
    }
    
    


    return self;
}

@end
