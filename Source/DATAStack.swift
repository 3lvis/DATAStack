import Foundation
import CoreData
import TestCheck

@objc public class DATAStack: NSObject {
    // MARK: - Enums

    @objc public enum DATAStackStoreType: Int {
        case InMemory, SQLite
    }

    // MARK: - Variables

    private var storeType: DATAStackStoreType = .SQLite

    private var modelName: String = ""

    private var modelBundle: NSBundle = NSBundle.mainBundle()

    public private(set) lazy var mainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.parentContext = self.writerContext

        return context
        }()

    private lazy var writerContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: DATAStack.backgroundConcurrencyType())
        context.undoManager = nil
        context.mergePolicy = NSMergeByPropertyStoreTrumpMergePolicy
        context.persistentStoreCoordinator = self.persistentStoreCoordinator

        return context
        }()

    private lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        let filePath = self.modelName + ".sqlite"

        guard let modelURL = self.modelBundle.URLForResource(self.modelName, withExtension: "momd"), model = NSManagedObjectModel(contentsOfURL: modelURL)
            else { fatalError("Model with model name \(self.modelName) not found in bundle \(self.modelBundle)") }

        let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: model)

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

            let shouldExcludeSQLiteFromBackup = self.storeType == .SQLite && !Test.isRunning()
            if shouldExcludeSQLiteFromBackup {
                do {
                    try storeURL.setResourceValue(true, forKey: NSURLIsExcludedFromBackupKey)
                } catch let excludingError as NSError {
                    fatalError("Excluding SQLite file from backup caused an error: \(excludingError)")
                }
            }

            break
        }

        return persistentStoreCoordinator

        }()

    public private(set) lazy var disposableMainContext: NSManagedObjectContext = {
        let context = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        context.persistentStoreCoordinator = self.disposablePersistentStoreCoordinator

        return context
        }()

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

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self, name: NSManagedObjectContextDidSaveNotification, object: nil)
    }

    // MARK: - Observers

    internal func backgroundContextDidSave(backgroundContextNotification: NSNotification) {
        if NSThread.isMainThread() && !Test.isRunning() {
            fatalError("Background context saved in the main thread. Use context's `performBlock`")
        } else {
            let contextBlock: @convention(block) () -> Void = {
                self.mainContext.mergeChangesFromContextDidSaveNotification(backgroundContextNotification)
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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "backgroundContextDidSave:", name: NSManagedObjectContextDidSaveNotification, object: context)

        let contextBlock: @convention(block) () -> Void = {
            operation(backgroundContext: context)
        }
        let blockObject : AnyObject = unsafeBitCast(contextBlock, AnyObject.self)
        context.performSelector(DATAStack.performSelectorForBackgroundContext(), withObject: blockObject)
    }

    public func persistWithCompletion(completion: () -> ()) {
        let writerContextBlock: @convention(block) () -> Void = {
            do {
                try self.writerContext.save()
                if Test.isRunning() {
                    completion()
                } else {
                    dispatch_async(dispatch_get_main_queue(), {
                        completion()
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

        // self.writerContext = nil
        // self.mainContext = nil
        // self.persistentStoreCoordinator = nil

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
        return NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask).last!
    }

    private static func backgroundConcurrencyType() -> NSManagedObjectContextConcurrencyType {
        return Test.isRunning() ? .MainQueueConcurrencyType : .PrivateQueueConcurrencyType
    }

    private static func performSelectorForBackgroundContext() -> Selector {
        return Test.isRunning() ? NSSelectorFromString("performBlockAndWait:") : NSSelectorFromString("performBlock:")
    }
}
