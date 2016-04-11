#import "ViewController.h"
@import CoreData;
@import DATASource;
#import "DemoObjectiveC-Swift.h"
#import "AppDelegate.h"

static NSString * const ANDYCellIdentifier = @"ANDYCellIdentifier";

@interface ViewController ()

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) DATASource *dataSource;
@property (nonatomic, weak) DATAStack *dataStack;

@end

@implementation ViewController

- (instancetype)initWithDataStack:(DATAStack *)dataStack {
    self = [super init];
    if (self) {
        _dataStack = dataStack;
    }

    return self;
}

#pragma mark - Lazy Instantiation

- (DATASource *)dataSource {
    if (_dataSource) return _dataSource;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"User"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"createdDate" ascending:YES]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                         cellIdentifier:ANDYCellIdentifier
                                           fetchRequest:fetchRequest
                                            mainContext:self.dataStack.mainContext
                                            sectionName:nil
                                          configuration:^(UITableViewCell * _Nonnull cell, NSManagedObject * _Nonnull item, NSIndexPath * _Nonnull indexPath) {
                                              cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [item valueForKey:@"name"], [item valueForKey:@"createdDate"]];
                                          }];

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ANDYCellIdentifier];
    self.tableView.dataSource = self.dataSource;

    UIBarButtonItem *backgroundButton = [[UIBarButtonItem alloc] initWithTitle:@"Background" style:UIBarButtonItemStyleDone target:self action:@selector(createBackground)];
    self.navigationItem.rightBarButtonItem = backgroundButton;

    UIBarButtonItem *mainButton = [[UIBarButtonItem alloc] initWithTitle:@"Main" style:UIBarButtonItemStyleDone target:self action:@selector(createMain)];
    self.navigationItem.leftBarButtonItem = mainButton;
}

#pragma mark - Actions

- (void)createBackground {
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:backgroundContext];
        NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:backgroundContext];
        [object setValue:@"Background" forKey:@"name"];
        [object setValue:[NSDate date] forKey:@"createdDate"];
        [backgroundContext save:nil];
    }];
}

- (void)createMain {
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:self.dataStack.mainContext];
    NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:self.dataStack.mainContext];
    [object setValue:@"Main" forKey:@"name"];
    [object setValue:[NSDate date] forKey:@"createdDate"];
    [self.dataStack.mainContext save:nil];
}

@end
