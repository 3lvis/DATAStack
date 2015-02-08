#import "ANDYMainTableViewController.h"
#import "ANDYFetchedResultsTableDataSource.h"
#import "DATAStack.h"
#import "Task.h"
#import "ANDYAppDelegate.h"

static NSString * const ANDYCellIdentifier = @"ANDYCellIdentifier";

@interface ANDYMainTableViewController ()

@property (nonatomic, strong) NSFetchedResultsController *fetchedResultsController;
@property (nonatomic, strong) ANDYFetchedResultsTableDataSource *dataSource;

@end

@implementation ANDYMainTableViewController

#pragma mark - Lazy Instantiation

- (NSFetchedResultsController *)fetchedResultsController
{
    if (_fetchedResultsController) return _fetchedResultsController;

    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:[appDelegate.dataStack mainThreadContext]
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];

    return _fetchedResultsController;
}

- (ANDYFetchedResultsTableDataSource *)dataSource
{
    if (_dataSource) return _dataSource;

    _dataSource = [[ANDYFetchedResultsTableDataSource alloc] initWithTableView:self.tableView
                                                      fetchedResultsController:self.fetchedResultsController
                                                                cellIdentifier:ANDYCellIdentifier];
    _dataSource.configureCellBlock = ^(UITableViewCell *cell, Task *task) {
        cell.textLabel.text = [NSString stringWithFormat:@"%@ - %@", task.title, task.date];
    };

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
    [appDelegate.dataStack performInNewBackgroundThreadContext:^(NSManagedObjectContext *context) {
        Task *task = [Task insertInManagedObjectContext:context];
        task.title = @"Hello BACKGROUND!";
        task.date = [NSDate date];
        [context save:nil];
    }];
}

- (void)createAlternativeTask
{
    NSManagedObjectContext *context = [appDelegate.dataStack mainThreadContext];
    Task *task = [Task insertInManagedObjectContext:context];
    task.title = @"Hello MAIN THREAD!";
    task.date = [NSDate date];
    [context save:nil];
}

@end
