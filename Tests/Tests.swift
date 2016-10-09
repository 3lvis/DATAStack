import XCTest
import CoreData

extension XCTestCase {
    func createDataStack(_ storeType: DATAStackStoreType = .inMemory) -> DATAStack {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: Tests.self), storeType: storeType)

        return dataStack
    }

    func insertUser(in context: NSManagedObjectContext) {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
        user.setValue(NSNumber(value: 1), forKey: "remoteID")
        user.setValue("Joshua Ivanof", forKey: "name")
        try! context.save()
    }

    func fetch(in context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        let objects = try! context.fetch(request)

        return objects
    }
}

class InitializerTests: XCTestCase {
    func testInitializeUsingXCDataModeld() {
        let dataStack = DATAStack(modelName: "DataModel", bundle: Bundle(for: Tests.self), storeType: .inMemory)

        self.insertUser(in: dataStack.mainContext)
        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testInitializeUsingXCDataModel() {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: Tests.self), storeType: .inMemory)

        self.insertUser(in: dataStack.mainContext)
        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testInitializingUsingNSManagedObjectModel() {
        let model = NSManagedObjectModel(bundle: Bundle(for: Tests.self), name: "Model")
        let dataStack = DATAStack(model: model, storeType: .inMemory)

        self.insertUser(in: dataStack.mainContext)
        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)
    }
}

class Tests: XCTestCase {
    func testSynchronousBackgroundContext() {
        let dataStack = self.createDataStack()

        var synchronous = false
        dataStack.performInNewBackgroundContext { _ in
            synchronous = true
        }

        XCTAssertTrue(synchronous)
    }

    func testBackgroundContextSave() {
        let dataStack = self.createDataStack()

        dataStack.performInNewBackgroundContext { backgroundContext in
            self.insertUser(in: backgroundContext)

            let objects = self.fetch(in: backgroundContext)
            XCTAssertEqual(objects.count, 1)
        }

        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testNewBackgroundContextSave() {
        var synchronous = false
        let dataStack = self.createDataStack()
        let backgroundContext = dataStack.newBackgroundContext()
        backgroundContext.performAndWait {
            synchronous = true
            self.insertUser(in: backgroundContext)
            let objects = self.fetch(in: backgroundContext)
            XCTAssertEqual(objects.count, 1)
        }

        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertTrue(synchronous)
    }

    func testRequestWithDictionaryResultType() {
        let dataStack = self.createDataStack()
        self.insertUser(in: dataStack.mainContext)

        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        let objects = try! dataStack.mainContext.fetch(request)
        XCTAssertEqual(objects.count, 1)

        let expression = NSExpressionDescription()
        expression.name = "objectID"
        expression.expression = NSExpression.expressionForEvaluatedObject()
        expression.expressionResultType = .objectIDAttributeType

        let dictionaryRequest = NSFetchRequest<NSDictionary>(entityName: "User")
        dictionaryRequest.resultType = .dictionaryResultType
        dictionaryRequest.propertiesToFetch = [expression, "remoteID"]

        let dictionaryObjects = try! dataStack.mainContext.fetch(dictionaryRequest)
        XCTAssertEqual(dictionaryObjects.count, 1)
    }

    func testDisposableContextSave() {
        let dataStack = self.createDataStack()

        let disposableContext = dataStack.newDisposableMainContext()
        self.insertUser(in: disposableContext)
        let objects = self.fetch(in: disposableContext)
        XCTAssertEqual(objects.count, 0)
    }

    func testDrop() {
        let dataStack = self.createDataStack(.sqLite)

        dataStack.performInNewBackgroundContext { backgroundContext in
            self.insertUser(in: backgroundContext)
        }

        let objectsA = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objectsA.count, 1)

        let _ = try? dataStack.drop()

        let objects = self.fetch(in: dataStack.mainContext)
        XCTAssertEqual(objects.count, 0)
    }
}
