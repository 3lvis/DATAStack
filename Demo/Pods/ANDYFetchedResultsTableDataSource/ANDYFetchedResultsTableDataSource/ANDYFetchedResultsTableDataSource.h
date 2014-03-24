//
//  ANDYFetchedResultsTableDataSource.h
//  Andy
//
//  Created by Elvis Nunez on 10/29/13.
//  Based on the work of Chris Eidhof.
//  Copyright (c) 2014 Elvis Nuñez. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CoreData;

typedef void (^ANDYConfigureBlock)(id cell, id item);

@interface ANDYFetchedResultsTableDataSource : NSObject <UITableViewDataSource>

/*!
 * Used to configure UITableView's cell.
 */
@property (nonatomic, copy) ANDYConfigureBlock configureCellBlock;

/*!
 * Initialization of ANDYFetchedResultsTableDataSource.
 * \param aTableView The used UITableView.
 * \param aFetchedResultsController The used NSFetchedResultsController.
 * \param aCellIdentifier The used cell identifier.
 * \returns An instance of ANDYFetchedResultsTableDataSource.
 */
- (instancetype)initWithTableView:(UITableView *)aTableView fetchedResultsController:(NSFetchedResultsController *)aFetchedResultsController cellIdentifier:(NSString *)aCellIdentifier;

/*!
 * Convenience method to change the predicate of the NSFetchedResultsController.
 * \param predicate The predicate.
 */
- (void)changePredicate:(NSPredicate *)predicate;

@end