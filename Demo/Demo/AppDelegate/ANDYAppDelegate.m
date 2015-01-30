#import "ANDYAppDelegate.h"
#import "ANDYMainTableViewController.h"
#import "ANDYDataManager.h"

ANDYAppDelegate *appDelegate;

@interface ANDYAppDelegate ()

@property (nonatomic, strong, readwrite) ANDYDataManager *dataManager;

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
