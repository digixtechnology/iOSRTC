//
//  PeerConnectionParameters.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/10/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface PeerConnectionParameters : NSObject

@property (nonatomic) BOOL videoCallEnabled;
@property (nonatomic) BOOL loopback;
@property (nonatomic) NSInteger videoWidth;
@property (nonatomic) NSInteger videoHeight;
@property (nonatomic) NSInteger videoFps;
@property (nonatomic) NSInteger videoStartBitrate;
@property (nonatomic) NSString *videoCodec;
@property (nonatomic) BOOL videoCodecHwAcceleration;
@property (nonatomic) NSInteger audioStartBitrate;
@property (nonatomic) NSString *audioCodec;
@property (nonatomic) BOOL cpuOveruseDetection;

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
           cpuOveruseDetection:(BOOL)cpuOveruseDetection;

@end
