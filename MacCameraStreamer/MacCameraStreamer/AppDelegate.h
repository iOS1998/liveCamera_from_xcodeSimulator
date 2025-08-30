//
//  AppDelegate.h
//  MacCameraStreamer
//
//  Created by Jagadish Paul on 28/07/25.
//

#import <Cocoa/Cocoa.h>

#import <Cocoa/Cocoa.h>
#import <AVFoundation/AVFoundation.h>
#import "SharedCameraBuffer.hpp"

@interface AppDelegate : NSObject <NSApplicationDelegate, AVCaptureVideoDataOutputSampleBufferDelegate>
@end

