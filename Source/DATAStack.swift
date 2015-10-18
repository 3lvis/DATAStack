import Foundation
import CoreData
import TestCheck

public class DATAStack: NSObject {
    // MARK: - Enums

    public enum StoreType {
        case InMemoryStoreType, SQLiteStoreType
    }

    // MARK: - Variables

    private var storeType: StoreType

    private var modelName: String

    private var modelBundle: NSBundle

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
        case .InMemoryStoreType:
            do {
                try persistentStoreCoordinator.addPersistentStoreWithType(NSInMemoryStoreType, configuration: nil, URL: nil, options: nil)
            } catch let error as NSError {
                fatalError("There was an error creating the persistentStoreCoordinator: \(error)")
            }

            break
        case .SQLiteStoreType:
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

            let shouldExcludeSQLiteFromBackup = self.storeType == .SQLiteStoreType && !Test.isRunning()
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

    override convenience init() {
        let bundle = NSBundle.mainBundle()
        let bundleName = bundle.infoDictionary!["CFBundleName"] as! String

        self.init(modelName: bundleName)
    }

    public convenience init(modelName: String) {
        self.init(modelName: modelName, storeType: .SQLiteStoreType)
    }

    public init(modelName: String, bundle: NSBundle = NSBundle.mainBundle(), storeType: StoreType) {
        self.modelName = modelName
        self.modelBundle = bundle
        self.storeType = storeType

        super.init()
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
        
    }
    
    public func drop() {
        
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
