#import "ANDYMainTableViewController.h"
@import DATASource;
#import "Demo-Swift.h"
#import "Task.h"
#import "ANDYAppDelegate.h"

static NSString * const ANDYCellIdentifier = @"ANDYCellIdentifier";

@interface ANDYMainTableViewController ()

@property (nonatomic) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic) DATASource *dataSource;
@property (nonatomic) DATAStack *dataStack;

@end

@implementation ANDYMainTableViewController

- (instancetype)initWithDataStack:(DATAStack *)dataStack
{
    self = [super init];
    if (!self) return nil;

    _dataStack = dataStack;

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
                                              Task *task = (Task *)item;
                                              cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", task.title, task.date];
                                          }];

    return _dataSource;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self.tableView registerClass:[UITableViewCell class]
           forCellReuseIdentifier:ANDYCellIdentifier];
    self.tableView.dataSource = self.dataSource;

    UIBarButtonItem *addTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(createTask)];
    self.navigationItem.rightBarButtonItem = addTaskButton;

    UIBarButtonItem *alternativeAddTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                              target:self
                                                                                              action:@selector(createAlternativeTask)];
    self.navigationItem.leftBarButtonItem = alternativeAddTaskButton;
}

#pragma mark - Actions

- (void)createTask
{
    [self.dataStack performInNewBackgroundContext:^(NSManagedObjectContext *backgroundContext) {
        Task *task = [Task insertInManagedObjectContext:backgroundContext];
        task.title = @"Hello BACKGROUND!";
        task.date = [NSDate date];
        [backgroundContext save:nil];
    }];
}

- (void)createAlternativeTask
{
    NSManagedObjectContext *context = [self.dataStack mainContext];
    Task *task = [Task insertInManagedObjectContext:context];
    task.title = @"Hello MAIN THREAD!";
    task.date = [NSDate date];
    [context save:nil];
}

@end
