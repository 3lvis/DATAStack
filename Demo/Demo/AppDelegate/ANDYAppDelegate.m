#import "ANDYAppDelegate.h"
#import "ANDYMainTableViewController.h"
#import "ANDYDataManager.h"

@interface ANDYAppDelegate ()

@property (nonatomic, strong, readwrite) ANDYDataManager *dataManager;

@end

@implementation ANDYAppDelegate

#pragma mark - Getters

- (ANDYDataManager *)dataManager
{
    if (_dataManager) return _dataManager;

    _dataManager = [[ANDYDataManager alloc] initWithModelName:@"Demo"];

    return _dataManager;
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
    [self.dataManager persistContext];
}

@end
