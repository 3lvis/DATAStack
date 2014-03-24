// DO NOT EDIT. This file is machine-generated and constantly overwritten.
// Make changes to Task.h instead.

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wauto-import"
#pragma clang diagnostic ignored "-Wc++-compat"
#pragma clang diagnostic ignored "-Wgnu-empty-struct"

@import CoreData;

extern const struct TaskAttributes {
	__unsafe_unretained NSString *date;
	__unsafe_unretained NSString *title;
} TaskAttributes;

extern const struct TaskRelationships {
} TaskRelationships;

extern const struct TaskFetchedProperties {
} TaskFetchedProperties;





@interface TaskID : NSManagedObjectID {}
@end

@interface _Task : NSManagedObject {}
+ (id)insertInManagedObjectContext:(NSManagedObjectContext*)moc_;
+ (NSString*)entityName;
+ (NSEntityDescription*)entityInManagedObjectContext:(NSManagedObjectContext*)moc_;
- (TaskID*)objectID;





@property (nonatomic, strong) NSDate* date;



//- (BOOL)validateDate:(id*)value_ error:(NSError**)error_;





@property (nonatomic, strong) NSString* title;



//- (BOOL)validateTitle:(id*)value_ error:(NSError**)error_;






@end

@interface _Task (CoreDataGeneratedAccessors)

@end

@interface _Task (CoreDataGeneratedPrimitiveAccessors)


- (NSDate*)primitiveDate;
- (void)setPrimitiveDate:(NSDate*)value;




- (NSString*)primitiveTitle;
- (void)setPrimitiveTitle:(NSString*)value;




@end

#pragma clang diagnostic pop