import XCTest
import CoreData

class Tests: XCTestCase {
    func createDataStack(storeType: DATAStackStoreType = .InMemory) -> DATAStack {
        let dataStack = DATAStack(modelName: "Model", bundle: NSBundle(forClass: Tests.self), storeType: storeType)

        return dataStack
    }

    func insertUserInContext(context: NSManagedObjectContext) {
        let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
        user.setValue(NSNumber(integer: 1), forKey: "remoteID")
        user.setValue("Joshua Ivanof", forKey: "name")
        try! context.save()
    }

    func fetchObjectsInContext(context: NSManagedObjectContext) -> [NSManagedObject] {
        let request = NSFetchRequest(entityName: "User")
        let objects = try! context.executeFetchRequest(request) as! [NSManagedObject]

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
        backgroundContext.performBlockAndWait {
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

        let request = NSFetchRequest(entityName: "User")
        let objects = try! dataStack.mainContext.executeFetchRequest(request)
        XCTAssertEqual(objects.count, 1)

        let expression = NSExpressionDescription()
        expression.name = "objectID"
        expression.expression = NSExpression.expressionForEvaluatedObject()
        expression.expressionResultType = .ObjectIDAttributeType

        let dictionaryRequest = NSFetchRequest(entityName: "User")
        dictionaryRequest.resultType = .DictionaryResultType
        dictionaryRequest.propertiesToFetch = [expression, "remoteID"]

        let dictionaryObjects = try! dataStack.mainContext.executeFetchRequest(dictionaryRequest)
        XCTAssertEqual(dictionaryObjects.count, 1)
    }

    func testDisposableContextSave() {
        let dataStack = self.createDataStack()

        let disposableContext = dataStack.newDisposableMainContext()
        self.insertUserInContext(disposableContext)
        let objects = self.fetchObjectsInContext(disposableContext)
        XCTAssertEqual(objects.count, 0)
    }

    func testDrop() {
        let dataStack = self.createDataStack(.SQLite)

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
        let dataStack = DATAStack(modelName: "DataModel", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)
        self.insertUserInContext(dataStack.mainContext)

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertNotNil(dataStack)
    }

    func testInitializationWithModel() {
        let bundle = NSBundle(forClass: Tests.self)
        let url = bundle.URLForResource("DataModel", withExtension: "mom")!
        let model = NSManagedObjectModel(contentsOfURL: url)!
        let dataStack = DATAStack(name: "DataModel", managedObjectModel: model)
        self.insertUserInContext(dataStack.mainContext)

        let objects = self.fetchObjectsInContext(dataStack.mainContext)
        XCTAssertEqual(objects.count, 1)

        XCTAssertNotNil(dataStack)
    }
}
