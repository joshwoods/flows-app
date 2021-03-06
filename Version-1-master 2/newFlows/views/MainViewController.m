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
#import <JTMaterialSpinner/JTMaterialSpinner.h>
#import <PromiseKit/PromiseKit.h>
#import "Forecastr.h"
#import "UIColor+Hexadecimal.h"
#import "customNavBar.h"
#import "pushAnimator.h"
#import "popAnimator.h"
#import "Reachability.h"

#define kBgQueue dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) //1

@interface MainViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTable;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (weak, nonatomic) IBOutlet JTMaterialSpinner *spinnerView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *addButton;

@property (strong, nonatomic) NSString *updateString;

@end

@implementation MainViewController{
    
    NSMutableArray *selectedStationArray;
    
    NSUserDefaults *defaults;
    NSNumber *stationNumber;
    NSString *stationTitle;
    NSMutableArray *resultArray;
    NSMutableArray *minMaxArray;
    
    //NSString *detailData;
    
    UITableViewHeaderFooterView *header;
    UILabel *headerLabel;
    BOOL hasTappedRow;
    
    UIBarButtonItem *rightItem;
    Forecastr *forecastr;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    forecastr = [Forecastr sharedManager];
    forecastr.apiKey = @"5decbd5c3ac3d3dc35a9ae7666dcfa65";
    
    // Customize the line width
    _spinnerView.circleLayer.lineWidth = 2.0;
    
    // Change the color of the line
    _spinnerView.circleLayer.strokeColor = [UIColor whiteColor].CGColor;
    
    self.navigationController.delegate = self;
#pragma mark - TODO refresh control
    
    [self.mainTable setSeparatorColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(pullToRefresh) forControlEvents:UIControlEventValueChanged];
    [_mainTable addSubview:_refreshControl];
    
    UIBarButtonItem *leftItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"infoicon"]
                                                                 style:UIBarButtonItemStylePlain
                                                                target:self action:@selector(leftButtonPressed:)];
    [leftItem setTintColor:[UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0]];
    
    rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddIcon"]
                                                 style:UIBarButtonItemStylePlain
                                                target:self action:@selector(addClicked:)];
    [rightItem setTintColor:[UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0]];
    
    self.navigationItem.rightBarButtonItem = rightItem;
    self.navigationItem.leftBarButtonItem = leftItem;
    
    UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    self.navigationItem.titleView = img;
    
    defaults = [NSUserDefaults standardUserDefaults];
    
    _mainTable.allowsMultipleSelectionDuringEditing = NO;
    selectedStationArray = [[defaults objectForKey:@"selectedStationArray"] mutableCopy];
    
    // A little trick for removing the cell separators
    _mainTable.tableFooterView = [UIView new];
    
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
    NSDate *lastUSGSupdateDate = [defaults objectForKey:@"lastUSGSupdateDate"];
    //NSDate *currentDate = [NSDate date];
    NSTimeInterval secondsSinceUpdateInterval = [lastUSGSupdateDate timeIntervalSinceNow];
    int minutesSinceUpdateInterval = secondsSinceUpdateInterval*-1/60;
    if (minutesSinceUpdateInterval>30) {
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }else{
        [_refreshControl endRefreshing];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    selectedStationArray = [[defaults objectForKey:@"selectedStationArray"] mutableCopy];
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.apple.com"];
    
    NetworkStatus internetStatus = [reach currentReachabilityStatus];
    
    if(internetStatus==0){
        //@"NoAccess";
        [defaults setBool:NO forKey:@"reachable"];
    }else{
        [defaults setBool:YES forKey:@"reachable"];
    }
    
    if ([defaults boolForKey:@"segueToRivers"]) {
        [self performSegueWithIdentifier:@"addStationSegue" sender:self];
    }else if ([defaults boolForKey:@"selectedStationUpdated"]) {
        if (selectedStationArray.count==1) {
            [_mainTable reloadEmptyDataSet];
        }
        [_spinnerView forceBeginRefreshing];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }else if ([defaults boolForKey:@"shouldUpdate"] && [defaults boolForKey:@"reachable"]){
        [_spinnerView forceBeginRefreshing];
        [defaults setObject:[NSNumber numberWithBool:NO] forKey:@"shouldUpdate"];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] refreshData];
    }else if (![defaults boolForKey:@"oneTwoFix"] && [defaults boolForKey:@"reachable"]){
        [_spinnerView forceBeginRefreshing];
        [defaults setBool:YES forKey:@"oneTwoFix"];
        [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
    }else if (![defaults boolForKey:@"reachable"]){
        //offline message here??
        resultArray = [defaults objectForKey:@"resultArray"];
        minMaxArray = [defaults objectForKey:@"minMaxArray"];
        [_mainTable reloadData];
    }else{
        if (selectedStationArray.count == resultArray.count) {
            resultArray = [defaults objectForKey:@"resultArray"];
            minMaxArray = [defaults objectForKey:@"minMaxArray"];
            [_mainTable reloadData];
        }else{
            if (selectedStationArray.count==1) {
                [_mainTable reloadEmptyDataSet];
            }
            if (selectedStationArray.count > 0) {
                [_spinnerView forceBeginRefreshing];
                [(AppDelegate *)[[UIApplication sharedApplication] delegate] runLiveUpdate];
            }
        }
    }
    
    if (selectedStationArray.count == 10) {
        self.navigationItem.rightBarButtonItem = nil;
        rightItem = nil;
        rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddIconEmpty"]
                                                     style:UIBarButtonItemStylePlain
                                                    target:self action:@selector(addNoneClicked:)];
        [self.navigationItem.rightBarButtonItem setEnabled:NO];
        [self.navigationController.navigationBar setNeedsLayout];
    }else if (selectedStationArray.count < 10){
        rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddIcon"]
                                                     style:UIBarButtonItemStylePlain
                                                    target:self action:@selector(addClicked:)];
        [self.navigationItem.rightBarButtonItem setEnabled:YES];
        [self.navigationController.navigationBar setNeedsLayout];
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

