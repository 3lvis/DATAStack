import UIKit

import CoreData
import DATASource

class CollectionController: UICollectionViewController {
    unowned var dataStack: DATAStack
    var counter: Int = 0

    lazy var dataSource: DATASource = {
        guard let collectionView = self.collectionView else { fatalError("CollectionView is nil") }

        let request: NSFetchRequest = NSFetchRequest(entityName: "User")
        request.sortDescriptors = [
            NSSortDescriptor(key: "name", ascending: true)
        ]

        let dataSource = DATASource(collectionView: collectionView, cellIdentifier: CollectionCell.Identifier, fetchRequest: request, mainContext: self.dataStack.mainContext, configuration: { cell, item, indexPath in
            let collectionCell = cell as! CollectionCell
            collectionCell.textLabel.text = item.valueForKey("name") as? String
        })

        return dataSource
    }()

    init(layout: UICollectionViewLayout, dataStack: DATAStack) {
        self.dataStack = dataStack

        super.init(collectionViewLayout: layout)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        guard let collectionView = self.collectionView else { fatalError("CollectionView is nil") }

        collectionView.accessibilityHint = "Group of cells"
        collectionView.registerClass(CollectionCell.self, forCellWithReuseIdentifier: CollectionCell.Identifier)
        collectionView.dataSource = self.dataSource
        collectionView.backgroundColor = UIColor.whiteColor()
        collectionView.contentInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .Add, target: self, action: #selector(CollectionController.saveAction))
    }

    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)

        let delayTime = dispatch_time(DISPATCH_TIME_NOW, Int64(0.2 * Double(NSEC_PER_SEC)))
        dispatch_after(delayTime, dispatch_get_main_queue()) {
            let view = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 200))
            view.accessibilityLabel = "Delay view"
            self.view.addSubview(view)
        }
    }

    func saveAction() {
        self.dataStack.performInNewBackgroundContext { backgroundContext in
            let entity = NSEntityDescription.entityForName("User", inManagedObjectContext: backgroundContext)!
            let user = NSManagedObject(entity: entity, insertIntoManagedObjectContext: backgroundContext)
            user.setValue(String(self.counter), forKey: "name")
            self.counter += 1
            try! backgroundContext.save()
        }
    }
}

extension CollectionController {
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        guard let object = self.dataSource.objectAtIndexPath(indexPath) else { return }

        self.dataStack.performInNewBackgroundContext { backgroundContext in
            let backgroundObject = backgroundContext.objectWithID(object.objectID)
            backgroundContext.deleteObject(backgroundObject)
            try! backgroundContext.save()
        }
    }
}
