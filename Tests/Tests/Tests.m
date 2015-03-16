@import XCTest;

#import "DATAStack.h"

#import "User.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (DATAStack *)dataStack
{
    DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"Model"
                                                         bundle:[NSBundle bundleForClass:[self class]]
                                                      storeType:DATAStackInMemoryStoreType];

    return dataStack;
}

- (void)insertUserInContext:(NSManagedObjectContext *)context
{
    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                               inManagedObjectContext:context];
    user.remoteID = @1;
    user.name = @"Joshua Ivanof";

    NSError *saveError = nil;
    if (![context save:&saveError]) {
        NSLog(@"Error: %@", saveError);
        abort();
    }
}

- (void)testNormalMainContextSave
{
    DATAStack *dataStack = [self dataStack];

    XCTAssertNotNil(dataStack);

    NSManagedObjectContext *context = [dataStack mainContext];

    [self insertUserInContext:context];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSError *fetchError = nil;
    NSArray *objects = [context executeFetchRequest:request error:&fetchError];
    if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);
    XCTAssertEqual(objects.count, 1);

    [dataStack persistWithCompletion:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        NSError *fetchError = nil;
        NSArray *objects = [dataStack.mainContext executeFetchRequest:request error:&fetchError];
        if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);
        XCTAssertEqual(objects.count, 1);
    }];
}

- (void)testBackgroundContextSave
{
    DATAStack *dataStack = [self dataStack];

    XCTAssertNotNil(dataStack);

    __block BOOL hasBeenTested = NO;

    [dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        [self insertUserInContext:backgroundContext];

        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        NSError *fetchError = nil;
        NSArray *objects = [backgroundContext executeFetchRequest:request error:&fetchError];
        if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);
        XCTAssertEqual(objects.count, 1);

        [dataStack persistWithCompletion:^{
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
            NSError *fetchError = nil;
            NSArray *objects = [dataStack.mainContext executeFetchRequest:request error:&fetchError];
            if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);
            XCTAssertEqual(objects.count, 1);

            hasBeenTested = YES;
        }];
    }];

    XCTAssertTrue(hasBeenTested);
}

- (void)testRequestWithDictionaryResultType
{
    DATAStack *dataStack = [self dataStack];

    NSManagedObjectContext *context = [dataStack mainContext];

    [self insertUserInContext:context];

    [dataStack persistWithCompletion:^{
        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

        NSError *fetchError = nil;
        NSArray *objects = [context executeFetchRequest:request error:&fetchError];
        if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);

        XCTAssertEqual(objects.count, 1);

        NSExpressionDescription *expression = [[NSExpressionDescription alloc] init];
        expression.name = @"objectID";
        expression.expression = [NSExpression expressionForEvaluatedObject];
        expression.expressionResultType = NSObjectIDAttributeType;

        NSFetchRequest *dictionaryRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        dictionaryRequest.resultType = NSDictionaryResultType;
        dictionaryRequest.propertiesToFetch = @[expression, @"remoteID"];

        NSError *dictionaryError = nil;
        NSArray *dictionaryObjects = [context executeFetchRequest:dictionaryRequest error:&dictionaryError];
        if (dictionaryError) NSLog(@"error fetching IDs: %@", [dictionaryError description]);
        XCTAssertEqual(dictionaryObjects.count, 1);
    }];
}

- (void)testDisposableMainContext
{
    DATAStack *dataStack = [self dataStack];
    XCTAssertThrowsSpecificNamed([self insertUserInContext:dataStack.disposableMainContext], NSException, NSInternalInconsistencyException);
}

@end
