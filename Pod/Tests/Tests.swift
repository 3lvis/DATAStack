import XCTest
import CoreData

class Tests: XCTestCase {
    func createDataStack() -> DATAStack {
        let dataStack = DATAStack(modelName: "Model", bundle: NSBundle(forClass: Tests.self), storeType: .InMemory)

        return dataStack
    }

    func insertUserInContext(context: NSManagedObjectContext) {
        let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: context)
        user.setValue(NSNumber(integer: 1), forKey: "remoteID")
        user.setValue("Joshua Ivanof", forKey: "name")
        try! context.save()
    }

    func testSynchronousPersist() {
        let dataStack = self.createDataStack()

        var synchronous = false
        dataStack.persistWithCompletion {
            synchronous = true
        }

        XCTAssertTrue(synchronous)
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

            let request = NSFetchRequest(entityName: "User")
            let objects = try! backgroundContext.executeFetchRequest(request)
            XCTAssertEqual(objects.count, 1)

            dataStack.persistWithCompletion({
                let objects = try! dataStack.mainContext.executeFetchRequest(request)
                XCTAssertEqual(objects.count, 1)
            })
        }
    }

    func testRequestWithDictionaryResultType() {
        let dataStack = self.createDataStack()
        self.insertUserInContext(dataStack.mainContext)

        dataStack.persistWithCompletion {
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
    }

    func testDrop() {
        let dataStack = self.createDataStack()
        self.insertUserInContext(dataStack.mainContext)
    }
}
