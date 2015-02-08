#import "ANDYAppDelegate.h"
#import "ANDYMainTableViewController.h"
#import "DATAStack.h"

ANDYAppDelegate *appDelegate;

@interface ANDYAppDelegate ()

@property (nonatomic, strong, readwrite) DATAStack *dataStack;

@end

@implementation ANDYAppDelegate

- (instancetype)init
{
    self = [super init];
    if (!self) return nil;

    appDelegate = self;

    return self;
}

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

    ANDYMainTableViewController *mainController = [[ANDYMainTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainController];
    self.window.rootViewController = navController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [self.dataStack persistWithCompletion:nil];
}

@end
