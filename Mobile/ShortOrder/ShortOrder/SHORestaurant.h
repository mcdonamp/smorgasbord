//
//  SHORestaurant.h
//  ShortOrder
//
//  Created by Michael McDonald on 2/18/14.
//  Copyright (c) 2014 Michael McDonald. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "FirebaseProtocol.h"

@interface SHORestaurant : NSObject <FirebaseProtocol>

@property (strong, nonatomic) NSString *restaurantID;
@property (strong, nonatomic) NSString *postalCode;
@property (strong, nonatomic) NSString *restaurantName;
@property (strong, nonatomic) CLLocation *location;
@property (nonatomic) NSInteger waitTimeMinutes;
@property (nonatomic) NSInteger waitTimeHours;
@property BOOL isFavorite;
@property (strong, nonatomic) NSMutableArray *reviewList;

// add in info on location

- (id)initWithDictionary:(NSDictionary *)dict;
- (id)initWithName:(NSString *)restaurantName isFavorite:(BOOL)favorite;
- (id)initWithName:(NSString *)restaurantName waitInMinutes:(NSInteger)minutes andHours:(NSInteger)hours isFavorite:(BOOL)favorite;

- (NSInteger)predictWaitTimeFromReviewsByAveraging;
- (NSInteger)calculateWasWorthItPercent;
- (NSInteger)calculateWasNotWorthItPercent;

- (void)refreshData;
- (NSDictionary *)toDictionary;

@end
