//
//  MainViewController.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "MainViewController.h"
#import "MainTableViewCell.h"
#import "UIScrollView+EmptyDataSet.h"
#import "AppDelegate.h"
#import "SwipeViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <PromiseKit/PromiseKit.h>
#import "Forecastr.h"
#import "UIColor+Hexadecimal.h"
#import "customNavBar.h"
#import "pushAnimator.h"
#import "popAnimator.h"
#import "Reachability.h"
@import JTMaterialSpinner;
#import "newFlows-Swift.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet JTMaterialSpinner *spinnerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *infoButton;

@property (strong, nonatomic) NSString *updateString;

@property (strong, nonatomic) NSMutableArray *selectedStationArray;
@property (strong, nonatomic) NSNumber *stationNumber;
@property (strong, nonatomic) NSString *stationTitle;
@property (strong, nonatomic) NSMutableArray *resultArray;
@property (strong, nonatomic) NSMutableArray *minMaxArray;

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Customize the line width
    self.spinnerView.circleLayer.lineWidth = 2.0;
    
    // Change the color of the line
    self.spinnerView.circleLayer.strokeColor = [UIColor whiteColor].CGColor;
    
    self.navigationController.delegate = self;
    
    self.navigationController.navigationBar.translucent = YES;
    
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [self.tableView addSubview:self.refreshControl];
    
    UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    self.navigationItem.titleView = img;
    
    self.selectedStationArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedStationArray"] mutableCopy];
    self.tableView.tableFooterView = [UIView new];
    
    self.navigationController.navigationBarHidden = YES;
    
    [UIView transitionWithView: self.navigationController.view
                      duration: 0.3
                       options: UIViewAnimationOptionTransitionCrossDissolve
                    animations: ^{
                        
                        [self.navigationController setNavigationBarHidden: NO animated: NO];
                    }
                    completion: nil ];
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:YES];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveLiveUpdateNotification:)
                                                 name:@"LiveUpdateNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveRefreshNotification:)
                                                 name:@"RefreshNotification"
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(receiveRefreshSpinNotification:)
                                                 name:@"RefreshSpinNotification"
                                               object:nil];
}

- (void)pullToRefresh{
    NSDate *lastUSGSupdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUSGSupdateDate"];
    NSTimeInterval secondsSinceUpdateInterval = [lastUSGSupdateDate timeIntervalSinceNow];
    int minutesSinceUpdateInterval = secondsSinceUpdateInterval*-1/60;
    if (minutesSinceUpdateInterval>30) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }
    else {
        [self.refreshControl endRefreshing];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    
    Reachability *reach = [Reachability reachabilityWithHostname:@"www.apple.com"];
    if([reach currentReachabilityStatus] == 0) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"reachable"];
    }
    else {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"reachable"];
    }
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"segueToRivers"]) {
        [self performSegueWithIdentifier:@"addStationSegue" sender:self];
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"selectedStationUpdated"]) {
        if (self.selectedStationArray.count==1) {
            [self.tableView reloadEmptyDataSet];
        }
        [self.spinnerView forceBeginRefreshing];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }
    else if ([[NSUserDefaults standardUserDefaults] boolForKey:@"shouldUpdate"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"reachable"]){
        [self.spinnerView forceBeginRefreshing];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"shouldUpdate"];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] refreshData];
    }
    else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"oneTwoFix"] && [[NSUserDefaults standardUserDefaults] boolForKey:@"reachable"]){
        [self.spinnerView forceBeginRefreshing];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"oneTwoFix"];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }
    else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"reachable"]){
        // offline message here??
        self.resultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"];
        self.minMaxArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxArray"];
        [self.tableView reloadData];
    }
    else {
        if (self.selectedStationArray.count == self.resultArray.count) {
            self.resultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"];
            self.minMaxArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxArray"];
            [self.tableView reloadData];
        }
        else {
            if (self.selectedStationArray.count==1) {
                [self.tableView reloadEmptyDataSet];
            }
            if (self.selectedStationArray.count > 0) {
                [self.spinnerView forceBeginRefreshing];
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
            }
        }
    }
}

- (id<UIViewControllerAnimatedTransitioning>)navigationController:(UINavigationController *)navigationController
                                  animationControllerForOperation:(UINavigationControllerOperation)operation
                                               fromViewController:(UIViewController*)fromVC
                                                 toViewController:(UIViewController*)toVC
{
    if (operation == UINavigationControllerOperationPush)
        return [[pushAnimator alloc] init];
    
    if (operation == UINavigationControllerOperationPop)
        return [[popAnimator alloc] init];
    
    return nil;
}

