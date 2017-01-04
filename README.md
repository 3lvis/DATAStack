![DATAStack](https://raw.githubusercontent.com/SyncDB/DATAStack/master/Images/datastack-logo2.png)

<div align = "center">
  <a href="https://cocoapods.org/pods/DATAStack">
    <img src="https://img.shields.io/cocoapods/v/DATAStack.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/DATAStack">
    <img src="https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat" />
  </a>
  <a href="https://github.com/SyncDB/DATAStack#installation">
    <img src="https://img.shields.io/badge/compatible-swift%202.3%20and%203.0-orange.svg" />
  </a>
</div>

<div align = "center">
  <a href="https://cocoapods.org/pods/DATAStack" target="blank">
    <img src="https://img.shields.io/cocoapods/p/DATAStack.svg?style=flat" />
  </a>
  <a href="https://cocoapods.org/pods/DATAStack" target="blank">
    <img src="https://img.shields.io/cocoapods/l/DATAStack.svg?style=flat" />
  </a>
  <a href="https://gitter.im/SyncDB/DATAStack">
    <img src="https://img.shields.io/gitter/room/nwjs/nw.js.svg" />
  </a>
  <br>
  <br>
</div>

**DATAStack** helps you to alleviate the Core Data boilerplate. Now you can go to your AppDelegate remove all the Core Data related code and replace it with an instance of DATAStack ([ObjC](DemoObjectiveC/AppDelegate.m), [Swift](DemoSwift/AppDelegate.swift)).

- Easier thread safety
- Runs synchronously when using unit tests
- No singletons
- SQLite and InMemory support out of the box
- Easy database drop method
- Shines with Swift
- Compatible with Objective-C
- Free

## Table of Contents

* [Running the demos](#running-the-demos)
* [Initialization](#initialization)
* [Main Thread NSManagedObjectContext](#main-thread-nsmanagedobjectcontext)
* [Background Thread NSManagedObjectContext](#background-thread-nsmanagedobjectcontext)
* [Clean up](#clean-up)
* [Testing](#testing)
* [Migrations](#migrations)
* [Installation](#installation)
* [Be Awesome](#be-awesome)
* [Author](#author)
* [License](#license)

## Running the demos
Before being able to run the demos you have to install the demo dependencies using [CocoaPods](https://cocoapods.org/).

- Install CocoaPods
- Run `pod install`
- Enjoy!

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

There are plenty of other ways to intialize a DATAStack:

- Using a custom store type.

``` swift
let dataStack = DATAStack(modelName:"MyAppModel", storeType: .InMemory)
```

- Using another bundle and a store type, let's say your test bundle and .InMemory store type, perfect for running unit tests.

``` swift
let dataStack = DATAStack(modelName: "Model", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)
```

- Using a different name for your .sqlite file than your model name, like `CustomStoreName.sqlite`.

``` swift
let dataStack = DATAStack(modelName: "Model", bundle: NSBundle.mainBundle(), storeType: .SQLite, storeName: "CustomStoreName")
```

- Providing a diferent container url, by default we'll use the documents folder, most apps do this, but if you want to share your sqlite file between your main app and your app extension you'll want this.

``` swift
let dataStack = DATAStack(modelName: "Model", bundle: NSBundle.mainBundle(), storeType: .SQLite, storeName: "CustomStoreName", containerURL: sharedURL)
```

## Main Thread NSManagedObjectContext

Getting access to the NSManagedObjectContext attached to the main thread is as simple as using the `mainContext` property.

```swift
self.dataStack.mainContext
```

or

```swift
self.dataStack.viewContext
```

## Background Thread NSManagedObjectContext

You can easily create a new background NSManagedObjectContext for data processing. This block is completely asynchronous and will be run on a background thread.

To be compatible with NSPersistentContainer you can also use `performBackgroundTask` instead of `performInNewBackgroundContext`.

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

When using Xcode's Objective-C autocompletion the `backgroundContext` parameter name doesn't get included. Make sure to add it.

## Clean up

Deleting the `.sqlite` file and resetting the state of your **DATAStack** is as simple as just calling `drop`.

**Swift**
```swift
self.dataStack.drop()
```

**Objective-C**
```objc
[self.dataStack forceDrop];
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

_(Hint: Maybe you haven't found the best way to use NSFetchedResultsController, well [here it is](https://github.com/SyncDB/DATASource).)_

## Migrations

If `DATAStack` has troubles creating your persistent coordinator because a migration wasn't properly handled it will destroy your data and create a new sqlite file. The normal Core Data behaviour for this is making your app crash on start. This is not fun.

## Installation

**DATAStack** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
use_frameworks!

pod 'DATAStack', '~> 6'
```

**DATAStack** is also available through [Carthage](https://github.com/Carthage/Carthage). To install
it, simply add the following line to your Cartfile:

```ruby
github "SyncDB/DATAStack" ~> 6.0
```

## Be Awesome

If something looks stupid, please create a friendly and constructive issue, getting your feedback would be awesome.

Have a great day.

## Author

SyncDB, [@Sync_DB](https://twitter.com/Sync_DB)

## License

**DATAStack** is available under the MIT license. See the LICENSE file for more info.
