import Foundation
import CoreData

// MARK: - Enums

@objc public enum DATAStackStoreType: Int {
    case InMemory, SQLite
}

@objc public class DATAStack: NSObject {
    // MARK: - Variables

    private var storeType: DATAStackStoreType = .SQLite

    private var storeName: String?

    private var modelName: String = ""

    private var modelBundle: NSBundle = NSBundle.mainBundle()

    private var _mainContext: NSManagedObjectContext?

    public var mainContext: NSManagedObjectContext {
        get {
            if _mainContext == nil {
                let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                context.undoManager = nil
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                context.parentContext = self.writerContext

                _mainContext = context
            }

            return _mainContext!
        }
    }

    private var _writerContext: NSManagedObjectContext?

    private var writerContext: NSManagedObjectContext {
        get {
            if _writerContext == nil {
                let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
                context.undoManager = nil
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                context.persistentStoreCoordinator = self.persistentStoreCoordinator

                _writerContext = context
            }

            return _writerContext!
        }
    }

    private var _persistentStoreCoordinator: NSPersistentStoreCoordinator?

    private var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        get {
            if _persistentStoreCoordinator == nil {
                let filePath = (self.storeName ?? self.modelName) + ".sqlite"

                var model: NSManagedObjectModel?

                if let momdModelURL = self.modelBundle.URLForResource(self.modelName, withExtension: "momd") {
                    model = NSManagedObjectModel(contentsOfURL: momdModelURL)
                }

                if let momModelURL = self.modelBundle.URLForResource(self.modelName, withExtension: "mom") {
                    model = NSManagedObjectModel(contentsOfURL: momModelURL)
                }

                if model == nil {
                    fatalError("Model with model name \(self.modelName) not found in bundle \(self.modelBundle)")
                }

                let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model!)

                switch self.storeType {
                case .InMemory:
                    do {
                        try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
                    } catch let error as NSError {
                        fatalError("There was an error creating the persistentStoreCoordinator: \(error)")
                    }

                    break
                case .SQLite:
                    let storeURL = self.applicationDocumentsDirectory().URLByAppendingPathComponent(filePath)
                    guard let storePath = storeURL.path else { fatalError("Store path not found: \(storeURL)") }

                    let shouldPreloadDatabase = !NSFileManager.defaultManager().fileExistsAtPath(storePath)
                    if shouldPreloadDatabase {
                        if let preloadedPath = self.modelBundle.pathForResource(self.modelName, ofType: "sqlite") {
                            let preloadURL = NSURL.fileURLWithPath(preloadedPath)

                            do {
                                try NSFileManager.defaultManager().copyItemAtURL(preloadURL, toURL: storeURL)
                            } catch let error as NSError {
                                fatalError("Oops, could not copy preloaded data. Error: \(error)")
                            }
                        }
                    }

                    do {
                        try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
                    } catch {
                        print("Error encountered while reading the database. Please allow all the data to download again.")

                        do {
                            try NSFileManager.defaultManager().removeItemAtPath(storePath)

                            do {
                                try persistentStoreCoordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
                            } catch let addPersistentError as NSError {
                                fatalError("There was an error creating the persistentStoreCoordinator: \(addPersistentError)")
                            }
                        } catch let removingError as NSError {
                            fatalError("There was an error removing the persistentStoreCoordinator: \(removingError)")
                        }
                    }

                    let shouldExcludeSQLiteFromBackup = self.storeType == .SQLite && TestCheck.isTesting == false
                    if shouldExcludeSQLiteFromBackup {
                        do {
                            try storeURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                        } catch let excludingError as NSError {
                            fatalError("Excluding SQLite file from backup caused an error: \(excludingError)")
                        }
                    }

                    break
                }

                _persistentStoreCoordinator = persistentStoreCoordinator
            }

