//
//  AppDelegate.mm
//  MacCameraStreamer
//
//  Created by Jagadish Paul on 28/07/25.
//


//#import <Cocoa/Cocoa.h>
//#import <AVFoundation/AVFoundation.h>
//#import "AppDelegate.h"
//#import "SharedCameraBuffer.hpp"
//
//NSString* SharedBufferPath() {
//    return [@"~/camera_shared_buffer" stringByExpandingTildeInPath];
//}
//
//@interface AppDelegate () <AVCaptureVideoDataOutputSampleBufferDelegate> {
//    AVCaptureSession *session;
//    SharedCameraBuffer sharedBuffer;
//    NSString *path;
//    dispatch_queue_t writeQueue;
//    CMTime lastFrameTime;
//}
//@end
//
//@implementation AppDelegate
//
//- (void)applicationDidFinishLaunching:(NSNotification *)notification {
//    path = SharedBufferPath();
//
//    if (!sharedBuffer.initialize(true, [path UTF8String])) {
//        NSLog(@"❌ Failed to initialize shared memory (%@)", path);
//        exit(1);
//    }
//
//    writeQueue = dispatch_queue_create("shared.write.queue", DISPATCH_QUEUE_SERIAL);
//    lastFrameTime = kCMTimeZero;
//
//    session = [[AVCaptureSession alloc] init];
//
//    if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
//        session.sessionPreset = AVCaptureSessionPreset1280x720;
//    } else {
//        session.sessionPreset = AVCaptureSessionPreset640x480;
//    }
//
//    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
//    if (!device) {
//        NSLog(@"❌ No camera found");
//        exit(1);
//    }
//
//    NSError *error = nil;
//    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
//    if (!input || error) {
//        NSLog(@"❌ Camera input error: %@", error.localizedDescription);
//        exit(1);
//    }
//
//    if ([session canAddInput:input]) {
//        [session addInput:input];
//    }
//
//    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
//    output.videoSettings = @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) };
//    [output setSampleBufferDelegate:self queue:dispatch_queue_create("cam.queue", DISPATCH_QUEUE_SERIAL)];
//
//    if ([session canAddOutput:output]) {
//        [session addOutput:output];
//    }
//
//    [session startRunning];
//    NSLog(@"✅ Camera streaming started to shared memory at %@", path);
//}
//
//- (void)captureOutput:(AVCaptureOutput *)output
//didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
//       fromConnection:(AVCaptureConnection *)connection {
//
//    CMTime current = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
//    Float64 delta = CMTimeGetSeconds(CMTimeSubtract(current, lastFrameTime));
//
//    if (delta < (1.0 / 30.0)) {
//        return; // Skip frame
//    }
//
//    lastFrameTime = current;
//
//    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
//    CVPixelBufferLockBaseAddress(imageBuffer, 0);
//
//    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
//    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
//    size_t height = CVPixelBufferGetHeight(imageBuffer);
//
//    if (baseAddress && bytesPerRow >= WIDTH * CHANNELS && height >= HEIGHT) {
//        const uint8_t *frameData = (const uint8_t *)malloc(FRAME_SIZE);
//        memcpy((void *)frameData, baseAddress, FRAME_SIZE);
//
//        dispatch_async(writeQueue, ^{
//            sharedBuffer.writeFrame(frameData);
//            free((void *)frameData);
//        });
//    }
//
//    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
//}
//
//- (void)applicationWillTerminate:(NSNotification *)notification {
//    [session stopRunning];
//    sharedBuffer.cleanup();
//    NSLog(@"🛑 Camera stopped and shared buffer cleaned");
//}
//
//@end
//
//int main(int argc, const char * argv[]) {
//    return NSApplicationMain(argc, argv);
//}


#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "AppDelegate.h"
#import "SharedCameraBuffer.hpp"

NSString* SharedBufferPath() {
    return [@"~/camera_shared_buffer" stringByExpandingTildeInPath];
}

