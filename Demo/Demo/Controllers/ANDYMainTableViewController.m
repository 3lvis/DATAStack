#import "ANDYMainTableViewController.h"
#import "ANDYFetchedResultsTableDataSource.h"
#import "ANDYDataManager.h"
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
    if (_fetchedResultsController) {
        return _fetchedResultsController;
    }

    ANDYAppDelegate *appDelegate = SharedAppDelegate;
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"Task"];
    fetchRequest.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"date" ascending:YES]];
    _fetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                    managedObjectContext:[appDelegate.dataManager mainThreadContext]
                                                                      sectionNameKeyPath:nil
                                                                               cacheName:nil];

    return _fetchedResultsController;
}

- (ANDYFetchedResultsTableDataSource *)dataSource
{
    if (_dataSource) {
        return _dataSource;
    }

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
    ANDYAppDelegate *appDelegate = SharedAppDelegate;
    [appDelegate.dataManager performInBackgroundContext:^(NSManagedObjectContext *context) {
        Task *task = [Task insertInManagedObjectContext:context];
        task.title = @"Hello!";
        task.date = [NSDate date];
        [context save:nil];
    }];
}

- (void)createAlternativeTask
{
    ANDYAppDelegate *appDelegate = SharedAppDelegate;
    NSManagedObjectContext *context = [appDelegate.dataManager mainThreadContext];
    Task *task = [Task insertInManagedObjectContext:context];
    task.title = @"Hello MAIN!";
    task.date = [NSDate date];
    [context save:nil];
}

@end
