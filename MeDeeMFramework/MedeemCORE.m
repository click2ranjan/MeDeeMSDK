//
//  MedeemCORE.m
//  MeDeeMSDK
//
//  Created by Ranjan on 8/9/13.
//  Copyright (c) 2013 Orion. All rights reserved.
//
//THIS CLASS IS ONLY FOR DATABASE COMMUNICATIONS / OFFLINE DATA STORAGE / DATA SYNCHRONISATION

#import "MedeemCORE.h"


@interface MedeemCORE()
- (NSURL *)applicationDocumentsDirectory;
@end


// This class inludes all the informations related to EVENTS and SESSIONS

@implementation MedeemCORE


@synthesize managedObjectContext = _managedObjectContext;
@synthesize managedObjectModel = _managedObjectModel;
@synthesize persistentStoreCoordinator = _persistentStoreCoordinator;

//---*******************************-----SHARED INSTANCE

+(MedeemCORE*) sharedInstance{
    static MedeemCORE* _sharedInstance;
    if (!_sharedInstance) _sharedInstance = [[MedeemCORE alloc] init];
    return _sharedInstance;
}


//---*******************************-----CREATE EVENTS AND GET EVENT-ID'S

-(void)createEvent:(NSString*) eventKey count:(double)count sum:(double)sum segmentation:(NSDictionary*)segmentation timestamp:(double)timestamp{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Event" inManagedObjectContext:context];
    
    [newManagedObject setValue:eventKey forKey:@"key"];
    [newManagedObject setValue:[NSNumber numberWithDouble:count] forKey:@"count"];
    [newManagedObject setValue:[NSNumber numberWithDouble:sum] forKey:@"sum"];
    [newManagedObject setValue:[NSNumber numberWithDouble:timestamp] forKey:@"timestamp"];
    [newManagedObject setValue:segmentation forKey:@"segmentation"];
    
    [self saveContext];
}

//---*******************************-----DELETE EVENTS
-(void)deleteEvent:(NSManagedObject*)eventObj{
    NSManagedObjectContext *context = [self managedObjectContext];
    [context deleteObject:eventObj];
    [self saveContext];
}

//---*******************************-----ADD TO QUEUE

-(void)addToQueue:(NSString*)postData{
    NSManagedObjectContext *context = [self managedObjectContext];
    NSManagedObject *newManagedObject = [NSEntityDescription insertNewObjectForEntityForName:@"Data" inManagedObjectContext:context];
    
    [newManagedObject setValue:postData forKey:@"post"];
    
    [self saveContext];
}

//---*******************************-----REMOVE FROM QUEUE

-(void)removeFromQueue:(NSManagedObject*)postDataObj{
    NSManagedObjectContext *context = [self managedObjectContext];
    [context deleteObject:postDataObj];
    [self saveContext];
}

//---*******************************-----GET EVENTS

-(NSArray*) getEvents{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError* error = nil;
    NSArray* result = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error){
        //MEDEEM_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return result;
}

//---*******************************-----GET FROM QUEUE

-(NSArray*) getQueue{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Data" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError* error = nil;
    NSArray* result = [_managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (!error){
       //MEDEEM_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return result;
}

//---*******************************-----GET COUNT LIST OF EVENTS

-(NSUInteger)getEventCount{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Event" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError* error = nil;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (!error){
        //MEDEEM_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    return count;
}

//---*******************************-----GET COUNT LIST OF QUEUE

-(NSUInteger)getQueueCount{
    NSFetchRequest *fetchRequest = [[[NSFetchRequest alloc] init] autorelease];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Data" inManagedObjectContext:self.managedObjectContext];
    [fetchRequest setEntity:entity];
    
    NSError* error = nil;
    NSUInteger count = [_managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (!error){
        //MEDEEM_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    return count;
}

//---*******************************-----SAVING DATA TO CORE DATABASE

- (void)saveContext{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
           // MEDEEM_LOG(@"Unresolved error %@, %@", error, [error userInfo]);
        }
    }
}

- (NSURL *)applicationDocumentsDirectory{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}


#pragma mark - Core Data stack

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.

- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}


// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:@"medeemdb" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:@"medeem.sqlite"];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
    }
    
    return _persistentStoreCoordinator;
}


@end
