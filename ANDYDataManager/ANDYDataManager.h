@import Foundation;
@import CoreData;

@interface ANDYDataManager : NSObject

/*!
 * Provides a singleton that handles CoreData related operations.
 * \returns The a shared ANDYDataManager for the application.
 */
+ (ANDYDataManager *)sharedManager;

/*!
 * Configures a stack with InMemoryStore for testing purposes.
 */
+ (void)setUpStackWithInMemoryStore;

/*!
 * Sets the model name in case it's different from the bundle name
 */
+ (void)setModelName:(NSString *)modelName;

/*!
 * Sets the model bundle in case it's different from the main bundle
 */
+ (void)setModelBundle:(NSBundle *)modelBundle;

/*!
 * Provides a NSManagedObjectContext appropriate for use on the main
 * thread.
 */
- (NSManagedObjectContext *)mainThreadContext;

/*!
 * Provides a safe way to perform an operation in a background
 * operation by using a context.
 */
- (void)performInBackgroundContext:(void (^)(NSManagedObjectContext *context))operation;

/*!
 * Saves current state of mainContext into the database.
 */
- (void)persistContext;

/*!
 * Destroys state of ANDYDataManager.
 */
- (void)destroy;

@end
