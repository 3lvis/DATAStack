@import UIKit;

@class ANDYDataManager;

#define SharedAppDelegate (ANDYAppDelegate *)[[UIApplication sharedApplication] delegate]

@interface ANDYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) ANDYDataManager *dataManager;

@end
