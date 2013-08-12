//
//  MeDeeMFramework.m
//  MeDeeMFramework
//
//  Created by Ranjan on 8/9/13.
//  Copyright (c) 2013 Orion. All rights reserved.
//


#ifndef MEDEEM_DEBUG
#define MEDEEM_DEBUG 0
#endif

#ifndef MEDEEM_IGNORE_INVALID_CERTIFICATES
#define MEDEEM_IGNORE_INVALID_CERTIFICATES 1
#endif

#if MEDEEM_DEBUG
#   define MEDEEM_LOG(fmt, ...) NSLog(fmt, ##__VA_ARGS__)
#else
#   define MEDEEM_LOG(...)
#endif

#define MEDEEM_VERSION "1.0"

#import <UIKit/UIKit.h>
#import "MeDeeMFramework.h"
#import "MedeemCORE.h"
#include <sys/types.h>
#include <sys/sysctl.h>
#import "ProtocolBuffers.h"
#import "Protocol.pb.h"
#import <CoreTelephony/CTTelephonyNetworkInfo.h>
#import <CoreTelephony/CTCarrier.h>

@implementation MeDeeMFramework


//--***************PROCESS GOES TO BACKGROUND

- (void)didEnterBackgroundCallBack:(NSNotification *)notification
{
	//MEDEEM_LOG(@"Medeem didEnterBackgroundCallBack");
	[self suspend];
    
}

//--***************PROCESS GOES TO FOREGROUND

- (void)willEnterForegroundCallBack:(NSNotification *)notification
{
	//MEDEEM_LOG(@"Medeem willEnterForegroundCallBack");
	[self resume];
}

//--***************PROCESS GOES TO TERMINATING

- (void)willTerminateCallBack:(NSNotification *)notification
{
	//MEDEEM_LOG(@"Medeem willTerminateCallBack");
    [[MedeemCORE sharedInstance] saveContext];
	[self exit];
}


@interface DeviceInfo : NSObject
{
}
@end

@implementation DeviceInfo

+ (NSString *)udid
{
	return [Medeem_OpenUDID value];
}

+ (NSString *)device
{
    size_t size;
    sysctlbyname("hw.machine", NULL, &size, NULL, 0);
    char *machine = malloc(size);
    sysctlbyname("hw.machine", machine, &size, NULL, 0);
    NSString *platform = [NSString stringWithUTF8String:machine];
    free(machine);
    return platform;
}

+ (NSString *)osVersion
{
	return [[UIDevice currentDevice] systemVersion];
}

+ (NSString *)carrier
{
	if (NSClassFromString(@"CTTelephonyNetworkInfo"))
	{
		CTTelephonyNetworkInfo *netinfo = [[[CTTelephonyNetworkInfo alloc] init] autorelease];
		CTCarrier *carrier = [netinfo subscriberCellularProvider];
		return [carrier carrierName];
	}
    
	return nil;
}

+ (NSString *)resolution
{
	CGRect bounds = [[UIScreen mainScreen] bounds];
	CGFloat scale = [[UIScreen mainScreen] respondsToSelector:@selector(scale)] ? [[UIScreen mainScreen] scale] : 1.f;
	CGSize res = CGSizeMake(bounds.size.width * scale, bounds.size.height * scale);
	NSString *result = [NSString stringWithFormat:@"%gx%g", res.width, res.height];
    
	return result;
}

+ (NSString *)locale
{
	return [[NSLocale currentLocale] localeIdentifier];
}

+ (NSString *)appVersion
{
    NSString *result = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"];
    if ([result length] == 0)
        result = [[NSBundle mainBundle] objectForInfoDictionaryKey:(NSString*)kCFBundleVersionKey];
    
    return result;
}

+ (NSString *)metrics
{
	NSString *result = @"{";
    
	result = [result stringByAppendingFormat:@"\"%@\":\"%@\"", @"_device", [DeviceInfo device]];
    
	result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_os", @"iOS"];
    
	result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_os_version", [DeviceInfo osVersion]];
    
	NSString *carrier = [DeviceInfo carrier];
	if (carrier != nil)
		result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_carrier", carrier];
    
	result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_resolution", [DeviceInfo resolution]];
    
	result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_locale", [DeviceInfo locale]];
    
	result = [result stringByAppendingFormat:@",\"%@\":\"%@\"", @"_app_version", [DeviceInfo appVersion]];
    
	result = [result stringByAppendingString:@"}"];
    
	result = [result gtm_stringByEscapingForURLArgument];
    
	return result;
}

