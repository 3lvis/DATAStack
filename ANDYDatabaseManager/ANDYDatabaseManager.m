//
//  ANDYDatabaseManager.m
//  Andy
//
//  Created by Elvis Nunez on 10/29/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

#import "ANDYDatabaseManager.h"
@import UIKit;

@interface ANDYDatabaseManager ()
@property (strong, nonatomic, readwrite) NSManagedObjectContext *mainContext;
@property (strong, nonatomic) NSManagedObjectContext *writerContext;
@property (strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@end

@implementation ANDYDatabaseManager

+ (ANDYDatabaseManager *)sharedManager
{
    static ANDYDatabaseManager *__sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        __sharedInstance = [[ANDYDatabaseManager alloc] init];
        [__sharedInstance setUpSaveNotification];
    });
    
    return __sharedInstance;
}

- (void)setUpSaveNotification
{
    [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification
                                                      object:nil
                                                       queue:nil
                                                  usingBlock:^(NSNotification* note) {
                                                      NSManagedObjectContext *moc = self.mainContext;
                                                      if (note.object != moc) {
                                                          [moc performBlock:^(){
                                                              [moc mergeChangesFromContextDidSaveNotification:note];
                                                          }];
                                                      }
                                                  }];
}

- (void)saveContext
{
    NSManagedObjectContext *managedObjectContext = self.mainContext;
    [managedObjectContext performBlock:^{
        if (managedObjectContext != nil) {
            NSError *error = nil;
            if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
                NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
                abort();
            }
        }
    }];
}

- (void)persistContext
{
    NSManagedObjectContext *writerManagedObjectContext = self.writerContext;
    NSManagedObjectContext *managedObjectContext = self.mainContext;
    
    [managedObjectContext performBlock:^{
        NSError *error = nil;
        if ([managedObjectContext save:&error]) {
            
            [writerManagedObjectContext performBlock:^{
                NSError *parentError = nil;
                if (![writerManagedObjectContext save:&parentError]) {
                    NSLog(@"Unresolved error saving parent managed object context %@, %@", error, [error userInfo]);
                    abort();
                }
            }];
        } else {
            NSLog(@"Unresolved error saving managed object context %@, %@", error, [error userInfo]);
            abort();
        }
    }];
}

#if !TARGET_IPHONE_SIMULATOR
- (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    return [URL setResourceValue:[NSNumber numberWithBool:YES] forKey:NSURLIsExcludedFromBackupKey error:nil];
}
#endif

#pragma mark - Core Data stack

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext) {
        return _mainContext;
    }

    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.undoManager = nil;
    _mainContext.parentContext = self.writerContext;
    return _mainContext;
}

- (NSManagedObjectContext *)writerContext
{
    if (_writerContext) {
        return _writerContext;
    }

    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    _writerContext.undoManager = nil;
    [_writerContext setPersistentStoreCoordinator:self.persistentStoreCoordinator];
    return _writerContext;
}

- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:[self appName] withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = nil;
    
    NSString *filePath = [NSString stringWithFormat:@"%@.sqlite", [self appName]];
    storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filePath];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption: @YES, NSInferMappingModelAutomaticallyOption: @YES};
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
        
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error]) {
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
        
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Error encountered while reading the database. Please allow all the data to download again.", @"[Error] Message to show when the database is corrupted") message:nil delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    }
    
#if !TARGET_IPHONE_SIMULATOR
    [self addSkipBackupAttributeToItemAtURL:storeURL];
#endif
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

- (NSString *)appName
{
    NSString *string = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    NSString *trimmedString = [string stringByTrimmingCharactersInSet:
                               [NSCharacterSet whitespaceCharacterSet]];
    return trimmedString;
}

#pragma mark - Class methods

+ (NSManagedObjectContext *)privateContext
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    context.persistentStoreCoordinator = [[self sharedManager] persistentStoreCoordinator];
    context.undoManager = nil;
    return context;
}

@end