- (void)receiveLiveUpdateNotification:(NSNotification *) notification{
    resultArray = [defaults objectForKey:@"resultArray"];
    minMaxArray = [defaults objectForKey:@"minMaxArray"];
    [_mainTable reloadData];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:selectedStationArray.count-1 inSection:0];
    [_mainTable scrollToRowAtIndexPath:indexPath
                      atScrollPosition:UITableViewScrollPositionBottom
                              animated:YES];
#pragma mark - TODO refresh
    [_refreshControl endRefreshing];
    [_spinnerView endRefreshing];
}

- (void)receiveRefreshNotification:(NSNotification *) notification{
    resultArray = [defaults objectForKey:@"resultArray"];
    minMaxArray = [defaults objectForKey:@"minMaxArray"];
    [_refreshControl endRefreshing];
    [_spinnerView endRefreshing];
    [_mainTable reloadData];
    
}

- (void)receiveRefreshSpinNotification:(NSNotification *) notification{
    resultArray = [defaults objectForKey:@"resultArray"];
    minMaxArray = [defaults objectForKey:@"minMaxArray"];
    [_mainTable reloadData];
#pragma mark - TODO refresh
    [_refreshControl endRefreshing];
    [_spinnerView endRefreshing];
}

- (IBAction)addNoneClicked:(id)sender {
    //should never hit? nil method
}

