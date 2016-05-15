import Foundation
import CoreData

@objc public enum DATAStackStoreType: Int {
    case InMemory, SQLite
}

@objc public class DATAStack: NSObject {
    private var storeType: DATAStackStoreType = .SQLite

    private var storeName: String?

    private var modelName: String = ""

    private var modelBundle: NSBundle = NSBundle.mainBundle()

    private var _mainContext: NSManagedObjectContext?

    /**
     The context for the main queue. Please do not use this to mutate data, use `performInNewBackgroundContext`
     instead.
     */
    public var mainContext: NSManagedObjectContext {
        get {
            if _mainContext == nil {
                let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
                context.undoManager = nil
                context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
                context.persistentStoreCoordinator = self.persistentStoreCoordinator

                NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.mainContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: context)

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
                let model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)
                let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
                try! persistentStoreCoordinator.addPersistentStore(storeType: self.storeType, bundle: self.modelBundle, modelName: self.modelName, storeName: self.storeName)
                _persistentStoreCoordinator = persistentStoreCoordinator
            }

            return _persistentStoreCoordinator!
        }
    }

    private lazy var disposablePersistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let model = NSManagedObjectModel(bundle: self.modelBundle, name: self.modelName)
        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)
        try! persistentStoreCoordinator.addPersistentStore(storeType: .InMemory, bundle: self.modelBundle, modelName: self.modelName, storeName: self.storeName)

        return persistentStoreCoordinator
    }()

    /**
     Initializes a DATAStack using the bundle name as the model name, so if your target is called ModernApp,
     it will look for a ModernApp.xcdatamodeld.
     */
    public override init() {
        let bundle = NSBundle.mainBundle()
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
            self.modelName = bundleName
        }
    }

    /**
     Initializes a DATAStack using the provided model name.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     */
    public init(modelName: String) {
        self.modelName = modelName
    }

    /**
     Initializes a DATAStack using the provided model name, bundle and storeType.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     */
    public init(modelName: String, storeType: DATAStackStoreType) {
        self.modelName = modelName
        self.storeType = storeType
    }

    /**
     Initializes a DATAStack using the provided model name, bundle and storeType.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter bundle: The bundle where your Core Data model is located, normally your Core Data model is in
     the main bundle but when using unit tests sometimes your Core Data model could be located where your tests
     are located.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     */
    public init(modelName: String, bundle: NSBundle, storeType: DATAStackStoreType) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType
    }

    /**
     Initializes a DATAStack using the provided model name, bundle, storeType and store name.
     - parameter modelName: The name of your Core Data model (xcdatamodeld).
     - parameter bundle: The bundle where your Core Data model is located, normally your Core Data model is in
     the main bundle but when using unit tests sometimes your Core Data model could be located where your tests
     are located.
     - parameter storeType: The store type to be used, you have .InMemory and .SQLite, the first one is memory
     based and doesn't save to disk, while the second one creates a .sqlite file and stores things there.
     - parameter storeName: Normally your file would be named as your model name is named, so if your model 
     name is AwesomeApp then the .sqlite file will be named AwesomeApp.sqlite, this attribute allows your to
     change that.
     */
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

    /**
     Returns a new main context that is detached from saving to disk.
     */
    public func newDisposableMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator
        context.undoManager = nil

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.newDisposableMainContextWillSave(_:)), name: NSManagedObjectContextWillSaveNotification, object: context)

        return context
    }

    /**
     Returns a background context perfect for data mutability operations. Make sure to never use it on the main thread. Use `performBlock` or `performBlockAndWait` to use it.
     */
    public func newBackgroundContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy

        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.backgroundContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: context)

        return context
    }

    /**
     Returns a background context perfect for data mutability operations.
     - parameter operation: The block that contains the created background context.
     */
    public func performInNewBackgroundContext(operation: (backgroundContext: NSManagedObjectContext) -> Void) {
        let context = self.newBackgroundContext()
        let contextBlock: @convention(block) () -> Void = {
            operation(backgroundContext: context)
        }
        let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
        context.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
    }

    func saveMainThread(completion: ((error: NSError?) -> Void)?) {
        var writerContextError: NSError?
        let writerContextBlock: @convention(block) Void -> Void = {
            do {
                try self.writerContext.save()
                if TestCheck.isTesting {
                    completion?(error: nil)
                }
            } catch let parentError as NSError {
                writerContextError = parentError
            }
        }
        let writerContextBlockObject : AnyObject = unsafeBitCast(writerContextBlock, AnyObject.self)

        let mainContextBlock: @convention(block) Void -> Void = {
            self.writerContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: writerContextBlockObject)
            dispatch_async(dispatch_get_main_queue()) {
                completion?(error: writerContextError)
            }
        }
        let mainContextBlockObject : AnyObject = unsafeBitCast(mainContextBlock, AnyObject.self)
        self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: mainContextBlockObject)
    }

    /**
     Drops the database. Useful for ObjC compatibility, since it doesn't allow `throws` Use `drop` in Swift.
     */
    public func forceDrop() {
        try! drop()
    }

    /**
     Drops the database.
     */
    public func drop() throws {
        guard let store = self.persistentStoreCoordinator.persistentStores.last, storeURL = store.URL, storePath = storeURL.path
            else { throw NSError(info: "Persistent store coordinator not found", previousError: nil) }

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
                throw NSError(info: "Could not delete persistent store shm", previousError: error)
            }
        }

        let wal = sqliteFile + ".sqlite-wal"
        if fileManager.fileExistsAtPath(wal) {
            do {
                try fileManager.removeItemAtURL(NSURL.fileURLWithPath(wal))
            } catch let error as NSError {
                throw NSError(info: "Could not delete persistent store wal", previousError: error)
            }
        }
        
        if fileManager.fileExistsAtPath(storePath) {
            do {
                try fileManager.removeItemAtURL(storeURL)
            } catch let error as NSError {
                throw NSError(info: "Could not delete sqlite file", previousError: error)
            }
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func mainContextDidSave(notification: NSNotification) {
        self.saveMainThread { error in
            if let error = error {
                fatalError("Failed to save objects in main thread: \(error)")
            }
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func newDisposableMainContextWillSave(notification: NSNotification) {
        if let context = notification.object as? NSManagedObjectContext {
            context.reset()
        }
    }

    // Can't be private, has to be internal in order to be used as a selector.
    func backgroundContextDidSave(notification: NSNotification) throws {
        if NSThread.isMainThread() && TestCheck.isTesting == false {
            throw NSError(info: "Background context saved in the main thread. Use context's `performBlock`", previousError: nil)
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
            self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
        }
    }

    private static func backgroundConcurrencyType() -> NSManagedObjectContextConcurrencyType {
        return TestCheck.isTesting ? .MainQueueConcurrencyType : .PrivateQueueConcurrencyType
    }

    private static func performSelectorForBackgroundContext() -> Selector {
        return TestCheck.isTesting ? NSSelectorFromString("performBlockAndWait:") : NSSelectorFromString("performBlock:")
    }
}

extension NSPersistentStoreCoordinator {
    func addPersistentStore(storeType storeType: DATAStackStoreType, bundle: NSBundle, modelName: String, storeName: String?) throws {
        let filePath = (storeName ?? modelName) + ".sqlite"
        switch storeType {
        case .InMemory:
            do {
                try self.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            } catch let error as NSError {
                throw NSError(info: "There was an error creating the persistentStoreCoordinator for in memory store", previousError: error)
            }

            break
        case .SQLite:
            let storeURL = NSURL.directoryURL().URLByAppendingPathComponent(filePath)
            guard let storePath = storeURL.path else { throw NSError(info: "Store path not found: \(storeURL)", previousError: nil) }

            let shouldPreloadDatabase = !NSFileManager.defaultManager().fileExistsAtPath(storePath)
            if shouldPreloadDatabase {
                if let preloadedPath = bundle.pathForResource(modelName, ofType: "sqlite") {
                    let preloadURL = NSURL.fileURLWithPath(preloadedPath)

                    do {
                        try NSFileManager.defaultManager().copyItemAtURL(preloadURL, toURL: storeURL)
                    } catch let error as NSError {
                        throw NSError(info: "Oops, could not copy preloaded data", previousError: error)
                    }
                }
            }

            do {
                try self.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
            } catch {
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(storePath)
                    do {
                        try self.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: storeURL, options: [NSMigratePersistentStoresAutomaticallyOption : true, NSInferMappingModelAutomaticallyOption : true])
                    } catch let addPersistentError as NSError {
                        throw NSError(info: "There was an error creating the persistentStoreCoordinator", previousError: addPersistentError)
                    }
                } catch let removingError as NSError {
                    throw NSError(info: "There was an error removing the persistentStoreCoordinator", previousError: removingError)
                }
            }

            let shouldExcludeSQLiteFromBackup = storeType == .SQLite && TestCheck.isTesting == false
            if shouldExcludeSQLiteFromBackup {
                do {
                    try storeURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                } catch let excludingError as NSError {
                    throw NSError(info: "Excluding SQLite file from backup caused an error", previousError: excludingError)
                }
            }

            break
        }
    }
}

extension NSManagedObjectModel {
    convenience init(bundle: NSBundle, name: String) {
        if let momdModelURL = bundle.URLForResource(name, withExtension: "momd") {
            self.init(contentsOfURL: momdModelURL)!
        } else if let momModelURL = bundle.URLForResource(name, withExtension: "mom") {
            self.init(contentsOfURL: momModelURL)!
        } else {
            self.init()
        }
    }
}

extension NSError {
    convenience init(info: String, previousError: NSError?) {
        if let previousError = previousError {
            var userInfo = previousError.userInfo
            if let _ = userInfo[NSLocalizedFailureReasonErrorKey] {
                userInfo["Additional reason"] = info
            } else {
                userInfo[NSLocalizedFailureReasonErrorKey] = info
            }

            self.init(domain: previousError.domain, code: previousError.code, userInfo: userInfo)
        } else {
            var userInfo = [String : AnyObject]()
            userInfo[NSLocalizedDescriptionKey] = info
            self.init(domain: "com.3lvis.DATAStack", code: 9999, userInfo: userInfo)
        }
    }
}

extension NSURL {
    private static func directoryURL() -> NSURL {
        #if os(tvOS)
            return NSFileManager.defaultManager().URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask).last!
        #else
            return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
        #endif
    }
}