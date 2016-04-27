import UIKit
import CoreData
import DATASource

class ViewController: UITableViewController {

    var dataStack: DATAStack
    var backgroundContext: NSManagedObjectContext

    lazy var dataSource: DATASource = {
        let request: NSFetchRequest = NSFetchRequest(entityName: "User")
        request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]

        let dataSource = DATASource(tableView: self.tableView, cellIdentifier: "Cell", fetchRequest: request, mainContext: self.dataStack.mainContext, configuration: { cell, item, indexPath in
            if let name = item.valueForKey("name") as? String, createdDate = item.valueForKey("createdDate") as? NSDate, score = item.valueForKey("score") as? NSNumber {
                cell.textLabel?.text =  name + " - " + score.description
                
            }
        })

        return dataSource
    }()

    init(dataStack: DATAStack) {
        self.dataStack = dataStack
        self.dataStack.mainContext.stalenessInterval = 0.0
        
        self.backgroundContext = dataStack.newBackgroundContext("ViewController Background Context")

        super.init(style: .Plain)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        self.tableView.registerClass(UITableViewCell.self, forCellReuseIdentifier: "Cell")
        self.tableView.dataSource = self.dataSource

        let mainButton = UIBarButtonItem(title: "Main", style: .Done, target: self, action: #selector(ViewController.createMain))
        let backgroundButton = UIBarButtonItem(title: "Background", style: .Done, target: self, action: #selector(ViewController.createBackground))
        self.navigationItem.rightBarButtonItems = [backgroundButton, mainButton]

        let editButton = UIBarButtonItem(title: "Edit", style: .Done, target: self, action: #selector(ViewController.editUsers))
        let saveButton = UIBarButtonItem(title: "Save", style: .Done, target: self, action: #selector(ViewController.persistStack))
        self.navigationItem.leftBarButtonItems = [editButton, saveButton]
        
        let tripleTapGesture = UITapGestureRecognizer(target: self, action: #selector(ViewController.dropStack))
        tripleTapGesture.numberOfTapsRequired = 3
        self.navigationController?.navigationBar.addGestureRecognizer(tripleTapGesture)
    }

    func createBackground() {
        self.dataStack.performInNewBackgroundContext { backgroundContext in
            let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: backgroundContext)!
            let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: backgroundContext)
            object.setValue("Background", forKey: "name")
            object.setValue(NSDate(), forKey: "createdDate")
            object.setValue(0, forKey: "score")
            try! backgroundContext.save()
        }
    }

    func createMain() {
        let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: self.dataStack.mainContext)!
        let object = NSManagedObject(entity: entity, insertIntoManagedObjectContext: self.dataStack.mainContext)
        object.setValue("Main", forKey: "name")
        object.setValue(NSDate(), forKey: "createdDate")
        object.setValue(0, forKey: "score")
        try! self.dataStack.mainContext.save()
    }
    
    func editUsers() {
        editUsersInContext(backgroundContext)
    }
    
    func persistStack() {
        self.dataStack.persistWithCompletion { error in
            if let error = error {
                print("An error occurred while persisting the stack:", error)
            } else {
                print("Stack has successfully persisted!")
            }
        }
    }
    
    func dropStack() {
        self.dataStack.drop()
        self.tableView.reloadData()
    }
    
    private func editUsersInContext(context: NSManagedObjectContext) {
        context.performBlock {
            /// Get all users created on the main context
            let fetchRequest = NSFetchRequest(entityName: "User")
            fetchRequest.predicate = NSPredicate(format: "%K contains[c] %@", "name", "main")
            
            let users = try! context.executeFetchRequest(fetchRequest)
            
            /// Update their scores
            for user in users {
                let score = user.valueForKey("score") as! NSNumber
                let newScore = NSNumber(int: score.integerValue + 1)
                
                user.setValue(newScore, forKey: "score")
            }
            
            try! context.save()
        }
    }
}
