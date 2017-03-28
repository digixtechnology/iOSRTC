//
//  RTCActivityViewController.m
//  webrtc-socketio-ios
//
//  Created by Disakul CG2 on 2/16/2560 BE.
//  Copyright © 2560 Digix Technology. All rights reserved.
//

#import "RTCActivityViewController.h"

#import <AVFoundation/AVFoundation.h>

#import <Toast/UIView+Toast.h>

@interface RTCActivityViewController ()

@end

@implementation RTCActivityViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[SocketIOManagerCall sharedManager] connect];
    [RTCPeerConnectionFactory initializeSSL];
    
    [self initByAppRTC];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    
    //Display the Local View full screen while connecting to Room
    [self.localViewBottomConstraint setConstant:0.0f];
    [self.localViewRightConstraint setConstant:0.0f];
    [self.localViewHeightConstraint setConstant:self.view.frame.size.height];
    [self.localViewWidthConstraint setConstant:self.view.frame.size.width];
    //[self.footerViewBottomConstraint setConstant:0.0f];
    

    
    
    [self initz];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self disconnect];
}


- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)disconnect {
    if (self.webRTCClient) {
        if (self.localVideoTrack) [self.localVideoTrack removeRenderer:self.localView];
        if (self.remoteVideoTrack) [self.remoteVideoTrack removeRenderer:self.remoteView];
        self.localVideoTrack = nil;
        [self.localView renderFrame:nil];
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
        [self.webRTCClient disconnect];
    }
}

- (void)remoteDisconnected {
    if (self.remoteVideoTrack) {
        [self.remoteVideoTrack removeRenderer:self.remoteView];
    }
    
    self.remoteVideoTrack = nil;
    [self.remoteView renderFrame:nil];
    [self videoView:self.localView didChangeVideoSize:self.localVideoSize];
    
    [self dismissViewControllerAnimated:YES completion:NULL];
}


- (void)initByAppRTC {
    
    self.isZoom = NO;
    self.isAudioMute = NO;
    self.isVideoBack = NO;
    
    [self.audioButton.layer setCornerRadius:20.0f];
    [self.videoButton.layer setCornerRadius:20.0f];
    [self.hangupButton.layer setCornerRadius:20.0f];
    
    //Add Double Tap to zoom
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(zoomRemote)];
    [tapGestureRecognizer setNumberOfTapsRequired:2];
    [self.view addGestureRecognizer:tapGestureRecognizer];
    
    //RTCEAGLVideoViewDelegate provides notifications on video frame dimensions
    [self.remoteView setDelegate:self];
    [self.localView setDelegate:self];
    
    [self registerNotifiactionObserver];
    
    [self zoomRemote];
}



- (void)initz{
    
    NSInteger videoWidth = [UIScreen mainScreen].bounds.size.width;
    NSInteger videoHeight = [UIScreen mainScreen].bounds.size.height;
    
    PeerConnectionParameters *params = [[PeerConnectionParameters alloc] initWithParams:YES loopback:NO videoWidth:videoWidth videoHeight:videoHeight videoFps:30 videoStartBitrate:1 videoCodec:VIDEO_CODEC_VP9 videoCodecHwAcceleration:YES audioStartBitrate:1 audioCodec:AUDIO_CODEC_OPUS cpuOveruseDetection:YES];
    
    self.webRTCClient = [[WebRTCClient alloc] initWebRTCClient:self params:params];
}

- (void)call:(NSString *)callId {
    
    [self startCam];
    
    NSString *message = [NSString stringWithFormat:@"%@%@", socketIOURL, callId];
    
    NSLog(@"call link: %@", message);
}

- (void)startCam {
    NSString *name = [NSString stringWithFormat:@"ios_%@", [self getStringFromDateTime]];
    NSLog(@"startCam name: %@", name);
    //camera settings
    [self.webRTCClient start:name];
}

