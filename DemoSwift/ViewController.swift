import UIKit
import CoreData
import DATASource

class ViewController: UITableViewController {

    var dataStack: DATAStack

    lazy var dataSource: DATASource = {
        let request: NSFetchRequest = NSFetchRequest<NSFetchRequestResult>(entityName: "User")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let dataSource = DATASource(tableView: self.tableView, cellIdentifier: "Cell", fetchRequest: request, mainContext: self.dataStack.mainContext, configuration: { cell, item, indexPath in
            if let name = item.value(forKey: "name") as? String, let createdDate = item.value(forKey: "createdDate") as? NSDate {
                cell.textLabel?.text = name + " - " + createdDate.description
            }
        })

        return dataSource
    }()

    init(dataStack: DATAStack) {
        self.dataStack = dataStack

        super.init(style: .plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self.dataSource

        let backgroundButton = UIBarButtonItem(title: "Background", style: .done, target: self, action: #selector(ViewController.createBackground))
        self.navigationItem.rightBarButtonItem = backgroundButton

        let mainButton = UIBarButtonItem(title: "Main", style: .done, target: self, action: #selector(ViewController.createMain))
        self.navigationItem.leftBarButtonItem = mainButton
    }

    func createBackground() {
        self.dataStack.performInNewBackgroundContext { backgroundContext in
            let entity = NSEntityDescription.entity(forEntityName: "User", in: backgroundContext)!
            let object = NSManagedObject(entity: entity, insertInto: backgroundContext)
            object.setValue("Background", forKey: "name")
            object.setValue(NSDate(), forKey: "createdDate")
            try! backgroundContext.save()
        }
    }

    func createMain() {
        let entity = NSEntityDescription.entity(forEntityName: "User", in: self.dataStack.mainContext)!
        let object = NSManagedObject(entity: entity, insertInto: self.dataStack.mainContext)
        object.setValue("Main", forKey: "name")
        object.setValue(Date(), forKey: "createdDate")
        try! self.dataStack.mainContext.save()
    }
}
