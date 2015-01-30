@import UIKit;

@class ANDYDataManager;

@interface ANDYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) ANDYDataManager *dataManager;

@end

extern ANDYAppDelegate *appDelegate;
