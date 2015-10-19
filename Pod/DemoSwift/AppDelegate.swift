import UIKit
import CoreData

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow? = {
        let window = UIWindow(frame: UIScreen.mainScreen().bounds)

        return window
        }()

    var dataStack: DATAStack = {
        let dataStack = DATAStack(modelName: "DemoSwift")

        return dataStack
        }()

    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        if let window = self.window {
            let viewController = ViewController(dataStack: self.dataStack)
            window.rootViewController = UINavigationController(rootViewController: viewController)
            window.makeKeyAndVisible()
        }

        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        self.dataStack.persistWithCompletion()
    }

    func applicationDidEnterBackground(application: UIApplication) {
        self.dataStack.persistWithCompletion()
    }

    func applicationWillTerminate(application: UIApplication) {
        self.dataStack.persistWithCompletion()
    }
}
