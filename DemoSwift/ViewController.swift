import UIKit
import CoreData
import DATASource
import DATAStack

class ViewController: UITableViewController {

    var dataStack: DATAStack

    lazy var dataSource: DATASource = {
        let request: NSFetchRequest = NSFetchRequest(entityName: "User")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let dataSource = DATASource(tableView: self.tableView, cellIdentifier: "Cell", fetchRequest: request, mainContext: self.dataStack.mainContext, configuration: { cell, item, indexPath in
            if let name = item.valueForKey("name") as? String, createdDate = item.valueForKey("createdDate") as? NSDate {
                cell.textLabel?.text =  name + " - " + createdDate.description
            }
        })

        return dataSource
    }()

    init(dataStack: DATAStack) {
        self.dataStack = dataStack

        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self.dataSource

        let backgroundButton = UIBarButtonItem(title: "Background", style: .Done, target: self, action: "createBackground")
        self.navigationItem.rightBarButtonItem = backgroundButton

        let mainButton = UIBarButtonItem(title: "Main", style: .Done, target: self, action: "createMain")
        self.navigationItem.leftBarButtonItem = mainButton
    }

    func createBackground() {
        self.dataStack.performInNewBackgroundContext { backgroundContext in
            let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: backgroundContext)!
            let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: backgroundContext)
            object.setValue("Background", forKey: "name")
            object.setValue(NSDate(), forKey: "createdDate")
            try! backgroundContext.save()
        }
    }

    func createMain() {
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: self.dataStack.mainContext)!
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: self.dataStack.mainContext)
        object.setValue("Main", forKey: "name")
        object.setValue(NSDate(), forKey: "createdDate")
        try! self.dataStack.mainContext.save()
    }
}
