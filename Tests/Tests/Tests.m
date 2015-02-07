@import XCTest;

#import "DATAStack.h"

#import "User.h"

@interface Tests : XCTestCase

@end

@implementation Tests

- (void)testSampleTest
{
    DATAStack *stack = [[DATAStack alloc] initWithModelName:@"Model"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackInMemoryStoreType];
    XCTAssertNotNil(stack);

    NSManagedObjectContext *context = [stack mainThreadContext];

    User *user = [NSEntityDescription insertNewObjectForEntityForName:@"User"
                                               inManagedObjectContext:context];
    user.remoteID = @1;
    user.name = @"Joshua Ivanof";

    NSError *saveError = nil;
    if (![context save:&saveError]) {
        NSLog(@"Error: %@", saveError);
        abort();
    }

    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];

    NSError *fetchError = nil;
    NSArray *objects = [context executeFetchRequest:request error:&fetchError];
    if (fetchError) NSLog(@"error fetching IDs: %@", [fetchError description]);

    XCTAssertEqual(objects.count, 1);
}

@end