- (IBAction)addClicked:(id)sender {
    // for the moment total stations are capped at 10?
    // test for station array count and hasPurchased bool
    NSLog(@"%@", [NSNumber numberWithBool:[defaults boolForKey:@"upgradePurchased"]]);
    
    if ([defaults boolForKey:@"upgradePurchased"]) {
        // in-app upgrade
        if (selectedStationArray.count < 10) {
            [self performSegueWithIdentifier:@"addStationSegue" sender:self];
        }else{
            // at max stations
        }
    }else{
        // free version
        if (selectedStationArray.count < 3) {
            [self performSegueWithIdentifier:@"addStationSegue" sender:self];
        }else{
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
    NSString *imageName = @"addStation.png";
    return [[[UIImage imageNamed:imageName] resizableImageWithCapInsets:UIEdgeInsetsMake(0, 0, 0, 0) resizingMode:UIImageResizingModeStretch] imageWithAlignmentRectInsets:UIEdgeInsetsMake(0, -self.view.bounds.size.width/4, 0, -self.view.bounds.size.width/4)];
}

- (CGFloat)spaceHeightForEmptyDataSet:(UIScrollView *)scrollView
{
    return self.view.bounds.size.height/8;
}

- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView
{
    return -65.0;
}

#pragma mark - DZNEmptyDataSetDelegate Methods

- (BOOL)emptyDataSetShouldDisplay:(UIScrollView *)scrollView
{
    if (selectedStationArray.count>0) {
        return NO;
    }else{
        return YES;
    }
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

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    header = (UITableViewHeaderFooterView *)view;
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]] && selectedStationArray.count != 0) {
        ((UITableViewHeaderFooterView *)view).backgroundView.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
        
        UIView *bottomSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, view.bounds.size.height-0.5f, view.bounds.size.width, 0.5f)];
        [bottomSeperatorView setBackgroundColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
        
        [view addSubview:bottomSeperatorView];
        
        if (header.textLabel.text.length > 0) {
            if ([defaults boolForKey:@"reachable"]) {
                header.textLabel.text = [NSString stringWithFormat:@"%@%@", [[header.textLabel.text substringToIndex:12] capitalizedString], [[header.textLabel.text substringFromIndex:12] uppercaseString]];
            }else{
                header.textLabel.text = [NSString stringWithFormat:@"%@%@", [[header.textLabel.text substringToIndex:21] capitalizedString], [[header.textLabel.text substringFromIndex:21] uppercaseString]];
            }
            
        }
        header.textLabel.textColor = [UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0];
        header.textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:11.0f];
        header.textLabel.textAlignment = NSTextAlignmentCenter;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if (selectedStationArray.count > 0) {
        NSString *updateString = [defaults objectForKey:@"updateString"];
        if (updateString.length == 0) {
            return @"Last updated at: N/A";
        }else if (![defaults boolForKey:@"reachable"]){
            return [NSString stringWithFormat:@"Offline, Last updated: %@", updateString];
        }else{
            return [NSString stringWithFormat:@"Last updated: %@", updateString];
        }
    }else{
        return @"";
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return selectedStationArray.count;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        if (selectedStationArray.count == 10) {
            rightItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"AddIcon"]
                                                         style:UIBarButtonItemStylePlain
                                                        target:self action:@selector(addClicked:)];
            [rightItem setTintColor:[UIColor colorWithRed:0.60 green:0.60 blue:0.60 alpha:1.0]];
            self.navigationItem.rightBarButtonItem = rightItem;
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
            [self.navigationController.navigationBar setNeedsLayout];
        }
        
        [selectedStationArray removeObjectAtIndex:indexPath.row];
        
        [defaults setObject:selectedStationArray forKey:@"selectedStationArray"];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationTop];
        [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"pullNewWeather"];
        
        if (selectedStationArray.count == 0) {
            [_mainTable beginUpdates];
            //Update your data model here
            [_mainTable reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationTop];
            [_mainTable reloadEmptyDataSet];
            [_mainTable endUpdates];
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
    static NSString *CellIdentifier = @"mainCell";
    MainTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    NSMutableDictionary *cellDict = selectedStationArray[indexPath.row];
    NSMutableDictionary *titleDict = [NSMutableDictionary new];
    if (cellDict[@"cleanedTitle"]){
        titleDict = cellDict[@"cleanedTitle"];
    }else{
        [titleDict setObject:cellDict[@"stationTitle"] forKey:@"nameHolder"];
    }
    if (resultArray.count > 0 && minMaxArray.count > 0) {
        for (NSDictionary *resultDict in resultArray) {
            if ([resultDict[@"siteNumber"] isEqualToString:cellDict[@"stationNumber"]]) {
                if ([resultDict[@"siteValue"] doubleValue] > 0) {
                    cell.resultLabel.text = resultDict[@"siteValue"];
                }else{
                    cell.resultLabel.text = @"N/A";
                }
                
                for (NSDictionary *meanDict in minMaxArray) {
                    
                    if (meanDict[@"missingData"]) {
                        //code for missing mean min
                        if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                            cell.resultLabel.text = @"N/A";
                            [cell.resultLabel setTextColor:[UIColor whiteColor]];
                        }else{
                            [cell.resultLabel setTextColor:[UIColor whiteColor]];
                        }
                    }else{
                        if ([meanDict[@"siteNumber"] isEqualToString:cellDict[@"stationNumber"]]) {
                            NSLog(@"%f", [meanDict[@"25Value"] doubleValue]);
                            if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                                cell.resultLabel.text = @"N/A";
                                [cell.resultLabel setTextColor:[UIColor whiteColor]];
                            }else{
                                if ([resultDict[@"siteValue"] doubleValue] < [meanDict[@"25Value"] doubleValue] && meanDict[@"25Value"] != [NSNull null]) {
                                    //red
                                    [cell.resultLabel setTextColor:[UIColor colorWithRed:0.93 green:0.39 blue:0.25 alpha:1.0]];
                                }else if ([resultDict[@"siteValue"] doubleValue] > [meanDict[@"75Value"] doubleValue] && meanDict[@"75Value"] != [NSNull null]){
                                    //blue
                                    [cell.resultLabel setTextColor:[UIColor colorWithRed:0.15 green:0.58 blue:1.00 alpha:1.0]];
                                }else{
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
    [_spinnerView beginRefreshing];
    if (!hasTappedRow) {
        hasTappedRow = YES;

        [defaults setInteger:indexPath.row forKey:@"selectedIndex"];
        
        BOOL pullNewWeather = [defaults boolForKey:@"pullNewWeather"];
        
        NSDate *lastWeatherPullDate = [defaults objectForKey:@"updatedWeatherDate"];
        
        selectedStationArray = [[defaults objectForKey:@"selectedStationArray"] mutableCopy];
        
        if (lastWeatherPullDate == nil) {
            [self pullFromDarkWeather:selectedStationArray];
        }else{
            NSDate *todaysDate = [NSDate date];
            NSCalendar *gregorian = [NSCalendar currentCalendar];
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setHour:3];
            NSDate *targetDate = [gregorian dateByAddingComponents:dateComponents toDate:lastWeatherPullDate options:0];
            if ([targetDate compare:todaysDate] == NSOrderedAscending || pullNewWeather) {
                [self pullFromDarkWeather:selectedStationArray];
            }else{
                [_spinnerView endRefreshing];
                hasTappedRow = NO;
                [self performSegueWithIdentifier:@"swipeSegue" sender:self];
            }
        }
    }
}

- (void)pullFromDarkWeather:(NSMutableArray*)incomingDataArray{
    
    NSMutableArray *weatherDataArray = [NSMutableArray new];
    
    dispatch_group_t group = dispatch_group_create();
    
    for (NSMutableDictionary *stationDict in incomingDataArray) {
        //code here
        dispatch_group_enter(group);
        
        NSArray *tmpExclusions = @[kFCAlerts, kFCFlags, kFCMinutelyForecast, kFCHourlyForecast];
        
        forecastr.cacheEnabled = NO;
        
        [forecastr getForecastForLatitude:[stationDict[@"latTotal"] doubleValue] longitude:[stationDict[@"longTotal"] doubleValue] time:nil exclusions:tmpExclusions extend:nil success:^(id JSON) {
            NSDictionary *testRespDict = [NSDictionary dictionaryWithDictionary:JSON];
            
            NSDictionary *dailyDict = testRespDict[@"daily"];
            
            NSNumber *offsetNumber = testRespDict[@"offset"];
            
            NSArray *dailyArray = dailyDict[@"data"];
            
            NSMutableArray *intermediateArray = [NSMutableArray new];
            
            for (int i=0; i<4; i++){
                NSDictionary *innerDict = dailyArray[i];
                NSNumber *secondsPerHour = @(3600);
                int offsetInSeconds = [offsetNumber intValue] * [secondsPerHour intValue];
                NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
                
                int finalSeconds = [innerDict[@"time"] intValue] + offsetInSeconds;
                NSDate *preOffsetDate = [NSDate dateWithTimeIntervalSince1970:[innerDict[@"time"] intValue]];
                NSDate *date = [NSDate dateWithTimeIntervalSince1970:finalSeconds];
                
                formatter.locale = [NSLocale currentLocale];
                [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
                
                NSDateFormatter *df = [[NSDateFormatter alloc] init];
                df.locale = [NSLocale currentLocale];
                [df setDateFormat:@"EEEE"];
                
                NSString *dateString = [df stringFromDate:preOffsetDate];
                
                NSLog(@"intial %@", [formatter stringFromDate:preOffsetDate]);
                NSLog(@"intial %@", [df stringFromDate:preOffsetDate]);
                NSLog(@"%@", [formatter stringFromDate:date]);
                NSLog(@"%@", [df stringFromDate:date]);

                NSNumber *lowNum = innerDict[@"temperatureMin"];
                NSNumber *highNum = innerDict[@"temperatureMax"];
                
                NSString *iconString = innerDict[@"icon"];
                
                NSDictionary *weatherDict = [[NSDictionary alloc] initWithObjectsAndKeys:lowNum, @"lowNum", highNum, @"highNum", dateString, @"dateString", iconString, @"iconString", stationDict[@"stationNumber"], @"stationNumber", nil];
                
                [intermediateArray addObject:weatherDict];
            }
            
            [weatherDataArray addObject:intermediateArray];
            dispatch_group_leave(group);
            NSLog(@"test");
        } failure:^(NSError *error, id response) {
            NSLog(@"Error while retrieving forecast: %@", [forecastr messageForError:error withResponse:response]);
        }];
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        // Do whatever you need to do when all requests are finished
        [defaults setObject:weatherDataArray forKey:@"weatherArray"];
#pragma mark - TODO refresh
        [_spinnerView endRefreshing];
        hasTappedRow = NO;
        [self performSegueWithIdentifier:@"swipeSegue" sender:self];
        NSLog(@"finished?");
    });
}

- (IBAction)unwindToHome:(UIStoryboardSegue *)unwindSegue
{
    
}

@end
