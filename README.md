![DATAStack](https://raw.githubusercontent.com/3lvis/DATAStack/master/Images/datastack-logo.png)

**DATAStack** helps you to alleviate the Core Data boilerplate. Now you can go to your AppDelegate remove all the Core Data related code and replace it with an instance of DATAStack ([ObjC](DemoObjectiveC/AppDelegate.m), [Swift](DemoSwift/AppDelegate.swift)).

- [x] Easier thread safety
- [x] Runs synchronously in testing enviroments
- [x] No singletons
- [x] SQLite and InMemory support out of the box
- [x] Easy database drop method
- [x] Swift
- [x] Objective-C support
- [x] Free

## Initialization

You can easily initialize a new instance of **DATAStack** with just your Core Data Model name (xcdatamodel).

**Swift**
``` swift
let dataStack = DATAStack(modelName:"MyAppModel")
```

**Objective-C**
``` objc
DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"MyAppModel"];
```

## Set up

It is recommended that **DATAStack** gets persisted when these two methods are called in your `AppDelegate`.

**Swift**
```swift
func applicationDidEnterBackground(application: UIApplication) {
    self.dataStack.persistWithCompletion(nil)
}

func applicationWillTerminate(application: UIApplication) {
    self.dataStack.persistWithCompletion(nil)
}
```

**Objective-C**
``` objc
- (void)applicationDidEnterBackground:(UIApplication *)application {
    [self.dataStack persistWithCompletion:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application {
    [self.dataStack persistWithCompletion:nil];
}
```

## Main Thread NSManagedObjectContext

Getting access to the NSManagedObjectContext attached to the main thread is as simple as using the `mainContext` property.

```objc
self.dataStack.mainContext
```

## Background Thread NSManagedObjectContext

You can easily create a new background NSManagedObjectContext for data processing. This block is completely asynchronous and will be run on a background thread.

**Swift**
```swift
func createUser() {
    self.dataStack.performInNewBackgroundContext { backgroundContext in
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: backgroundContext)!
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: backgroundContext)
        object.setValue("Background", forKey: "name")
        object.setValue(NSDate(), forKey: "createdDate")
        try! backgroundContext.save()
    }
}
```

**Objective-C**
```objc
- (void)createUser {
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext * _Nonnull backgroundContext) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:backgroundContext];
        NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:backgroundContext];
        [object setValue:@"Background" forKey:@"name"];
        [object setValue:[NSDate date] forKey:@"createdDate"];
        [backgroundContext save:nil];
    }];
}
```

When using Xcode's autocompletion the `backgroundContext` parameter name doesn't get included. Make sure to add it.

## Clean up

Deleting the `.sqlite` file and resetting the state of your **DATAStack** is as simple as just calling `drop`.

**Swift**
```swift
self.dataStack.drop()
```

**Objective-C**
```objc
[self.dataStack drop];
```

## Testing

**DATAStack** is optimized for unit testing and it runs synchronously in testing enviroments. Hopefully you'll have to use less XCTestExpectations now.

You can create a stack that uses in memory store like this if your Core Data model is located in your app bundle:

**Swift**
```swift
let dataStack = DATAStack(modelName: "MyAppModel", bundle: NSBundle.mainBundle(), storeType: .InMemory)
```

**Objective-C**
```objc
DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"MyAppModel"
                                                     bundle:[NSBundle mainBundle]
                                                  storeType:DATAStackStoreTypeInMemory];
```

If your Core Data model is located in your test bundle:

**Swift**
```swift
let dataStack = DATAStack(modelName: "MyAppModel", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)
```

**Objective-C**
```objc
DATAStack *dataStack = [[DATAStack alloc] initWithModelName:@"MyAppModel"
                                                     bundle:[NSBundle bundleForClass:[self class]]
                                                  storeType:DATAStackStoreTypeInMemory];
```

_(Hint: Maybe you haven't found the best way to use NSFetchedResultsController, well [here it is](https://github.com/3lvis/DATASource).)_

## Migrations

If `DATAStack` has troubles creating your persistent coordinator because a migration wasn't properly handled it will destroy your data and create a new sqlite file. The normal Core Data behaviour for this is making your app crash on start. This is not fun.

## Installation

**DATAStack** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
use_frameworks!

pod 'DATAStack'
```

## Be Awesome

If something looks stupid, please create a friendly and constructive issue, getting your feedback would be awesome.

Have a great day.

## Author

Elvis Nuñez, [@3lvis](https://twitter.com/3lvis)

## License

**DATAStack** is available under the MIT license. See the LICENSE file for more info.
