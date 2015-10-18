#import "Controller.h"
@import DATASource;
#import "Demo-Swift.h"
#import "ANDYAppDelegate.h"

static NSString * const ANDYCellIdentifier = @"ANDYCellIdentifier";

@interface Controller ()

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) DATASource *dataSource;
@property (nonatomic) DATAStack *dataStack;

@end

@implementation Controller

- (instancetype)initWithDataStack:(DATAStack *)dataStack
{
    self = [super init];
    if (self) {
        _dataStack = dataStack;
    }

    return self;
}

#pragma mark - Lazy Instantiation

- (DATASource *)dataSource
{
    if (_dataSource) return _dataSource;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];

    _dataSource = [[DATASource alloc] initWithTableView:self.tableView
                                         cellIdentifier:ANDYCellIdentifier
                                           fetchRequest:fetchRequest
                                            mainContext:self.dataStack.mainContext
                                            sectionName:nil
                                          configuration:^(UITableViewCell * _Nonnull cell, NSManagedObject * _Nonnull item, NSIndexPath * _Nonnull indexPath) {
                                              cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", [item valueForKey:@"title"], [item valueForKey:@"date"]];
                                          }];

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:ANDYCellIdentifier];
    self.tableView.dataSource = self.dataSource;

    UIBarButtonItem *backgroundButton = [[UIBarButtonItem alloc] initWithTitle:@"Background" style:UIBarButtonItemStyleDone target:self action:@selector(createBackground)];
    self.navigationItem.rightBarButtonItem = backgroundButton;

    UIBarButtonItem *mainButton = [[UIBarButtonItem alloc] initWithTitle:@"Main" style:UIBarButtonItemStyleDone target:self action:@selector(createMain)];
    self.navigationItem.leftBarButtonItem = mainButton;
}

#pragma mark - Actions

- (void)createBackground
{
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:backgroundContext];
        NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:backgroundContext];
        [object setValue:@"Background" forKey:@"title"];
        [object setValue:[NSDate date] forKey:@"date"];
        [backgroundContext save:nil];
    }];
}

- (void)createMain
{
    NSManagedObjectContext *context = [self.dataStack mainContext];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Task" inManagedObjectContext:context];
    NSManagedObject *object = [[NSManagedObject alloc] initWithEntity:entity insertIntoManagedObjectContext:context];
    [object setValue:@"Main" forKey:@"title"];
    [object setValue:[NSDate date] forKey:@"date"];
    [context save:nil];
}

@end