@end


@interface MedeemEvent : NSObject
{
}

@property (nonatomic, copy) NSString *key;
@property (nonatomic, retain) NSDictionary *segmentation;
@property (nonatomic, assign) int count;
@property (nonatomic, assign) double sum;
@property (nonatomic, assign) double timestamp;

@end

@implementation MedeemEvent

@synthesize key = key_;
@synthesize segmentation = segmentation_;
@synthesize count = count_;
@synthesize sum = sum_;
@synthesize timestamp = timestamp_;

- (id)init
{
    if (self = [super init])
    {
        key_ = nil;
        segmentation_ = nil;
        count_ = 0;
        sum_ = 0;
        timestamp_ = 0;
    }
    return self;
}

- (void)dealloc
{
    [key_ release];
    [segmentation_ release];
    [super dealloc];
}

@end



@interface EventQueue : NSObject

@end


@implementation EventQueue

- (void)dealloc
{
    [super dealloc];
}

- (NSUInteger)count
{
    @synchronized (self)
    {
        return [[CountlyDB sharedInstance] getEventCount];
    }
}


- (NSString *)events
{
    NSString *result = @"[";
    
    @synchronized (self)
    {
        NSArray* events = [[[CountlyDB sharedInstance] getEvents] copy];
        for (NSUInteger i = 0; i < events.count; ++i)
        {
            
            CountlyEvent *event = [self convertNSManagedObjectToCountlyEvent:[events objectAtIndex:i]];
            
            result = [result stringByAppendingString:@"{"];
            
            result = [result stringByAppendingFormat:@"\"%@\":\"%@\"", @"key", event.key];
            
            if (event.segmentation)
            {
                NSString *segmentation = @"{";
                
                NSArray *keys = [event.segmentation allKeys];
                for (NSUInteger i = 0; i < keys.count; ++i)
                {
                    NSString *key = [keys objectAtIndex:i];
                    NSString *value = [event.segmentation objectForKey:key];
                    
                    segmentation = [segmentation stringByAppendingFormat:@"\"%@\":\"%@\"", key, value];
                    
                    if (i + 1 < keys.count)
                        segmentation = [segmentation stringByAppendingString:@","];
                }
                segmentation = [segmentation stringByAppendingString:@"}"];
                
                result = [result stringByAppendingFormat:@",\"%@\":%@", @"segmentation", segmentation];
            }
            
            result = [result stringByAppendingFormat:@",\"%@\":%d", @"count", event.count];
            
            if (event.sum > 0)
                result = [result stringByAppendingFormat:@",\"%@\":%g", @"sum", event.sum];
            
            result = [result stringByAppendingFormat:@",\"%@\":%ld", @"timestamp", (time_t)event.timestamp];
            
            result = [result stringByAppendingString:@"}"];
            
            if (i + 1 < events.count)
                result = [result stringByAppendingString:@","];
            
            [[CountlyDB sharedInstance] removeFromQueue:[events objectAtIndex:i]];
            
        }
        
        [events release];
        
    }
    
    result = [result stringByAppendingString:@"]"];
    
    result = [result gtm_stringByEscapingForURLArgument];
    
	return result;
}

-(CountlyEvent*) convertNSManagedObjectToCountlyEvent:(NSManagedObject*)managedObject{
    CountlyEvent* event = [[CountlyEvent alloc] init];
    event.key = [managedObject valueForKey:@"key"];
    if ([managedObject valueForKey:@"count"])
        event.count = ((NSNumber*) [managedObject valueForKey:@"count"]).doubleValue;
    if ([managedObject valueForKey:@"sum"])
        event.sum = ((NSNumber*) [managedObject valueForKey:@"sum"]).doubleValue;
    if ([managedObject valueForKey:@"timestamp"])
        event.timestamp = ((NSNumber*) [managedObject valueForKey:@"timestamp"]).doubleValue;
    if ([managedObject valueForKey:@"segmentation"])
        event.segmentation = [managedObject valueForKey:@"segmentation"];
    return event;
}

