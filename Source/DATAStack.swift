import Foundation
import CoreData

// MARK: - Notifications

public let DATAStackDidPersistNotification = "net.3lvis.DATAStack.DidPersistNotification"
public let DATAStackDidFailToPersistNotification = "net.3lvis.DATAStack.DidFailToPersistNotification"

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

    /// The context for the main queue
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

    /// The parent context of all `NSManagedObjectContext` instances.
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

    /// The persistent store coordinator shared across all `NSManagedObjectContext` instances
    /// created by this instance
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

                guard let unwrappedModel = model else { fatalError("Model with model name \(self.modelName) not found in bundle \(self.modelBundle)") }
                let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: unwrappedModel)

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
        if let bundleName = bundle.infoDictionary?["CFBundleName"] as? String {
            self.modelName = bundleName
        }
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
        if let context = notification.object as? NSManagedObjectContext {
            context.reset()
        }
    }

    internal func backgroundContextDidSave(notification: NSNotification) {
        if NSThread.isMainThread() && TestCheck.isTesting == false {
            fatalError("Background context saved in the main thread. Use context's `performBlock`")
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChangesFromContextDidSaveNotification(notification)
            }
            
            let blockObject: AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
            self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
        }
    }

    // MARK: - Public
    
    /// Creates a new disposable main context, which resets on save
    public func newDisposableMainContext() -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator
        context.undoManager = nil
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.newDisposableMainContextWillSave(_:)), name: NSManagedObjectContextWillSaveNotification, object: context)
        
        return context
    }
    
    /// Creates a new context which can be used on a background thread.
    public func newBackgroundContext(name: String? = nil) -> NSManagedObjectContext {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.persistentStoreCoordinator = self.persistentStoreCoordinator
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.name = name
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(DATAStack.backgroundContextDidSave(_:)), name: NSManagedObjectContextDidSaveNotification, object: context)
        
        return context
    }

    /// Creates a new background context, performs `operation` within the context, and then merges changes to the `mainContext`
    public func performInNewBackgroundContext(operation: (backgroundContext: NSManagedObjectContext) -> ()) {
        let context = newBackgroundContext()

        let contextBlock: @convention(block) () -> Void = {
            operation(backgroundContext: context)
        }
        let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
        context.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
    }
    
    /// Persists the stack. Calls `completion` with an error if something fails.
    /// This will not save child context's. They must be saved before invoking this method
    /// for their changes to persist.
    public func persistWithCompletion(completion: ((ErrorType?) -> Void)? = nil) {
        let innerCompletion: ErrorType? -> Void = { error in
            let notificationCenter = NSNotificationCenter.defaultCenter()
            if let error = error as? NSError {
                notificationCenter.postNotificationName(DATAStackDidFailToPersistNotification, object: error)
            } else {
                notificationCenter.postNotificationName(DATAStackDidPersistNotification, object: self)
            }
            
            completion?(error)
        }
        
        let writerContextBlock: @convention(block) Void -> Void = {
            do {
                try self.writerContext.save()
                if TestCheck.isTesting {
                    innerCompletion(nil)
                } else {
                    dispatch_async(dispatch_get_main_queue()) {
                        innerCompletion(nil)
                    }
                }
            } catch {
                innerCompletion(error)
            }
        }
        let writerContextBlockObject: AnyObject = unsafeBitCast(writerContextBlock, AnyObject.self)
        
        let mainContextBlock: @convention(block) Void -> Void = {
            do {
                try self.mainContext.save()
                self.writerContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: writerContextBlockObject)
            } catch {
                innerCompletion(error)
            }
        }
        let mainContextBlockObject: AnyObject = unsafeBitCast(mainContextBlock, AnyObject.self)
        self.mainContext.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: mainContextBlockObject)
    }
    
    /// Drops a collection for an `entity`. This is not object-graph safe, and
    /// mostly for development purposes. Deletes in production should respect
    /// the object graph
    public func dropEntityCollection(entityName: String) -> Bool {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        
        if #available(iOS 9.0, OSX 10.11, *) {
            return batchDeleteCollection(fetchRequest)
        } else {
            // Fallback on earlier versions
            return fetchAndDeleteCollection(fetchRequest)
        }
        
    }
    
    /// Utilizes `NSBatchDeleteRequest` to delete objects matching `fetchRequest`
    @available(iOS 9.0, OSX 10.11, *)
    private func batchDeleteCollection(fetchRequest: NSFetchRequest) -> Bool {
        let batchDeleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
        
        do {
            try self._persistentStoreCoordinator?.executeRequest(batchDeleteRequest, withContext: mainContext)
            return true
        } catch {
            return false
        }
    }
    
    /// Loads objects matching `fetchRequest` into memory, and then deletes them.
    private func fetchAndDeleteCollection(fetchRequest: NSFetchRequest) -> Bool {
        fetchRequest.includesPropertyValues = false
        
        do {
            guard let objects = try mainContext.executeFetchRequest(fetchRequest) as? [NSManagedObject]
            else {
                return false
            }
            
            for object in objects {
                mainContext.deleteObject(object)
            }
            
            return true
        } catch {
            return false
        }
    }

    /// Drops the entire stack.
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