@interface AppDelegate () <AVCaptureVideoDataOutputSampleBufferDelegate> {
    AVCaptureSession *session;
    SharedCameraBuffer sharedBuffer;
    NSString *path;
    dispatch_queue_t writeQueue;
    CMTime lastFrameTime;
}
@property (strong, nonatomic) NSStatusItem *statusItem;
@property (assign, nonatomic) BOOL isStreaming;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification {
    path = SharedBufferPath();

    if (!sharedBuffer.initialize(true, [path UTF8String])) {
        NSLog(@"❌ Failed to initialize shared memory (%@)", path);
        exit(1);
    }

    writeQueue = dispatch_queue_create("shared.write.queue", DISPATCH_QUEUE_SERIAL);
    lastFrameTime = kCMTimeZero;
    self.isStreaming = NO;

    // ✅ Setup menu bar item
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.button.title = @"📷";

    NSMenu *menu = [[NSMenu alloc] init];
    [menu addItemWithTitle:@"Start Camera" action:@selector(toggleCamera:) keyEquivalent:@""];
    [menu addItem:[NSMenuItem separatorItem]];
    [menu addItemWithTitle:@"Quit" action:@selector(quitApp:) keyEquivalent:@"q"];
    self.statusItem.menu = menu;

    NSLog(@"✅ Menu bar item created. Use it to start/stop camera.");
}

#pragma mark - Menu Actions

- (void)toggleCamera:(NSMenuItem *)sender {
    if (self.isStreaming) {
        [session stopRunning];
        NSLog(@"🛑 Camera stopped");
        self.isStreaming = NO;
        sender.title = @"Start Camera";
    } else {
        [self setupSession];
        [session startRunning];
        NSLog(@"✅ Camera streaming started to shared memory at %@", path);
        self.isStreaming = YES;
        sender.title = @"Stop Camera";
    }
}

- (void)quitApp:(id)sender {
    if (self.isStreaming) {
        [session stopRunning];
    }
    sharedBuffer.cleanup();
    [NSApp terminate:nil];
}

#pragma mark - Camera Setup

- (void)setupSession {
    if (session) return; // already created
    session = [[AVCaptureSession alloc] init];

    if ([session canSetSessionPreset:AVCaptureSessionPreset1280x720]) {
        session.sessionPreset = AVCaptureSessionPreset1280x720;
    } else {
        session.sessionPreset = AVCaptureSessionPreset640x480;
    }

    AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    if (!device) {
        NSLog(@"❌ No camera found");
        return;
    }

    NSError *error = nil;
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
    if (!input || error) {
        NSLog(@"❌ Camera input error: %@", error.localizedDescription);
        return;
    }

    if ([session canAddInput:input]) {
        [session addInput:input];
    }

    AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
    output.videoSettings = @{ (__bridge NSString *)kCVPixelBufferPixelFormatTypeKey: @(kCVPixelFormatType_32BGRA) };
    [output setSampleBufferDelegate:self queue:dispatch_queue_create("cam.queue", DISPATCH_QUEUE_SERIAL)];

    if ([session canAddOutput:output]) {
        [session addOutput:output];
    }
}

#pragma mark - Capture Delegate

- (void)captureOutput:(AVCaptureOutput *)output
didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer
       fromConnection:(AVCaptureConnection *)connection {

    CMTime current = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
    Float64 delta = CMTimeGetSeconds(CMTimeSubtract(current, lastFrameTime));

    if (delta < (1.0 / 30.0)) {
        return; // Skip frame
    }

    lastFrameTime = current;

    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    if (baseAddress && bytesPerRow >= WIDTH * CHANNELS && height >= HEIGHT) {
        const uint8_t *frameData = (const uint8_t *)malloc(FRAME_SIZE);
        memcpy((void *)frameData, baseAddress, FRAME_SIZE);

        dispatch_async(writeQueue, ^{
            self->sharedBuffer.writeFrame(frameData);
            free((void *)frameData);
        });
    }

    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
}

- (void)applicationWillTerminate:(NSNotification *)notification {
    if (self.isStreaming) {
        [session stopRunning];
    }
    sharedBuffer.cleanup();
    NSLog(@"🛑 Camera stopped and shared buffer cleaned");
}

@end

int main(int argc, const char * argv[]) {
    return NSApplicationMain(argc, argv);
}