#pragma mark - TODO refresh

- (void)receiveLiveUpdateNotification:(NSNotification *) notification{
    self.resultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"];
    self.minMaxArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxArray"];
    [self.tableView reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.selectedStationArray.count-1 inSection:0];
    [self.tableView scrollToRowAtIndexPath:indexPath
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:YES];
    [self.refreshControl endRefreshing];
    [self.spinnerView endRefreshing];
}

- (void)receiveRefreshNotification:(NSNotification *) notification{
    self.resultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"];
    self.minMaxArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxArray"];
    [self.refreshControl endRefreshing];
    [self.spinnerView endRefreshing];
    [self.tableView reloadData];
}

- (void)receiveRefreshSpinNotification:(NSNotification *) notification{
    self.resultArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"];
    self.minMaxArray = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxArray"];
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
    [self.spinnerView endRefreshing];
}

- (IBAction)addTapped:(id)sender {
    // for the moment total stations are capped at 10?
    // test for station array count and hasPurchased bool
    NSLog(@"%@", [NSNumber numberWithBool:[[NSUserDefaults standardUserDefaults] boolForKey:@"upgradePurchased"]]);
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"upgradePurchased"]) {
        // in-app upgrade
        if (self.selectedStationArray.count < 10) {
            [self performSegueWithIdentifier:@"addStationSegue" sender:self];
        }
        else {
            // at max stations
        }
    }
    else {
        // free version
        if (self.selectedStationArray.count < 3) {
            [self performSegueWithIdentifier:@"addStationSegue" sender:self];
        }
        else {
            [self performSegueWithIdentifier:@"purchaseSegue" sender:self];
        }
    }
}

- (void)leftButtonPressed:(id)sender{
    [self performSegueWithIdentifier:@"aboutSegue" sender:self];
}

#pragma mark - EmptyDataset

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"Keep a pulse on the rivers you care about";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.firstLineHeadIndent = 20.0;
    paragraphStyle.tailIndent = -20.0;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:26.0f],
                                 NSForegroundColorAttributeName: [UIColor colorWithHex:@"FFFFFF"],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    return [[NSAttributedString alloc] initWithString:text attributes:attributes];
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:17.0f];
    UIColor *textColor = [UIColor colorWithHex:(state == UIControlStateNormal) ? @"ffffff" : @"acacac"];

    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:@"Add a Station" attributes:attributes];
}

- (UIImage *)buttonBackgroundImageForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state{
    return [[[UIImage imageNamed:@"addStation"] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, -self.view.bounds.size.width/4, 0, -self.view.bounds.size.width/4)];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return self.view.bounds.size.height / 8;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -65.0;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    return self.selectedStationArray.count > 0;
}

#pragma mark - UITableviewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 27.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]] && self.selectedStationArray.count != 0) {
        UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;

        ((UITableViewHeaderFooterView *)view).backgroundView.backgroundColor = [UIColor clearColor];
        
        UIView *bottomSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, view.bounds.size.height-0.5f, view.bounds.size.width, 0.5f)];
        [bottomSeperatorView setBackgroundColor:[UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0]];
        
        [view addSubview:bottomSeperatorView];
        
        if (header.textLabel.text.length > 0) {
            if ([[NSUserDefaults standardUserDefaults] boolForKey:@"reachable"]) {
                header.textLabel.text = [NSString stringWithFormat:@"%@%@", [[header.textLabel.text substringToIndex:12] capitalizedString], [[header.textLabel.text substringFromIndex:12] uppercaseString]];
            }
            else {
                header.textLabel.text = [NSString stringWithFormat:@"%@%@", [[header.textLabel.text substringToIndex:21] capitalizedString], [[header.textLabel.text substringFromIndex:21] uppercaseString]];
            }
            
        }
        header.textLabel.textColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0];
        header.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:11.0f];
        header.textLabel.textAlignment = NSTextAlignmentCenter;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (self.selectedStationArray.count > 0) {
        NSString *updateString = [[NSUserDefaults standardUserDefaults] objectForKey:@"updateString"];
        
        if (updateString.length == 0) {
            return @"Last updated at: N/A";
        }
        else if (![[NSUserDefaults standardUserDefaults] boolForKey:@"reachable"]){
            return [NSString stringWithFormat:@"Offline, Last updated: %@", updateString];
        }
        else {
            return [NSString stringWithFormat:@"Last updated: %@", updateString];
        }
    }
    
    return @"";
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.selectedStationArray.count;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.selectedStationArray removeObjectAtIndex:indexPath.row];
        
        [[NSUserDefaults standardUserDefaults] setObject:self.selectedStationArray forKey:@"selectedStationArray"];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"pullNewWeather"];
        
        if (self.selectedStationArray.count == 0) {
            [tableView beginUpdates];
            [tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
            [tableView reloadEmptyDataSet];
            [tableView endUpdates];
        }
    }
}

