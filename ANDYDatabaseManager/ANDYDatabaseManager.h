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

/*!
 * Provides a NSManagedObjectContext appropriate for use on the main
 * thread.
 */
@property (strong, nonatomic, readonly) NSManagedObjectContext *mainContext;

/*!
 * Provides a singleton that handles CoreData related operations.
 * \returns The a shared ANDYDatabaseManager for the application.
 */
+ (ANDYDatabaseManager *)sharedManager;

/*!
 * Provides a new privateContext bound to the mainContext for a
 * performant background operation.
 * \returns A background NSManagedObjectContext.
 */
+ (NSManagedObjectContext *)privateContext;

/*!
 * Configures a stack with InMemoryStore for testing purposes.
 */
+ (void)setUpStackWithInMemoryStore;

/*!
 * Saves current state of mainContext into the database.
 */
- (void)persistContext;

/*!
 * Resets state of ANDYDatabaseManager.
 */
- (void)reset;

@end