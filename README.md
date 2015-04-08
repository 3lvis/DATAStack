![DATAStack](https://raw.githubusercontent.com/3lvis/DATAStack/master/Images/datastack-logo.png)

This is a library that helps you to alleviate the Core Data boilerplate. Now you can go to your AppDelegate remove all the Core Data related code and replace it with [an instance of DATAStack](https://github.com/3lvis/DATAStack/blob/master/Demo/Demo/AppDelegate/ANDYAppDelegate.m#L19).

``` objc
- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}
```

Then in your DATASource backed app (attached to your main context). You can do this:

``` objc
#pragma mark - Actions

- (void)createTask
{
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        Task *task = [Task insertInManagedObjectContext:backgroundContext];
        task.title = @"Hello!";
        task.date = [NSDate date];
        [backgroundContext save:nil];
    }];
}
```

**BOOM, it just works.**

_(Hint: Maybe you haven't found the best way to use NSFetchedResultsController, well [here it is](https://github.com/3lvis/DATASource).)_

Installation
===========

**DATAStack** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'DATAStack'
```

Be Awesome
==========

If something looks stupid, please create a friendly and constructive issue, getting your feedback would be awesome. Have a great day.
