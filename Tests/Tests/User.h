//
//  User.h
//  Tests
//
//  Created by Elvis Nuñez on 2/7/15.
//  Copyright (c) 2015 ORGANIZATION. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface User : NSManagedObject

@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * remoteID;

@end
