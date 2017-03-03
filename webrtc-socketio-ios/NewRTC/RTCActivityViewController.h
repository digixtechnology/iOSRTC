//
//  RTCActivityViewController.h
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/16/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import <UIKit/UIKit.h>

#import "WebRTCClient.h"

#import <libjingle_peerconnection/RTCVideoRenderer.h>
#import <libjingle_peerconnection/RTCOpenGLVideoRenderer.h>


static NSString * const VIDEO_CODEC_VP9 = @"VP9";
static NSString * const AUDIO_CODEC_OPUS = @"opus";
// Local preview screen position before call is connected.
//static NSUInteger const LOCAL_X_CONNECTING = 0;
//static NSUInteger const LOCAL_Y_CONNECTING = 0;
//static NSUInteger const LOCAL_WIDTH_CONNECTING = 100;
//static NSUInteger const LOCAL_HEIGHT_CONNECTING = 100;
//// Local preview screen position after call is connected.
//static NSUInteger const LOCAL_X_CONNECTED = 72;
//static NSUInteger const LOCAL_Y_CONNECTED = 72;
//static NSUInteger const LOCAL_WIDTH_CONNECTED = 25;
//static NSUInteger const LOCAL_HEIGHT_CONNECTED = 25;
//// Remote video screen position
//static NSUInteger const REMOTE_X = 0;
//static NSUInteger const REMOTE_Y = 0;
//static NSUInteger const REMOTE_WIDTH = 100;
//static NSUInteger const REMOTE_HEIGHT = 100;




@interface RTCActivityViewController : UIViewController <WebRTCClientDelegate, RTCEAGLVideoViewDelegate>


@property (nonatomic) WebRTCClient *webRTCClient;
@property (nonatomic) NSString *callerId;

@property (nonatomic) NSString *myCallId;

@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *remoteView; //remoteRender in android
@property (weak, nonatomic) IBOutlet RTCEAGLVideoView *localView; //localRender in android



//add later
@property (strong, nonatomic) RTCVideoTrack *localVideoTrack;
@property (strong, nonatomic) RTCVideoTrack *remoteVideoTrack;
@property (assign, nonatomic) CGSize localVideoSize;
@property (assign, nonatomic) CGSize remoteVideoSize;
@property (assign, nonatomic) BOOL isZoom;

//togle button parameter
@property (assign, nonatomic) BOOL isAudioMute;
@property (assign, nonatomic) BOOL isVideoBack;

@property (weak, nonatomic) IBOutlet UIButton *audioButton;
@property (weak, nonatomic) IBOutlet UIButton *videoButton;
@property (weak, nonatomic) IBOutlet UIButton *hangupButton;

- (IBAction)audioButtonPressed:(id)sender;
- (IBAction)videoButtonPressed:(id)sender;
- (IBAction)hangupButtonPressed:(id)sender;

//Auto Layout Constraints used for animations
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *remoteViewTopConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *remoteViewRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *remoteViewLeftConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *remoteViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *localViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *localViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *localViewRightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *localViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *footerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *buttonContainerViewLeftConstraint;


- (IBAction)hangupTapped:(id)sender;



@end
