@import XCTest;

#import "DATAStack.h"

#import "User.h"

@interface Tests : XCTestCase

@end

@implementation Tests

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

- (void)testNormalMainThreadSave
{
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];
    XCTAssertNotNil(stack);

    NSManagedObjectContext *context = [stack mainThreadContext];

    [self insertUserInContext:context];

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSError *fetchError = nil;
    NSArray *objects = [context executeFetchRequest:request error:&fetchError];
    if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);

    XCTAssertEqual(objects.count, 1);
}

- (void)testRequestWithDictionaryResultType
{
    XCTestExpectation *expectation = [self expectationWithDescription:@"Saving expectations"];

    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];

    NSManagedObjectContext *context = [stack mainThreadContext];

    [self insertUserInContext:context];

    [stack persistWithCompletion:^{
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

        [expectation fulfill];
    }];

    [self waitForExpectationsWithTimeout:5.0f handler:nil];
}

@end