- (NSString *)getStringFromDateTime{
    NSDateFormatter *dateFormatter=[[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    // or @"yyyy-MM-dd hh:mm:ss a" if you prefer the time with AM/PM
    return [dateFormatter stringFromDate:[NSDate date]];
}

- (void)answer:(NSString *)callerId {
    NSLog(@"answer callerId:%@", callerId);
    
    [self.webRTCClient sendMessage:callerId type:KEY_INIT payload:nil];
    [self startCam];
}


#pragma mark - button
- (IBAction)audioButtonPressed:(id)sender {
    
    UIButton *audioButton = sender;
    
    if (self.isAudioMute) {
        [self.webRTCClient unmuteAllAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"microphone"] forState:UIControlStateNormal];
        self.isAudioMute = NO;
        
    } else {
        [self.webRTCClient muteAllAudioIn];
        [audioButton setImage:[UIImage imageNamed:@"microphone-off"] forState:UIControlStateNormal];
        audioButton.tintColor = [UIColor whiteColor];
        self.isAudioMute = YES;
    }
    
}

- (IBAction)videoButtonPressed:(id)sender {
    if (self.isVideoBack) {
        [self.webRTCClient swapCameraToFront];
        self.isVideoBack = NO;
    } else {
        [self.webRTCClient swapCameraToBack];
        self.isVideoBack = YES;
    }
}

- (IBAction)hangupButtonPressed:(id)sender {
    

    
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)hangupTapped:(id)sender {
    
    
}


#pragma mark - implement WebRTCClient Delegate

- (void)onCallReady:(NSString *)callId {
    
    NSLog(@"onCallReady callId: %@", callId);
    
    if(self.callerId) {
        [self answer:self.callerId];
    }else {
        [self call:callId];
        
        self.myCallId = callId;
    }
    
}

- (void)onStatusChanged:(WebRTCClientState)newStatus {

    if(newStatus == kWebRTCClientStateConnecting){
        NSLog(@"WebRTCClientState: Connecting");
        [self.view makeToast:@"Connecting"];
        
    }else if(newStatus == kWebRTCClientStateConnected){
        NSLog(@"WebRTCClientState: Connected");
        [self.view makeToast:@"Connected"];
    
    }else if(newStatus == kWebRTCClientStateDisconnected){
        NSLog(@"WebRTCClientState: Disconnected");
        [self.view makeToast:@"Disconnected"];
        [self remoteDisconnected];
    }

}

//didReceiveLocalVideoTrack in apprtc
- (void)onLocalStream:(RTCMediaStream *)localStream {
    
    NSLog(@"onLocalStream");
    
    RTCVideoTrack *localVideoTrack = localStream.videoTracks[0];
    
//    if (self.localVideoTrack) { //clear old data
//        [self.localVideoTrack removeRenderer:self.localView];
//        self.localVideoTrack = nil;
//        [self.localView renderFrame:nil];
//    }
    
    self.localVideoTrack = localVideoTrack;
    [self.localVideoTrack addRenderer:self.localView];
}

//didReceiveRemoteVideoTrack
- (void)onAddRemoteStream:(RTCMediaStream *) remoteStream endPoint:(NSInteger)endPoint {
    
    NSLog(@"onAddRemoteStream");
    
    if (self.remoteVideoTrack) { //clear old data
        [self.remoteVideoTrack removeRenderer:self.remoteView];
        self.remoteVideoTrack = nil;
        [self.remoteView renderFrame:nil];
    }
    
    self.remoteVideoTrack = remoteStream.videoTracks[0];
    [self.remoteVideoTrack addRenderer:self.remoteView];
    
    [UIView animateWithDuration:0.4f animations:^{
        //Instead of using 0.4 of screen size, we re-calculate the local view and keep our aspect ratio
        UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
        CGRect videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width/4.0f, self.view.frame.size.height/4.0f);
        if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
            videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.height/4.0f, self.view.frame.size.width/4.0f);
        }
        CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(_localView.frame.size, videoRect);
        
        [self.localViewWidthConstraint setConstant:videoFrame.size.width];
        [self.localViewHeightConstraint setConstant:videoFrame.size.height];
        
        
        [self.localViewBottomConstraint setConstant:28.0f];
        [self.localViewRightConstraint setConstant:28.0f];
        //[self.footerViewBottomConstraint setConstant:-80.0f];
        [self.view layoutIfNeeded];
    }];
    
    
}

