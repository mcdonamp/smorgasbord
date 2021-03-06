//
//  SHORestaurantViewController.m
//  ShortOrder
//
//  Created by Michael McDonald on 2/3/14.
//  Copyright (c) 2014 Michael McDonald. All rights reserved.
//

#import "SHORestaurantViewController.h"
#import "SHOReviewCell.h"
#import "SHOReview.h"
#import "SHOReviewPickerModalViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>

#define SHORT_WAIT_TIME 5
#define MEDIUM_WAIT_TIME 10
#define LONG_WAIT_TIME 20

@interface SHORestaurantViewController ()

@end

@implementation SHORestaurantViewController

static NSString *ReviewCellIdentifier = @"ReviewCellIdentifier";

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.reviews = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.restaurant.restaurantName;
    
    if ([self.restaurant isFavorite]) {
        self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMaps)],[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FilledStar"] style:UIBarButtonItemStylePlain target:self action:@selector(markAsNotFavorite)]];
    } else {
        self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMaps)],[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledStar"] style:UIBarButtonItemStylePlain target:self action:@selector(markAsFavorite)]];
    }
    
    self.tableView.tableHeaderView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Separator.png"]];
    
    [self.tableView registerNib:[UINib nibWithNibName:@"SHOReviewCell" bundle:nil] forCellReuseIdentifier:ReviewCellIdentifier];
    
    NSString *reviewURL = [NSString stringWithFormat:@"https://shortorder.firebaseio.com/restaurants/%@/%@/reviewList",self.restaurant.postalCode, self.restaurant.restaurantID];
    Firebase *reviewBase = [[Firebase alloc] initWithUrl:reviewURL];
    
    [reviewBase observeEventType:FEventTypeChildAdded withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *msgData = snapshot.value;
        SHOReview *addedReview = [[SHOReview alloc] initWithDictionary:msgData];
        [self.reviews addObject:addedReview];
        addedReview.reviewID = snapshot.name;
        NSSortDescriptor *sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timestamp" ascending:NO];
        self.reviews = [[self.reviews sortedArrayUsingDescriptors:@[sortDescriptor]] mutableCopy];
        self.restaurant.reviewList = self.reviews;
        [self refreshData];
    }];
    
    /*
    [reviewBase observeEventType:FEventTypeChildChanged withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *msgData = snapshot.value;
        SHOReview *reviewToRemove = [[SHOReview alloc] initWithDictionary:msgData];
        reviewToRemove.reviewID = snapshot.name;
        [self.reviews removeObject:reviewToRemove];
        [self.restaurant.reviewList removeObject:reviewToRemove];
        [self refreshData];
    }];
     */
    
    [reviewBase observeEventType:FEventTypeChildRemoved withBlock:^(FDataSnapshot *snapshot) {
        NSDictionary *msgData = snapshot.value;
        SHOReview *reviewToRemove = [[SHOReview alloc] initWithDictionary:msgData];
        reviewToRemove.reviewID = snapshot.name;
        [self.reviews removeObject:reviewToRemove];
        [self.restaurant.reviewList removeObject:reviewToRemove];
        [self refreshData];
    }];
    
    [self refreshData];
}

- (void)markAsFavorite;
{
    
    
    Firebase *baseRef = [[Firebase alloc] initWithUrl:@"shortorder.firebaseio.com"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:baseRef];
    [authClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        if (error != nil) {
            // Oh no! There was an error performing the check
        } else if (user == nil) {
            // No user is logged in, pop up an alert
        } else {
            self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMaps)],[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"FilledStar"] style:UIBarButtonItemStylePlain target:self action:@selector(markAsNotFavorite)]];
            
            NSString *refURL = [NSString stringWithFormat:@"shortorder.firebaseio.com/users/%@", user.userId];
            Firebase *ref = [[Firebase alloc] initWithUrl:refURL];
        }
    }];
    
    
    
    
//    NSString *refURL = [NSString stringWithFormat:@"https://shortorder.firebaseio.com/restaurants/%@/%@/isFavorite/",self.restaurant.postalCode,self.restaurant.restaurantID];
//    Firebase *ref = [[Firebase alloc] initWithUrl:refURL];
//    [ref setValue:[NSNumber numberWithBool:YES]];
}