- (void)recordEvent:(NSString *)key count:(int)count
{
    @synchronized (self)
    {
        NSArray* events = [[CountlyDB sharedInstance] getEvents];
        for (NSManagedObject* obj in events)
        {
            CountlyEvent *event = [self convertNSManagedObjectToCountlyEvent:obj];
            if ([event.key isEqualToString:key])
            {
                event.count += count;
                event.timestamp = (event.timestamp + time(NULL)) / 2;
                
                [obj setValue:[NSNumber numberWithDouble:event.count] forKey:@"count"];
                [obj setValue:[NSNumber numberWithDouble:event.timestamp] forKey:@"timestamp"];
                
                [[CountlyDB sharedInstance] saveContext];
                return;
            }
        }
        
        CountlyEvent *event = [[CountlyEvent alloc] init];
        event.key = key;
        event.count = count;
        event.timestamp = time(NULL);
        
        [[CountlyDB sharedInstance] createEvent:event.key count:event.count sum:event.sum segmentation:event.segmentation timestamp:event.timestamp];
        
        [event release];
    }
}

- (void)recordEvent:(NSString *)key count:(int)count sum:(double)sum
{
    @synchronized (self)
    {
        NSArray* events = [[CountlyDB sharedInstance] getEvents];
        for (NSManagedObject* obj in events)
        {
            CountlyEvent *event = [self convertNSManagedObjectToCountlyEvent:obj];
            if ([event.key isEqualToString:key])
            {
                event.count += count;
                event.sum += sum;
                event.timestamp = (event.timestamp + time(NULL)) / 2;
                
                [obj setValue:[NSNumber numberWithDouble:event.count] forKey:@"count"];
                [obj setValue:[NSNumber numberWithDouble:event.sum] forKey:@"sum"];
                [obj setValue:[NSNumber numberWithDouble:event.timestamp] forKey:@"timestamp"];
                
                [[CountlyDB sharedInstance] saveContext];
                
                return;
            }
        }
        
        CountlyEvent *event = [[CountlyEvent alloc] init];
        event.key = key;
        event.count = count;
        event.sum = sum;
        event.timestamp = time(NULL);
        
        [[CountlyDB sharedInstance] createEvent:event.key count:event.count sum:event.sum segmentation:event.segmentation timestamp:event.timestamp];
        
        [event release];
    }
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(int)count;
{
    @synchronized (self)
    {
        
        NSArray* events = [[CountlyDB sharedInstance] getEvents];
        for (NSManagedObject* obj in events)
        {
            CountlyEvent *event = [self convertNSManagedObjectToCountlyEvent:obj];
            if ([event.key isEqualToString:key] &&
                event.segmentation && [event.segmentation isEqualToDictionary:segmentation])
            {
                event.count += count;
                event.timestamp = (event.timestamp + time(NULL)) / 2;
                
                [obj setValue:[NSNumber numberWithDouble:event.count] forKey:@"count"];
                [obj setValue:[NSNumber numberWithDouble:event.timestamp] forKey:@"timestamp"];
                
                [[CountlyDB sharedInstance] saveContext];
                
                return;
            }
        }
        
        CountlyEvent *event = [[CountlyEvent alloc] init];
        event.key = key;
        event.segmentation = segmentation;
        event.count = count;
        event.timestamp = time(NULL);
        
        [[CountlyDB sharedInstance] createEvent:event.key count:event.count sum:event.sum segmentation:event.segmentation timestamp:event.timestamp];
        
        [event release];
    }
}

- (void)recordEvent:(NSString *)key segmentation:(NSDictionary *)segmentation count:(int)count sum:(double)sum;
{
    @synchronized (self)
    {
        
        NSArray* events = [[[CountlyDB sharedInstance] getEvents] copy];
        for (NSManagedObject* obj in events)
        {
            CountlyEvent *event = [self convertNSManagedObjectToCountlyEvent:obj];
            if ([event.key isEqualToString:key] &&
                event.segmentation && [event.segmentation isEqualToDictionary:segmentation])
            {
                event.count += count;
                event.sum += sum;
                event.timestamp = (event.timestamp + time(NULL)) / 2;
                
                [obj setValue:[NSNumber numberWithDouble:event.count] forKey:@"count"];
                [obj setValue:[NSNumber numberWithDouble:event.sum] forKey:@"sum"];
                [obj setValue:[NSNumber numberWithDouble:event.timestamp] forKey:@"timestamp"];
                
                [[CountlyDB sharedInstance] saveContext];
                
                return;
            }
        }
        
        CountlyEvent *event = [[CountlyEvent alloc] init];
        event.key = key;
        event.segmentation = segmentation;
        event.count = count;
        event.sum = sum;
        event.timestamp = time(NULL);
        
        [[CountlyDB sharedInstance] createEvent:event.key count:event.count sum:event.sum segmentation:event.segmentation timestamp:event.timestamp];
        
        [event release];
    }
}

@end




@end