- (void)onRemoveRemoteStream:(NSInteger) endPoint {
//    VideoRendererGui.update(localRender,
//                            LOCAL_X_CONNECTING, LOCAL_Y_CONNECTING,
//                            LOCAL_WIDTH_CONNECTING, LOCAL_HEIGHT_CONNECTING,
//                            scalingType);
}


- (void)didError:(NSError *) error{
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Error" message:error.localizedDescription preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
    
    [alert addAction:okAction];
    
    [self presentViewController:alert animated:YES completion:nil];

}












#pragma mark - RTCEAGLVideoViewDelegate

- (void)videoView:(RTCEAGLVideoView *)videoView didChangeVideoSize:(CGSize)size {
    UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
    [UIView animateWithDuration:0.4f animations:^{
        CGFloat containerWidth = self.view.frame.size.width;
        CGFloat containerHeight = self.view.frame.size.height;
        CGSize defaultAspectRatio = CGSizeMake(4, 3);
        if (videoView == self.localView) {
            //Resize the Local View depending if it is full screen or thumbnail
            self.localVideoSize = size;
            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
            CGRect videoRect = self.view.bounds;
            if (self.remoteVideoTrack) {
                videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.width/4.0f, self.view.frame.size.height/4.0f);
                if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
                    videoRect = CGRectMake(0.0f, 0.0f, self.view.frame.size.height/4.0f, self.view.frame.size.width/4.0f);
                }
            }
            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);
            
            //Resize the localView accordingly
            [self.localViewWidthConstraint setConstant:videoFrame.size.width];
            [self.localViewHeightConstraint setConstant:videoFrame.size.height];
            if (self.remoteVideoTrack) {
                [self.localViewBottomConstraint setConstant:28.0f]; //bottom right corner
                [self.localViewRightConstraint setConstant:28.0f];
            } else {
                [self.localViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f]; //center
                [self.localViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            }
        } else if (videoView == self.remoteView) {
            //Resize Remote View
            self.remoteVideoSize = size;
            CGSize aspectRatio = CGSizeEqualToSize(size, CGSizeZero) ? defaultAspectRatio : size;
            CGRect videoRect = self.view.bounds;
            CGRect videoFrame = AVMakeRectWithAspectRatioInsideRect(aspectRatio, videoRect);
            if (self.isZoom) {
                //Set Aspect Fill
                CGFloat scale = MAX(containerWidth/videoFrame.size.width, containerHeight/videoFrame.size.height);
                videoFrame.size.width *= scale;
                videoFrame.size.height *= scale;
            }
            [self.remoteViewTopConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewBottomConstraint setConstant:containerHeight/2.0f - videoFrame.size.height/2.0f];
            [self.remoteViewLeftConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            [self.remoteViewRightConstraint setConstant:containerWidth/2.0f - videoFrame.size.width/2.0f]; //center
            
        }
        [self.view layoutIfNeeded];
    }];
    
}

- (void)zoomRemote {
    //Toggle Aspect Fill or Fit
    self.isZoom = !self.isZoom;
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}

- (void)registerNotifiactionObserver{
    //Getting Orientation change
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
                                                 name:@"UIDeviceOrientationDidChangeNotification"
                                               object:nil];
    
  
}

- (void)orientationChanged:(NSNotification *)notification{
    [self videoView:self.localView didChangeVideoSize:self.localVideoSize];
    [self videoView:self.remoteView didChangeVideoSize:self.remoteVideoSize];
}




@end
