// Inspired by https://github.com/pwmckenna/react-native-motion-manager

#import <React/RCTBridge.h>
#import <React/RCTEventDispatcher.h>
#import "Lightsensor.h"

@implementation Lightsensor

@synthesize bridge = _bridge;

RCT_EXPORT_MODULE();

- (id) init {
    self = [super init];
    NSLog(@"Lightsensor");

    if (self) {
        self->_motionManager = [[CMMotionManager alloc] init];
    }
    return self;
}

+ (BOOL)requiresMainQueueSetup
{
    return NO;
}

RCT_REMAP_METHOD(isAvailable,
                 resolver:(RCTPromiseResolveBlock)resolve
                 rejecter:(RCTPromiseRejectBlock)reject) {
    return [self isAvailableWithResolver:resolve
                                rejecter:reject];
}

- (void) isAvailableWithResolver:(RCTPromiseResolveBlock) resolve
                        rejecter:(RCTPromiseRejectBlock) reject {
    if([self->_motionManager isLightAvailable])
    {
        /* Start the accelerometer if it is not active already */
        if([self->_motionManager isLightActive] == NO)
        {
            resolve(@YES);
        } else {
            reject(@"-1", @"Lightscope is not active", nil);
        }
    }
    else
    {
        reject(@"-1", @"Lightscope is not available", nil);
    }
}


RCT_EXPORT_METHOD(setUpdateInterval:(double) interval) {
    NSLog(@"setLightUpdateInterval: %f", interval);
    double intervalInSeconds = interval / 1000;

    [self->_motionManager setLightUpdateInterval:intervalInSeconds];
}

RCT_EXPORT_METHOD(getUpdateInterval:(RCTResponseSenderBlock) cb) {
    double interval = self->_motionManager.LightUpdateInterval;
    NSLog(@"getUpdateInterval: %f", interval);
    cb(@[[NSNull null], [NSNumber numberWithDouble:interval]]);
}

RCT_EXPORT_METHOD(getData:(RCTResponseSenderBlock) cb) {
    double C = self->_motionManager.LightData.C;
    double N = self->_motionManager.LightData.N;
    double t = self->_motionManager.LightData.t;
    double S = self->_motionManager.LightData.S;
    double timestamp = self->_motionManager.LightData.timestamp;

    NSLog(@"getData: %f, %f, %f, %f", x, y, z, timestamp);

    cb(@[[NSNull null], @{
                 @"C" : [NSNumber numberWithDouble:C],
                 @"N" : [NSNumber numberWithDouble:N],
                 @"t" : [NSNumber numberWithDouble:t],
                 @"S" : [NSNumber numberWithDouble:S],
                 @"timestamp" : [NSNumber numberWithDouble:timestamp]
             }]
       );
}

RCT_EXPORT_METHOD(startUpdates) {
    NSLog(@"startUpdates");
    [self->_motionManager startLightUpdates];
    [self initCamera];

    /* Receive the Lightscope data on this block */
    [self->_motionManager startLightUpdatesToQueue:[NSOperationQueue mainQueue]
                                      withHandler:^(CMLightData *LightData, NSError *error) {
         double C = LightData.C;
         double N = LightData.N;
         double t = LightData.t;
         double S = LightData.S;
         double timestamp = LightData.timestamp;
         NSLog(@"startUpdates: %f, %f, %f, %f", C, N, t, S, timestamp);

         [self.bridge.eventDispatcher sendDeviceEventWithName:@"Lightscope" body:@{
                                                                                     @"C" : [NSNumber numberWithDouble:C],
                                                                                     @"N" : [NSNumber numberWithDouble:N],
                                                                                     @"t" : [NSNumber numberWithDouble:t],
                                                                                     @"S" : [NSNumber numberWithDouble:S],
                                                                                     @"timestamp" : [NSNumber numberWithDouble:timestamp]
                                                                                 }];
     }];

}

RCT_EXPORT_METHOD(stopUpdates) {
    NSLog(@"stopUpdates");
    [self->_motionManager stopLightUpdates];
}

- (void)initCamera {
    self.captureSession = [[AVCaptureSession alloc] init];
    self.captureSession .sessionPreset = AVCaptureSessionPresetMedium;
    
    AVCaptureVideoPreviewLayer *captureVideoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession ];
    
    captureVideoPreviewLayer.frame = self.cameraView.layer.bounds;
    [self.cameraView.layer addSublayer:captureVideoPreviewLayer];
    
    AVCaptureDevice *device =  [self cameraWithPosition:AVCaptureDevicePositionFront];
    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    _currentCameraPosition = device.position;
    
    if (!input) {
        // Handle the error appropriately.
        NSLog(@"ERROR: trying to open camera: xxxx %@", error);
    }
    
    [self.captureSession  addInput:input];
    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureSession  addOutput:output];
    
    output.videoSettings = @{ (NSString *)kCVPixelBufferPixelFormatTypeKey : @(kCVPixelFormatType_32BGRA) };
    
    dispatch_queue_t queue = dispatch_queue_create("VideoQueue", DISPATCH_QUEUE_SERIAL);
    
    [output setSampleBufferDelegate:self queue:queue];
    
    [self.captureSession  startRunning];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSDictionary *exifDictionary = (__bridge NSDictionary*)CMGetAttachment(sampleBuffer, kCGImagePropertyExifDictionary, NULL);
    
    
    //      NSLog(@"%@",exifDictionary);
    double C = 2.0f;
    double N = [exifDictionary[@"FNumber"] doubleValue];
    double t = [exifDictionary[@"ExposureTime"] doubleValue];
    double S = [exifDictionary[@"ISOSpeedRatings"][0] doubleValue];
    double lux = (C * N *N ) / ( t * S);
    lux -= 0.09;
    lux = lux <= 0 ? 0 : lux;
    lux = lux *10;
    lux *= sliderValue;
    
//    NSLog(@"slider_value %lf",sliderValue);
//    NSLog(@"lux %lf",lux);
    _totalLux = lux;

    [self.bridge.eventDispatcher sendDeviceEventWithName:@"Lightscope" body:@{
                                                                            @"C" : [NSNumber numberWithDouble:C],
                                                                            @"N" : [NSNumber numberWithDouble:N],
                                                                            @"t" : [NSNumber numberWithDouble:t],
                                                                            @"S" : [NSNumber numberWithDouble:S],
                                                                            @"timestamp" : [NSNumber numberWithDouble:timestamp]
                                                                        }];
    
}

- (AVCaptureDevice *) cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)    {
        if ([device position] == position) return device;
    }
    return nil;
}

@end
