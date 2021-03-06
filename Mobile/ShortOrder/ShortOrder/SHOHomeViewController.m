//
//  SHOHomeViewController.m
//  ShortOrder
//
//  Created by Michael McDonald on 2/3/14.
//  Copyright (c) 2014 Michael McDonald. All rights reserved.
//

#import "SHOHomeViewController.h"
#import "SHORestaurantTableViewController.h"
#import "SHORestaurantTableViewControllerWithTabs.h"
#import "SHOLoginViewController.h"
#import <Firebase/Firebase.h>
#import <FirebaseSimpleLogin/FirebaseSimpleLogin.h>

@interface SHOHomeViewController ()

@end

@implementation SHOHomeViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [self.navigationController setToolbarHidden:YES];
    
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    self.locationManager.desiredAccuracy = kCLLocationAccuracyNearestTenMeters;
    
    [self.locationManager startUpdatingLocation];
    
    // Do any additional setup after loading the view from its nib.
}

- (void)viewWillAppear:(BOOL)animated;
{
    [[self navigationController] setNavigationBarHidden:YES animated:YES];
    self.title = @"Home";
    self.searchTextField.text = @"";
    self.searchTextField.placeholder = @"City or Zip Code";
    
    Firebase *authRef = [[Firebase alloc] initWithUrl:@"https://shortorder.firebaseio.com"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:authRef];
    
    [authClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        if (error != nil) {
            // Uh oh...
        } else if (user == nil) {
            self.signInButton.titleLabel.text = @"Sign In";
        } else {
            self.signInButton.titleLabel.text = @"Sign Out";
        }
    }];

    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)viewWillDisappear:(BOOL)animated;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)signInButtonPressed:(id)sender;
{
    Firebase *authRef = [[Firebase alloc] initWithUrl:@"https://shortorder.firebaseio.com"];
    FirebaseSimpleLogin *authClient = [[FirebaseSimpleLogin alloc] initWithRef:authRef];
    
    [authClient checkAuthStatusWithBlock:^(NSError *error, FAUser *user) {
        if (error != nil) {
            // Uh oh...
        } else if (user == nil) {
            SHOLoginViewController *loginController = [[SHOLoginViewController alloc] init];
            loginController.modalPresentationStyle = UIModalPresentationFullScreen;
            loginController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
            [self presentViewController:loginController animated:YES completion:nil];
        } else {
            [authClient logout];
            NSLog(@"User %@ logged out",user);
            self.signInButton.titleLabel.text = @"Sign In";
        }
    }];
}

- (IBAction)searchFieldPressedEnter:(id)sender;
{
//    [sender resignFirstResponder];
    [self searchGoButtonPressed:self];
}

- (IBAction)backgroundTap:(id)sender;
{
    [self.searchTextField resignFirstResponder];
}

- (IBAction)searchGoButtonPressed:(id)sender {
    // Get user input to find out where we should be searching
    NSString *textBoxInput = self.searchTextField.text;
    [self switchToRestaurantListNearLocation:textBoxInput];
}

- (IBAction)nearButtonPressed:(id)sender {
    // Use gelocation to find out the area code near me
    CLGeocoder *geocoder = [[CLGeocoder alloc] init];
    [geocoder reverseGeocodeLocation:self.currentLocation completionHandler:^(NSArray *placemarks, NSError *error) {
        if (error == nil && [placemarks count] > 0) {
            CLPlacemark *currentPlace = [placemarks lastObject];
            [self switchToRestaurantListNearLocation:[NSString stringWithFormat:@"%@",currentPlace.postalCode]];
        }
    }];
}

- (void)switchToRestaurantListNearLocation:(NSString *)location;
{
    // Hide the keyboard if it's present
    [self.searchTextField resignFirstResponder];
    
    SHORestaurantTableViewControllerWithTabs *restaurantTableViewController = [[SHORestaurantTableViewControllerWithTabs alloc] initWithNibName:@"SHORestaurantTableViewControllerWithTabs" bundle:[NSBundle mainBundle]];
    
    if ([location isEqualToString:@""]) {
        // Must input valid things! Check here for validity...
    } else {
        restaurantTableViewController.locationString = location;
        [self.navigationController pushViewController:restaurantTableViewController animated:YES];
    }
}

// TODO eliminate the magic numbers here (especially for iPhone 4's vs 5's
// Use the notification dicationary
# pragma mark - Keyboard will show/hide notifications to scroll the view properly
- (void)keyboardWillShow:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setFrame:CGRectMake(0,-120,320,460)];
    }];
}

-(void)keyboardWillHide:(NSNotification *)notification
{
    [UIView animateWithDuration:0.3f animations:^{
        [self.view setFrame:CGRectMake(0,0,320,460)];
    }];
}

#pragma mark - CLLocationManager Delegate Methods
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations;
{
    self.currentLocation = [locations lastObject];
    NSLog(@"Lat: %.8f, Lon: %.8f",self.currentLocation.coordinate.latitude, self.currentLocation.coordinate.longitude);
    [self.locationManager stopUpdatingLocation];
    
}

- (void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error;
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Location Failure" message:@"Location failed to find" delegate:Nil cancelButtonTitle:@"OK" otherButtonTitles: nil];
    
    [alertView show];
}

@end
