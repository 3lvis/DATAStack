#import "DATAStackOld.h"

@import TestCheck;

@interface DATAStackOld ()

@property (nonatomic) NSManagedObjectContext *mainContext;
@property (nonatomic) NSManagedObjectContext *disposableMainContext;
@property (nonatomic) NSManagedObjectContext *writerContext;
@property (nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (nonatomic) NSPersistentStoreCoordinator *disposablePersistentStoreCoordinator;

@property (nonatomic) DATAStackStoreType storeType;
@property (nonatomic, copy) NSString *modelName;
@property (nonatomic) NSBundle *modelBundle;

@end

@implementation DATAStackOld

#pragma mark - Initializers

- (instancetype)init
{
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *bundleName = [[bundle infoDictionary] objectForKey:@"CFBundleName"];

    return [self initWithModelName:bundleName];
}

- (instancetype)initWithModelName:(NSString *)modelName
{
    NSBundle *bundle = [NSBundle mainBundle];

    return [self initWithModelName:modelName
                            bundle:bundle
                         storeType:DATAStackSQLiteStoreType];
}

- (instancetype)initWithModelName:(NSString *)modelName
                           bundle:(NSBundle *)bundle
                        storeType:(DATAStackStoreType)storeType
{
    self = [super init];
    if (!self) return nil;

    _modelName = modelName;
    _modelBundle = bundle;
    _storeType = storeType;

    if (!self.persistentStoreCoordinator) NSLog(@"Error setting up data stack");

    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:NSManagedObjectContextDidSaveNotification
                                                  object:nil];
}

#pragma mark - Getters

- (NSManagedObjectContext *)mainContext
{
    if (_mainContext) return _mainContext;

    _mainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _mainContext.undoManager = nil;
    _mainContext.parentContext = self.writerContext;
    _mainContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    return _mainContext;
}

- (NSManagedObjectContext *)writerContext
{
    if (_writerContext) return _writerContext;

    _writerContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:[self backgroundConcurrencyType]];
    _writerContext.undoManager = nil;
    _writerContext.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;
    _writerContext.persistentStoreCoordinator = self.persistentStoreCoordinator;

    return _writerContext;
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator) return _persistentStoreCoordinator;

    NSString *filePath = [NSString stringWithFormat:@"%@.sqlite", self.modelName];
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:filePath];

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
    if (![[NSFileManager defaultManager] fileExistsAtPath:[storeURL path]]) {
        NSString *preloadedPath = [[NSBundle mainBundle] pathForResource:self.modelName ofType:@"sqlite"];
        if (preloadedPath) {
            NSURL *preloadURL = [NSURL fileURLWithPath:preloadedPath];
            NSError *error = nil;

            if (![[NSFileManager defaultManager] copyItemAtURL:preloadURL toURL:storeURL error:&error]) {
                NSLog(@"Oops, could not copy preloaded data. Error: %@", [error description]);
            }
        }
    }
#pragma clang diagnostic pop

    NSDictionary *options = @{ NSMigratePersistentStoresAutomaticallyOption: @YES,
                               NSInferMappingModelAutomaticallyOption: @YES };

    NSString *storeType;

    switch (self.storeType) {
        case DATAStackInMemoryStoreType: {
            storeType = NSInMemoryStoreType;
            storeURL = nil;
            options = nil;
        } break;
        case DATAStackSQLiteStoreType:
        storeType = NSSQLiteStoreType;
        break;
    }

    NSBundle *bundle = (self.modelBundle) ?: [NSBundle mainBundle];
    NSURL *modelURL = [bundle URLForResource:self.modelName withExtension:@"momd"];
    if (!modelURL) {
        NSLog(@"Model with model name {%@} not found in bundle {%@}", self.modelName, bundle);
        abort();
    }

    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];

    NSError *addPersistentStoreError = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                   configuration:nil
                                                             URL:storeURL
                                                         options:options
                                                           error:&addPersistentStoreError]) {
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:storeType
                                                       configuration:nil
                                                                 URL:storeURL
                                                             options:options
                                                               error:&addPersistentStoreError]) {
            NSLog(@"Unresolved error %@, %@", addPersistentStoreError, [addPersistentStoreError userInfo]);
            abort();
        }

        [NSException raise:@"DATASTACK_NON_VALID_MIGRATION_OCURRED"
                    format:@"Error encountered while reading the database. Please allow all the data to download again."];
    }

    NSError *excludeSQLiteFileFromBackupsError = nil;
    BOOL shouldExcludeSQLiteFromBackup = (self.storeType == DATAStackSQLiteStoreType &&
                                          ![Test isRunning]);
    if (shouldExcludeSQLiteFromBackup) {
        [storeURL setResourceValue:@YES
                            forKey:NSURLIsExcludedFromBackupKey
                             error:&excludeSQLiteFileFromBackupsError];
        if (excludeSQLiteFileFromBackupsError) {
            NSLog(@"Excluding SQLite file from backup caused an error: %@", [excludeSQLiteFileFromBackupsError description]);
        }
    }

    return _persistentStoreCoordinator;
}

