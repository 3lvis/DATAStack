#import "ANDYAppDelegate.h"
#import "ANDYMainTableViewController.h"
#import "Demo-Swift.h"

@interface ANDYAppDelegate ()

@property (nonatomic) DATAStack *dataStack;

@end

@implementation ANDYAppDelegate

#pragma mark - Getters

- (DATAStack *)dataStack
{
    if (_dataStack) return _dataStack;

    _dataStack = [[DATAStack alloc] initWithModelName:@"Demo"];

    return _dataStack;
}

#pragma mark - UIApplicationDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ANDYMainTableViewController *mainController = [[ANDYMainTableViewController alloc] initWithDataStack:self.dataStack];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainController];
    self.window.rootViewController = navController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:^{}];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:^{}];
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:^{}];
}

@end
