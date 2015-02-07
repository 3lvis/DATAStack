@import UIKit;

@class DATAStack;

@interface ANDYAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (nonatomic, strong, readonly) DATAStack *dataStack;

@end

extern ANDYAppDelegate *appDelegate;
