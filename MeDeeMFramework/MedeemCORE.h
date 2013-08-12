//
//  MedeemCORE.h
//  MeDeeMSDK
//
//  Created by Ranjan on 8/9/13.
//  Copyright (c) 2013 Orion. All rights reserved.
//

//THIS CLASS IS ONLY FOR DATABASE COMMUNICATIONS / OFFLINE DATA STORAGE / DATA SYNCHRONISATION

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface MedeemCORE : NSObject

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

+(MedeemCORE*) sharedInstance;

-(void)createEvent:(NSString*) eventKey count:(double)count sum:(double)sum segmentation:(NSDictionary*)segmentation timestamp:(double)timestamp;
-(void)addToQueue:(NSString*)postData;
-(void)deleteEvent:(NSManagedObject*)eventObj;
-(void)removeFromQueue:(NSManagedObject*)postDataObj;
-(NSArray*) getEvents;
-(NSArray*) getQueue;
-(NSUInteger)getEventCount;
-(NSUInteger)getQueueCount;
- (void)saveContext;

@end
