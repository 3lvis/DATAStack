// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Task.m instead.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wgnu-empty-initializer"
#pragma clang diagnostic ignored "-Wcustom-atomic-properties"
#pragma clang diagnostic ignored "-Wgnu-empty-struct"

#import "_Task.h"

const struct TaskAttributes TaskAttributes = {
	.date = @"date",
	.title = @"title",
};

const struct TaskRelationships TaskRelationships = {
};

const struct TaskFetchedProperties TaskFetchedProperties = {
};

@implementation TaskID
@end

@implementation _Task

+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription insertNewObjectForEntityForName:@"Task" inManagedObjectContext:moc_];
}

+ (NSString*)entityName {
	return @"Task";
}

+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_ {
	NSParameterAssert(moc_);
	return [NSEntityDescription entityForName:@"Task" inManagedObjectContext:moc_];
}

- (TaskID*)objectID {
	return (TaskID*)[super objectID];
}

+ (NSSet*)keyPathsForValuesAffectingValueForKey:(NSString*)key {
	NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
	

	return keyPaths;
}




@dynamic date;






@dynamic title;











@end

#pragma clang diagnostic pop