#pragma mark -

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [self performSegueWithIdentifier:@"addStationSegue" sender:self];
    [_spinnerView beginRefreshing];
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"MainTableViewCellIdentifier" forIndexPath:indexPath];

    NSMutableDictionary *cellDict = self.selectedStationArray[indexPath.row];
    NSMutableDictionary *titleDict = [NSMutableDictionary new];
    
    if (cellDict[@"cleanedTitle"]){
        titleDict = cellDict[@"cleanedTitle"];
    }
    else {
        [titleDict setObject:cellDict[@"stationTitle"] forKey:@"nameHolder"];
    }
    
    if (self.resultArray.count > 0 && self.minMaxArray.count > 0) {
        for (NSDictionary *resultDict in self.resultArray) {
            if ([resultDict[@"siteNumber"] isEqualToString:cellDict[@"stationNumber"]]) {
                if ([resultDict[@"siteValue"] doubleValue] > 0) {
                    cell.resultLabel.text = resultDict[@"siteValue"];
                }
                else {
                    cell.resultLabel.text = @"N/A";
                }
                
                for (NSDictionary *meanDict in self.minMaxArray) {
                    
                    if (meanDict[@"missingData"]) {
                        //code for missing mean min
                        cell.resultLabel.textColor = [UIColor whiteColor];
                        
                        if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                            cell.resultLabel.text = @"N/A";
                        }
                    }
                    else {
                        if ([meanDict[@"siteNumber"] isEqualToString:cellDict[@"stationNumber"]]) {
                            NSLog(@"%f", [meanDict[@"25Value"] doubleValue]);
                            if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                                cell.resultLabel.text = @"N/A";
                                [cell.resultLabel setTextColor:[UIColor whiteColor]];
                            }
                            else {
                                if ([resultDict[@"siteValue"] doubleValue] < [meanDict[@"25Value"] doubleValue] && meanDict[@"25Value"] != [NSNull null]) {
                                    //red
                                    [cell.resultLabel setTextColor:[UIColor colorWithRed:0.93 green:0.39 blue:0.25 alpha:1.0]];
                                }
                                else if ([resultDict[@"siteValue"] doubleValue] > [meanDict[@"75Value"] doubleValue] && meanDict[@"75Value"] != [NSNull null]){
                                    //blue
                                    [cell.resultLabel setTextColor:[UIColor colorWithRed:0.15 green:0.58 blue:1.00 alpha:1.0]];
                                }
                                else{
                                    //green
                                    [cell.resultLabel setTextColor:[UIColor colorWithRed:0.42 green:0.91 blue:0.46 alpha:1.0]];
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    //strip new line /n chars
    
    NSString *titleString = [titleDict[@"nameHolder"] stringByReplacingOccurrencesOfString: @"\r" withString:@""];
    NSString *subTitleString = [titleDict[@"locationHolder"] stringByReplacingOccurrencesOfString: @"\r" withString:@""];
    
    cell.titleLabel.text = titleString;
    cell.subTitleLabel.text = subTitleString;
    cell.subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.subTitleLabel.numberOfLines = 0;
    [cell.subTitleLabel setTextColor:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0]];
    return cell;
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    StationManager.shared.selectedStation = self.selectedStationArray[indexPath.row];
    [self performSegueWithIdentifier:@"StationDetailSegue" sender:self];

//    [self.spinnerView beginRefreshing];
//    if (self.hasTappedRow == NO) {
//        self.hasTappedRow = YES;
//
//        [[NSUserDefaults standardUserDefaults] setInteger:indexPath.row forKey:@"selectedIndex"];
//        
//        BOOL pullNewWeather = [[NSUserDefaults standardUserDefaults] boolForKey:@"pullNewWeather"];
//        
//        NSDate *lastWeatherPullDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"updatedWeatherDate"];
//        
//        self.selectedStationArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedStationArray"] mutableCopy];
//        
//        if (lastWeatherPullDate == nil) {
//            [self pullFromDarkWeather:self.selectedStationArray];
//        }
//        else {
//            NSDate *todaysDate = [NSDate date];
//            NSCalendar *gregorian = [NSCalendar currentCalendar];
//            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
//            [dateComponents setHour:3];
//            NSDate *targetDate = [gregorian dateByAddingComponents:dateComponents toDate:lastWeatherPullDate options:0];
//            if ([targetDate compare:todaysDate] == NSOrderedAscending || pullNewWeather) {
//                [self pullFromDarkWeather:self.selectedStationArray];
//            }
//            else {
//                [self.spinnerView endRefreshing];
//                self.hasTappedRow = NO;
//            }
//        }
//    }
}

//- (void)pullFromDarkWeather:(NSMutableArray*)incomingDataArray{
//    
//    NSMutableArray *weatherDataArray = [NSMutableArray new];
//    
//    dispatch_group_t group = dispatch_group_create();
//    
//    for (NSMutableDictionary *stationDict in incomingDataArray) {
//        dispatch_group_enter(group);
//        
//        NSArray *tmpExclusions = @[kFCAlerts, kFCFlags, kFCMinutelyForecast, kFCHourlyForecast];
//        
//        [[Forecastr sharedManager] getForecastForLatitude:[stationDict[@"latTotal"] doubleValue] longitude:[stationDict[@"longTotal"] doubleValue] time:nil exclusions:tmpExclusions extend:nil success:^(id JSON) {
//            NSDictionary *testRespDict = [NSDictionary dictionaryWithDictionary:JSON];
//            
//            NSDictionary *dailyDict = testRespDict[@"daily"];
//            
//            NSNumber *offsetNumber = testRespDict[@"offset"];
//            
//            NSArray *dailyArray = dailyDict[@"data"];
//            
//            NSMutableArray *intermediateArray = [NSMutableArray new];
//            
//            for (int i = 0; i < 4; i++){
//                NSDictionary *innerDict = dailyArray[i];
//                NSNumber *secondsPerHour = @(3600);
//                int offsetInSeconds = [offsetNumber intValue] * [secondsPerHour intValue];
//                NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
//                
//                int finalSeconds = [innerDict[@"time"] intValue] + offsetInSeconds;
//                NSDate *preOffsetDate = [NSDate dateWithTimeIntervalSince1970:[innerDict[@"time"] intValue]];
//                NSDate *date = [NSDate dateWithTimeIntervalSince1970:finalSeconds];
//                
//                formatter.locale = [NSLocale currentLocale];
//                [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
//                
//                NSDateFormatter *df = [[NSDateFormatter alloc] init];
//                df.locale = [NSLocale currentLocale];
//                [df setDateFormat:@"EEEE"];
//                
//                NSString *dateString = [df stringFromDate:preOffsetDate];
//                
//                NSLog(@"intial %@", [formatter stringFromDate:preOffsetDate]);
//                NSLog(@"intial %@", [df stringFromDate:preOffsetDate]);
//                NSLog(@"%@", [formatter stringFromDate:date]);
//                NSLog(@"%@", [df stringFromDate:date]);
//                
//                NSNumber *lowNum = innerDict[@"temperatureMin"];
//                NSNumber *highNum = innerDict[@"temperatureMax"];
//                
//                NSString *iconString = innerDict[@"icon"];
//                
//                NSDictionary *weatherDict = [[NSDictionary alloc] initWithObjectsAndKeys:lowNum, @"lowNum", highNum, @"highNum", dateString, @"dateString", iconString, @"iconString", stationDict[@"stationNumber"], @"stationNumber", nil];
//                
//                [intermediateArray addObject:weatherDict];
//            }
//            
//            [weatherDataArray addObject:intermediateArray];
//            dispatch_group_leave(group);
//            NSLog(@"test");
//        } failure:^(NSError *error, id response) {
//            NSLog(@"Error while retrieving forecast.\n\n%@\n\n%@", error, response);
//        }];
//        
//    }
//    
//    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
//        // All Requests have finished
//        [[NSUserDefaults standardUserDefaults] setObject:weatherDataArray forKey:@"weatherArray"];
//#pragma mark - TODO refresh
//        [self.spinnerView endRefreshing];
//
//        [self performSegueWithIdentifier:@"StationDetailSegue" sender:self];
//    });
//}

- (IBAction)unwindToHome:(UIStoryboardSegue *)unwindSegue
{
    
}

@end