            return _persistentStoreCoordinator!
        }
    }

    public func newDisposableMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator
        context.undoManager = nil

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.newDisposableMainContextWillSave(_:)), name: NSManagedObjectContextWillSaveNotification, object: context)

        return context
    }

    private lazy var disposablePersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        guard let modelURL = self.modelBundle.URLForResource(self.modelName, withExtension: "momd"), model = NSManagedObjectModel(contentsOfURL: modelURL)
            else { fatalError("Model named \(self.modelName) not found in bundle \(self.modelBundle)") }

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        do {
            try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
        } catch let error as NSError {
            fatalError("There was an error creating the disposablePersistentStoreCoordinator: \(error)")
        }

        return persistentStoreCoordinator
    }()

    // MARK: - Initalizers

    public override init() {
        let bundle = NSBundle.mainBundle()
        let bundleName = bundle.infoDictionary!["CFBundleName"] as! String

        self.modelName = bundleName
    }

    public init(modelName: String) {
        self.modelName = modelName
    }

    public init(modelName: String, bundle: NSBundle, storeType: DATAStackStoreType) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
    }

    public init(modelName: String, bundle: NSBundle, storeType: DATAStackStoreType, storeName: String) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
        self.storeName = storeName
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextWillSaveNotification, object: nil)
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: nil)
    }

    // MARK: - Observers

    internal func newDisposableMainContextWillSave(notification: NSNotification) {
        let context = notification.object as! NSManagedObjectContext
        context.reset()
    }

    internal func backgroundContextDidSave(notification: NSNotification) {
        if NSThread.isMainThread() && TestCheck.isTesting == false {
            fatalError("Background context saved in the main thread. Use context's `performBlock`")
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
            self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
        }
    }

    // MARK: - Public

    public func performInNewBackgroundContext(operation: (backgroundContext: NSManagedObjectContext) -> ()) {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.backgroundContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: context)

        let contextBlock: @convention(block) () -> Void = {
            operation(backgroundContext: context)
        }
        let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
        context.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
    }

    public func persistWithCompletion(completion: (() -> ())?) {
        let writerContextBlock: @convention(block) () -> Void = {
            do {
                try self.writerContext.save()
                if TestCheck.isTesting {
                    completion?()
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion?()
                    })
                }
            } catch let parentError as NSError {
                fatalError("Unresolved error saving parent managed object context \(parentError)");
            }
        }
        let writerContextBlockObject : AnyObject = unsafeBitCast(writerContextBlock, AnyObject.self)

        let mainContextBlock: @convention(block) () -> Void = {
            do {
                try self.mainContext.save()
                self.writerContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: writerContextBlockObject)
            } catch let error as NSError {
                fatalError("Unresolved error saving managed object context \(error)")
            }
        }
        let mainContextBlockObject : AnyObject = unsafeBitCast(mainContextBlock, AnyObject.self)
        self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: mainContextBlockObject)

    }

    public func drop() {
        guard let store = self.persistentStoreCoordinator.persistentStores.last, storeURL = store.URL, storePath = storeURL.path
            else { fatalError("Persistent store coordinator not found") }

        let sqliteFile = (storePath as NSString).stringByDeletingPathExtension
        let fileManager = NSFileManager.defaultManager()

        self._writerContext = nil
        self._mainContext = nil
        self._persistentStoreCoordinator = nil

        let shm = sqliteFile + ".sqlite-shm"
        if fileManager.fileExistsAtPath(shm) {
            do {
                try fileManager.removeItemAtURL(NSURL.fileURLWithPath(shm))
            } catch let error as NSError {
                print("Could not delete persistent store shm: \(error)")
            }
        }

        let wal = sqliteFile + ".sqlite-wal"
        if fileManager.fileExistsAtPath(wal) {
            do {
                try fileManager.removeItemAtURL(NSURL.fileURLWithPath(wal))
            } catch let error as NSError {
                print("Could not delete persistent store wal: \(error)")
            }
        }

        if fileManager.fileExistsAtPath(storePath) {
            do {
                try fileManager.removeItemAtURL(storeURL)
            } catch let error as NSError {
                print("Could not delete sqlite file: \(error)")
            }
        }
    }

    private func applicationDocumentsDirectory() -> NSURL {
        #if os(tvOS)
            return NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last!
        #else
            return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        #endif
    }

    private static func backgroundConcurrencyType() -> NSManagedObjectContextConcurrencyType {
        return TestCheck.isTesting ? .MainQueueConcurrencyType : .PrivateQueueConcurrencyType
    }

    private static func performSelectorForBackgroundContext() -> Selector {
        return TestCheck.isTesting ? NSSelectorFromString("performBlockAndWait:") : NSSelectorFromString("performBlock:")
    }
}

struct TestCheck {
    /**
     Method to check wheter your on testing mode or not.
     - returns: A Bool, `true` if you're on testing mode, `false` if you're not.
     */
    static let isTesting: Bool = {
        let enviroment = NSProcessInfo.processInfo().environment
        let serviceName = enviroment["XPC_SERVICE_NAME"]
        let injectBundle = enviroment["XCInjectBundle"]
        var isRunning = (enviroment["TRAVIS"] != nil || enviroment["XCTestConfigurationFilePath"] != nil)

        if !isRunning {
            if let serviceName = serviceName {
                isRunning = (serviceName as NSString).pathExtension == "xctest"
            }
        }

        if !isRunning {
            if let injectBundle = injectBundle {
                isRunning = (injectBundle as NSString).pathExtension == "xctest"
            }
        }

        return isRunning
    }()
}
