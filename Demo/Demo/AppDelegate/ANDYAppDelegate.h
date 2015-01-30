@import UIKit;

@class ANDYDataStack;

@interface ANDYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) ANDYDataStack *dataStack;

@end

extern ANDYAppDelegate *appDelegate;
