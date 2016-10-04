import XCTest
import CoreData

class Tests: XCTestCase {
    func createDataStack(_ storeType: DATAStackStoreType = .inMemory) -> DATAStack {
        let dataStack = DATAStack(modelName: "Model", bundle: Bundle(for: Tests.self), storeType: storeType)

        return dataStack
    }

    func insertUserInContext(_ context: NSManagedObjectContext) {
        let user = NSEntityDescription.insertNewObject(forEntityName: "User", into: context)
        user.setValue(NSNumber(value: 1), forKey: "remoteID")
        user.setValue("Joshua Ivanof", forKey: "name")
        try! context.save()
    }

    func fetchObjectsInContext(_ context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest<NSManagedObject>(entityName: "User")
        let objects = try! context.fetch(request)

        return objects
    }

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
            self.insertUserInContext(backgroundContext)

            let objects = self.fetchObjectsInContext(backgroundContext)
            XCTAssertEqual(objects.count, 1)
        }

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)
    }

    func testNewBackgroundContextSave() {
        var synchronous = false
        let dataStack = self.createDataStack()
        let backgroundContext = dataStack.newBackgroundContext()
        backgroundContext.performAndWait {
            synchronous = true
            self.insertUserInContext(backgroundContext)
            let objects = self.fetchObjectsInContext(backgroundContext)
            XCTAssertEqual(objects.count, 1)
        }

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertTrue(synchronous)
    }

    func testRequestWithDictionaryResultType() {
        let dataStack = self.createDataStack()
        self.insertUserInContext(dataStack.mainContext)

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

    func testMainDisposableContextSave() {
        let dataStack = self.createDataStack()

        let disposableContext = dataStack.newDisposableMainContext()
        self.insertUserInContext(disposableContext)
        let objects = self.fetchObjectsInContext(disposableContext)
        XCTAssertEqual(objects.count, 0)
    }

    func testBackgroundDisposableContextSave() {
        let dataStack = self.createDataStack()

        var synchronous = false
        dataStack.performInNewDisposableBackgroundContext { disposableBackgroundContext in
            synchronous = true
            self.insertUserInContext(disposableBackgroundContext)
            let objects = self.fetchObjectsInContext(disposableBackgroundContext)
            XCTAssertEqual(objects.count, 0)
        }

        XCTAssertTrue(synchronous)
    }

    func testDrop() {
        let dataStack = self.createDataStack(.sqLite)

        dataStack.performInNewBackgroundContext { backgroundContext in
            self.insertUserInContext(backgroundContext)
        }

        let objectsA = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objectsA.count, 1)

        let _ = try? dataStack.drop()

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 0)
    }

    func testAlternativeModel() {
        let dataStack = DATAStack(modelName: "DataModel", bundle: Bundle(for: Tests.self), storeType: .inMemory)
        self.insertUserInContext(dataStack.mainContext)

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertNotNil(dataStack)
    }
}