- (NSPersistentStoreCoordinator *)disposablePersistentStoreCoordinator
{
    if (_disposablePersistentStoreCoordinator) return _disposablePersistentStoreCoordinator;

    NSBundle *bundle = (self.modelBundle) ?: [NSBundle mainBundle];
    NSURL *modelURL = [bundle URLForResource:self.modelName withExtension:@"momd"];
    if (!modelURL) {
        NSLog(@"Model with model name {%@} not found in bundle {%@}", self.modelName, bundle);
        abort();
    }

    NSManagedObjectModel *model = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    _disposablePersistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:model];
    NSError *addPersistentStoreError = nil;
    [_disposablePersistentStoreCoordinator addPersistentStoreWithType:NSInMemoryStoreType
                                                        configuration:nil
                                                                  URL:nil
                                                              options:nil
                                                                error:&addPersistentStoreError];
    if (addPersistentStoreError) {
        NSLog(@"There was a problem adding the persistent store to the disposable persistent coordinator: %@", [addPersistentStoreError description]);
    }

    return _disposablePersistentStoreCoordinator;
}

#pragma mark - Private methods

- (void)persistWithCompletion:(void (^)())completion
{
    void (^writerContextBlock)() = ^() {
        NSError *parentError = nil;
        if ([self.writerContext save:&parentError]) {
            if ([Test isRunning]) {
                if (completion) completion();
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (completion) completion();
                });
            }
        } else {
            NSLog(@"Unresolved error saving parent managed object context %@, %@", parentError, [parentError userInfo]);
            abort();
        }
    };

    void (^mainContextBlock)() = ^() {
        NSError *error = nil;
        if ([self.mainContext save:&error]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [self.writerContext performSelector:[self performSelectorForBackgroundContext]
                                     withObject:writerContextBlock];
#pragma clang diagnostic pop
        } else {
            NSLog(@"Unresolved error saving managed object context %@, %@", error, [error userInfo]);
            abort();
        }
    };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [self.mainContext performSelector:[self performSelectorForBackgroundContext]
                           withObject:mainContextBlock];
#pragma clang diagnostic pop
}

#pragma mark - Application's Documents directory

- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

#pragma mark - Public methods

- (void)performInNewBackgroundContext:(void (^)(NSManagedObjectContext *backgroundContext))operation
{
    NSManagedObjectContext *context = [[NSManagedObjectContext alloc] initWithConcurrencyType:[self backgroundConcurrencyType]];
    context.persistentStoreCoordinator = self.persistentStoreCoordinator;
    context.undoManager = nil;
    context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy;

    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(backgroundContextDidSave:)
                                                 name:NSManagedObjectContextDidSaveNotification
                                               object:context];

    void (^contextBlock)() = ^() {
        if (operation) operation(context);
    };

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
    [context performSelector:[self performSelectorForBackgroundContext]
                  withObject:contextBlock];
#pragma clang diagnostic pop
}

- (NSManagedObjectContext *)disposableMainContext
{
    if (_disposableMainContext) return _disposableMainContext;

    _disposableMainContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
    _disposableMainContext.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator;

    return _disposableMainContext;
}

#pragma mark - Observers

- (void)backgroundContextDidSave:(NSNotification *)backgroundContextNotification
{
    void (^contextBlock)() = ^() {
        [self.mainContext mergeChangesFromContextDidSaveNotification:backgroundContextNotification];
    };

    if ([NSThread isMainThread] && ![Test isRunning]) {
        [NSException raise:@"DATASTACK_BACKGROUND_CONTEXT_CREATION_EXCEPTION"
                    format:@"Background context saved in the main thread. Use context's `performBlock`"];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [self.mainContext performSelector:[self performSelectorForBackgroundContext]
                               withObject:contextBlock];
#pragma clang diagnostic pop
    }
}

#pragma mark - Test

- (void)drop {
    NSPersistentStore *store = [self.persistentStoreCoordinator.persistentStores lastObject];
    NSURL *storeURL = store.URL;
    NSString *sqliteFile = [storeURL.path stringByDeletingPathExtension];
    NSFileManager *fileManager = [NSFileManager defaultManager];

    self.writerContext = nil;
    self.mainContext = nil;
    self.persistentStoreCoordinator = nil;

    NSString *shm = [NSString stringWithFormat:@"%@.sqlite-shm", sqliteFile];
    NSError *removeShmError = nil;
    if ([fileManager fileExistsAtPath:shm]) {
        [fileManager removeItemAtURL:[NSURL fileURLWithPath:shm] error:&removeShmError];
    }
    if (removeShmError) {
        NSLog(@"Could not delete persitent store shm: %@", removeShmError.localizedDescription);
    }

    NSString *wal = [NSString stringWithFormat:@"%@.sqlite-wal", sqliteFile];
    NSError *removeWalError = nil;
    if ([fileManager fileExistsAtPath:wal]) {
        [fileManager removeItemAtURL:[NSURL fileURLWithPath:wal] error:&removeWalError];
    }
    if (removeWalError) {
        NSLog(@"Could not delete persitent store wal: %@", removeWalError.localizedDescription);
    }

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnullable-to-nonnull-conversion"
    NSError *removeStoreURLError = nil;
    if ([fileManager fileExistsAtPath:storeURL.path]) {
        [fileManager removeItemAtURL:storeURL error:&removeStoreURLError];
    }
#pragma clang diagnostic pop

    if (removeStoreURLError) {
        NSLog(@"error deleting sqlite file");
        abort();
    }
}

- (NSManagedObjectContextConcurrencyType)backgroundConcurrencyType
{
    return ([Test isRunning]) ? NSMainQueueConcurrencyType : NSPrivateQueueConcurrencyType;
}

- (SEL)performSelectorForBackgroundContext
{
    return ([Test isRunning]) ? NSSelectorFromString(@"performBlockAndWait:") : NSSelectorFromString(@"performBlock:");
}

@end
