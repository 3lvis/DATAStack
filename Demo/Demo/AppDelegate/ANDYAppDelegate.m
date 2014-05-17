//
//  ANDYAppDelegate.m
//  Demo
//
//  Created by Elvis Nunez on 3/20/14.
//  Copyright (c) 2014 Andy. All rights reserved.
//

#import "ANDYAppDelegate.h"
#import "ANDYMainTableViewController.h"
#import "ANDYDataManager.h"

@interface ANDYAppDelegate () <ANDYDataManagerDataSource>
@end

@implementation ANDYAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [[ANDYDataManager sharedManager] setDataSource:self];

    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];

    ANDYMainTableViewController *mainController = [[ANDYMainTableViewController alloc] initWithStyle:UITableViewStylePlain];
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:mainController];
    self.window.rootViewController = navController;

    [self.window makeKeyAndVisible];
    return YES;
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    [[ANDYDataManager sharedManager] persistContext];
}

#pragma mark - ANDYDataManagerDataSource

- (NSString *)managedObjectModelName
{
    return @"Demo";
}

@end