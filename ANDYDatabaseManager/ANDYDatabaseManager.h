//
//  ANDYDatabaseManager.h
//  Andy
//
//  Created by Elvis Nunez on 10/29/13.
//  Copyright (c) 2013 Andy. All rights reserved.
//

@import Foundation;
@import CoreData;

@interface ANDYDatabaseManager : NSObject
@property (strong, nonatomic, readonly) NSManagedObjectContext *mainContext;

+ (ANDYDatabaseManager *)sharedManager;
+ (NSManagedObjectContext *)privateContext;
- (void)saveContext;
- (void)persistContext;

@end