- (void)markAsNotFavorite;
{
    self.navigationItem.rightBarButtonItems = @[[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledArrow"] style:UIBarButtonItemStylePlain target:self action:@selector(goToMaps)],[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"UnfilledStar"] style:UIBarButtonItemStylePlain target:self action:@selector(markAsFavorite)]];
    
    
    
    NSString *refURL = [NSString stringWithFormat:@"https://shortorder.firebaseio.com/restaurants/%@/%@/isFavorite/",self.restaurant.postalCode,self.restaurant.restaurantID];
    Firebase *ref = [[Firebase alloc] initWithUrl:refURL];
    [ref setValue:[NSNumber numberWithBool:NO]];
}

- (void)goToMaps;
{
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:self.restaurant.location completionHandler:^(NSArray *placemarks, NSError *error) {
        CLPlacemark *placemark = [placemarks lastObject];
        MKPlacemark *mapPlacemark = [[MKPlacemark alloc] initWithPlacemark:placemark];
        MKMapItem *endingItem = [[MKMapItem alloc] initWithPlacemark:mapPlacemark];
        
        NSMutableDictionary *launchOptions = [[NSMutableDictionary alloc] init];
        [launchOptions setObject:MKLaunchOptionsDirectionsModeDriving forKey:MKLaunchOptionsDirectionsModeKey];
        
        [endingItem openInMapsWithLaunchOptions:launchOptions];
    }];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return [self.reviews count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SHOReviewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:ReviewCellIdentifier];
    
    cell.review = [self.reviews objectAtIndex:indexPath.row];
    
    return cell;
}

//TODO: Refactor to pull colors out to a plist (or at the very least a header file)
- (void)setWaitTimeInMinutes:(NSInteger)waitTimeMinutes Hours:(NSInteger)waitTimeHours;
{
    if (waitTimeHours > 0) {
        self.waitTimeLabel.text = [NSString stringWithFormat:@"%d+ hr", waitTimeHours];
        self.waitTimeLabel.textColor = [UIColor colorWithRed:0.8353 green:0.1294 blue:0.0863 alpha:1.0];
    } else {
        self.waitTimeLabel.text = [NSString stringWithFormat:@"%d min", waitTimeMinutes];
        if (waitTimeMinutes <= SHORT_WAIT_TIME) {
            self.waitTimeLabel.textColor = [UIColor colorWithRed:0.0902 green:0.6431 blue:0.1020 alpha:1.0];
        } else if (waitTimeMinutes <= MEDIUM_WAIT_TIME) {
            self.waitTimeLabel.textColor = [UIColor colorWithRed:0.9922 green:0.7020 blue:0.1686 alpha:1.0];
        } else if (waitTimeMinutes <= LONG_WAIT_TIME) {
            self.waitTimeLabel.textColor = [UIColor colorWithRed:0.9882 green:0.3882 blue:0.1255 alpha:1.0];
        } else if (waitTimeMinutes > LONG_WAIT_TIME) {
            self.waitTimeLabel.textColor = [UIColor colorWithRed:0.8353 green:0.1294 blue:0.0863 alpha:1.0];
        }
    }
}

- (IBAction)worthItButtonPressed:(id)sender {
    [self launchReviewViewWasWorthIt:YES];
}

- (IBAction)noThanksButtonPressed:(id)sender {
    [self launchReviewViewWasWorthIt:NO];
}

- (void) launchReviewViewWasWorthIt:(BOOL)worthIt;
{
    // The much better modal view solution: looks and feels native
    SHOReviewPickerModalViewController *pickerController = [[SHOReviewPickerModalViewController alloc] init];
    pickerController.wasWorthIt = worthIt;
    pickerController.restaurant = self.restaurant;
    pickerController.modalPresentationStyle = UIModalPresentationFullScreen;
    pickerController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:pickerController animated:YES completion:nil];
    
    /*
    // If you really want to run this code with my super shitty totally not native UI components (thanks OmniGraffle, no thanks CS degree)
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    UIView *coverView = [[UIView alloc] initWithFrame:screenRect];
    coverView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.0];
    [self.view addSubview:coverView];
    
    [UIView animateWithDuration:0.2 animations:^{
        UIView *latestView = [[self.view subviews] lastObject];
        latestView.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:0.3];
    }];
    
    
    UIView *reviewView = [[[NSBundle mainBundle] loadNibNamed:@"RestaurantReviewPickerView" owner:self options:nil] lastObject];
    reviewView.frame = CGRectMake(self.view.frame.size.width/2.0 - reviewView.frame.size.width/2.0, self.view.frame.size.height/2.0 - reviewView.frame.size.height/2.0, reviewView.frame.size.width, reviewView.frame.size.height);
    reviewView.alpha = 0;
    [self.view addSubview:reviewView];
    
    [UIView animateWithDuration:0.2 animations:^{
        UIView *latestView = [[self.view subviews] lastObject];
        latestView.alpha = 1.0;
    }];
     */
}

- (void) refreshData;
{
    NSString *minutesURL = [NSString stringWithFormat:@"https://shortorder.firebaseio.com/restaurants/%@/%@/waitTimeMinutes",self.restaurant.postalCode,self.restaurant.restaurantID];
    Firebase *firebase = [[Firebase alloc] initWithUrl:minutesURL];
    
    [self.restaurant refreshData];
    
    [self setWaitTimeInMinutes:self.restaurant.waitTimeMinutes Hours:self.restaurant.waitTimeHours];
    
    [firebase setValue:[NSNumber numberWithInteger:self.restaurant.waitTimeMinutes]];
    
    self.worthItLabel.text = [NSString stringWithFormat:@"%d%%",[self.restaurant calculateWasWorthItPercent]];
    
    self.noThanksLabel.text = [NSString stringWithFormat:@"%d%%",[self.restaurant calculateWasNotWorthItPercent]];
    
    [self.tableView reloadData];
}


@end
