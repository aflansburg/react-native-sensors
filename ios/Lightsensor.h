// Inspired by https://github.com/pwmckenna/react-native-motion-manager

#import <React/RCTBridgeModule.h>
#import <CoreMotion/CoreMotion.h>
#import <UIKit/UIKit.h>

@import AVFoundation;
@import MobileCoreServices;
@import ImageIO;

@interface Lightsensor : NSObject<RCTBridgeModule, AVCaptureVideoDataOutputSampleBufferDelegate> {
    CMMotionManager *_motionManager;
}

- (void) isAvailableResolver:(RCTPromiseResolveBlock) resolve
         rejecter:(RCTPromiseRejectBlock) reject;
- (void) setUpdateInterval:(double) interval;
- (void) getUpdateInterval:(RCTResponseSenderBlock) cb;
- (void) getData:(RCTResponseSenderBlock) cb;
- (void) startUpdates;
- (void) stopUpdates;

@end
