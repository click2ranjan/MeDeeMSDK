//
//  MeDeeMFramework.h
//  MeDeeMFramework
//
//  Created by Ranjan on 8/9/13.
//  Copyright (c) 2013 Orion. All rights reserved.
//

#import <Foundation/Foundation.h>

@class EventQueue;

@interface MeDeeMFramework : NSObject {
	double unsentSessionLength;
	NSTimer *timer;
	double lastTime;
	BOOL isSuspended;
    EventQueue *eventQueue;
}

+ (MeDeeMFramework *)sharedInstance;

- (void)start:(NSString *)appKey withHost:(NSString *)appHost;

- (void)recordEvent:(NSString *)key count:(int)count;

- (void)recordEvent:(NSString *)key count:(int)count sum:(double)sum;

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(int)count;

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(int)count sum:(double)sum;

@end