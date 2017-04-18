//
//  AddDetailViewController.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "AddDetailViewController.h"
#import "GDIIndexBar.h"
#import "UIColor+Hexadecimal.h"
#import "pushAnimator.h"
#import "popAnimator.h"

@interface AddDetailViewController () <UITableViewDelegate, UITableViewDataSource, GDIIndexBarDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTable;

@end

@implementation AddDetailViewController{
    NSArray *arrayForTable;
    GDIIndexBar *indexBar;
    NSMutableArray *alphabetsArray;
    NSData *dataToPass;
    NSUserDefaults *defaults;
}

@synthesize incomingValue;
@synthesize selectedState;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    arrayForTable = [NSArray new];
    alphabetsArray = [NSMutableArray new];
    defaults = [NSUserDefaults standardUserDefaults];
    
    NSURL *dataPath = [[NSBundle mainBundle] URLForResource:incomingValue withExtension:@""];
    NSString *stringPath = [dataPath absoluteString];
    
    [self.mainTable setSeparatorColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    
    _mainTable.tableFooterView = [UIView new];
    
    NSData *data = [NSData dataWithContentsOfURL:[NSURL URLWithString:stringPath]];
    
    NSString *responseHolder = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    NSArray *components = [responseHolder componentsSeparatedByString:@"\n"];
    
    NSMutableArray *workingDataArray = [[NSMutableArray alloc] initWithArray:components];
    
    [self.navigationItem setTitle:selectedState];
    
    NSMutableArray *tempForSort = [[NSMutableArray alloc] init];
    
    for (int i=0; i<workingDataArray.count; i++) {
        NSString *matchCriteria = @"USGS";
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", matchCriteria];
        
        BOOL filePathMatches = [pred evaluateWithObject:[workingDataArray objectAtIndex:i]];
        
        if (filePathMatches) {
            NSArray *tempHolderArray = [[workingDataArray objectAtIndex:i] componentsSeparatedByString:@"\t"];
            
            NSLog(@"%@", tempHolderArray);
            NSDictionary *tempInstanceDict = [[NSDictionary alloc] initWithObjectsAndKeys:[tempHolderArray objectAtIndex:1], @"siteNumber", [tempHolderArray objectAtIndex:2], @"siteName", nil];
            [tempForSort addObject:tempInstanceDict];
        }
        
    }
    
    NSSortDescriptor *siteDescriptor = [[NSSortDescriptor alloc] initWithKey:@"siteName" ascending:YES];
    NSArray *sortDescriptors = [NSArray arrayWithObject:siteDescriptor];
    
    arrayForTable = [tempForSort sortedArrayUsingDescriptors:sortDescriptors];
    
    self.navigationItem.title = selectedState;
    
    [self createAlphabetArray];
    
    if (alphabetsArray.count > 10) {
        indexBar = [[GDIIndexBar alloc] initWithTableView:_mainTable];
        [[GDIIndexBar appearance] setTextColor:[UIColor colorWithHex:@"ACACAC"]];
        [[GDIIndexBar appearance] setBackgroundColor:[UIColor clearColor]];
        indexBar.delegate = self;
        indexBar.textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:13.0f];
        [indexBar setTextOffset:UIOffsetMake(2.0, 0.0)];
        [self.view addSubview:indexBar];
    }
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
    self.navigationController.delegate = self;
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

#pragma mark - Create Alphabet Array
- (void)createAlphabetArray {
    [alphabetsArray removeAllObjects];
    
    for (int i = 0; i < [arrayForTable count]; i++) {
        NSDictionary *holderDict = arrayForTable[i];
        NSString *siteName = holderDict[@"siteName"];
        NSString *letterString = [siteName substringToIndex:1];
        if (![alphabetsArray containsObject:letterString]) {
            [alphabetsArray addObject:letterString];
        }
    }
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return alphabetsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [arrayForTable filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(siteName beginswith[c] %@)", [alphabetsArray objectAtIndex:section]]];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"addDetail";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    NSArray *sectionArray = [arrayForTable filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(siteName beginswith[c] %@)", [alphabetsArray objectAtIndex:indexPath.section]]];
    NSDictionary *cellDict = sectionArray[indexPath.row];
    NSString *siteOrigin = cellDict[@"siteName"];
    NSString *siteName = [siteOrigin stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    siteName = [siteName uppercaseString];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0f], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    if ([siteName length] && isnumber([siteName characterAtIndex:0])) {
        NSAttributedString *cellString = [[NSAttributedString alloc] initWithString:siteName attributes:attributes];
        [cell.textLabel setAttributedText:cellString];
    }else{
        NSMutableDictionary *location = [self locationName:siteName];
        NSDictionary *detailAttributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:15.0f], NSForegroundColorAttributeName:[UIColor colorWithHex:@"ACACAC"]};
        
        NSAttributedString *cellString = [[NSAttributedString alloc] initWithString:[location objectForKey:@"nameHolder"] attributes:attributes];
        NSAttributedString *cellDetailString = [[NSAttributedString alloc] initWithString:[location objectForKey:@"locationHolder"] attributes:detailAttributes];
        [cell.textLabel setAttributedText:cellString];
        [cell.detailTextLabel setAttributedText:cellDetailString];
    }
    
    return cell;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return alphabetsArray[section];
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    if ([view isKindOfClass:[UITableViewHeaderFooterView class]]) {
        ((UITableViewHeaderFooterView *)view).backgroundView.backgroundColor = [UIColor colorWithRed:0.09 green:0.09 blue:0.09 alpha:1.0];
    }
    
    UIView *topSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, -0.5f, view.bounds.size.width, 0.5f)];
    [topSeperatorView setBackgroundColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    
    UIView *bottomSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, view.bounds.size.height-0.5f, view.bounds.size.width, 0.5f)];
    [bottomSeperatorView setBackgroundColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    
    [view addSubview:bottomSeperatorView];
    [view addSubview:topSeperatorView];
    
    header.textLabel.textColor = [UIColor whiteColor];
    header.textLabel.font = [UIFont boldSystemFontOfSize:18];
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    header.textLabel.textAlignment = NSTextAlignmentJustified;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
    [cell setPreservesSuperviewLayoutMargins:NO];
    [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70;
}

#pragma mark - custom dictionary

- (NSMutableDictionary*)locationName:(NSString*)siteName{
    NSMutableDictionary *returnDict = [NSMutableDictionary new];
    
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"abbreviations" ofType:@"plist"];
    NSArray *array = [[NSArray alloc] initWithContentsOfFile:filePath];
    
    for (NSDictionary *abbrDict in array){
        NSString *abbrString = abbrDict[@"abbr"];
        NSString *replaceString = abbrDict[@"replace"];
        NSPredicate *loopPredicate = [NSPredicate predicateWithFormat:@"self CONTAINS %@", abbrString];
        BOOL match = [loopPredicate evaluateWithObject:siteName];
        if (match) {
            siteName = [siteName stringByReplacingOccurrencesOfString:abbrString withString:replaceString];
        }
    }
    
    NSRange theRange = [siteName rangeOfString:@"," options:NSBackwardsSearch];
    if (theRange.location != NSNotFound && theRange.length<4){
        siteName = [siteName substringToIndex:theRange.location];
    }
    
    NSString *nameHolder;
    NSString *locationHolder;
    
    NSArray *criteraArray = [[NSArray alloc] initWithObjects:@" AT ", @" BELOW ", @" ABOVE ", @" NEAR ", @" TO ", nil];
    
    int shortestBreak = 0;
    int selectedBreak = 100;
    int stationCounter = 0;
    NSString *stationHolderString;
    
    for (int i=0; i<criteraArray.count; i++) {
        NSString *criteriaString = criteraArray[i];
        NSPredicate *loopPredicate = [NSPredicate predicateWithFormat:@"self CONTAINS %@", criteriaString];
        BOOL match = [loopPredicate evaluateWithObject:siteName];
        if (match) {
            NSRange r = NSMakeRange(0, siteName.length);
            switch (i) {
                case 0:
                {
                    r = [siteName rangeOfString:@" AT " options:NSCaseInsensitiveSearch range:r];
                    if ((int)r.location <  shortestBreak || shortestBreak == 0) {
                        selectedBreak = i;
                        shortestBreak = (int)r.location;
                    }
                }
                    break;
                case 1:
                {
                    r = [siteName rangeOfString:@" BELOW " options:NSCaseInsensitiveSearch range:r];
                    if ((int)r.location < shortestBreak || shortestBreak == 0) {
                        selectedBreak = i;
                        shortestBreak = (int)r.location;
                    }
                }
                    break;
                case 2:
                {
                    r = [siteName rangeOfString:@" ABOVE " options:NSCaseInsensitiveSearch range:r];
                    if ((int)r.location < shortestBreak || shortestBreak == 0) {
                        selectedBreak = i;
                        shortestBreak = (int)r.location;
                    }
                }
                    break;
                case 3:
                {
                    r = [siteName rangeOfString:@" NEAR " options:NSCaseInsensitiveSearch range:r];
                    if (r.location < shortestBreak || shortestBreak == 0) {
                        selectedBreak = i;
                        shortestBreak = (int)r.location;
                    }
                }
                    break;
                case 4:
                {
                    r = [siteName rangeOfString:@" TO " options:NSCaseInsensitiveSearch range:r];
                    if (r.location < shortestBreak || shortestBreak == 0) {
                        selectedBreak = i;
                        shortestBreak = (int)r.location;
                    }
                }
                    break;
                    
                default:
                    break;
            }
            NSArray *titleArray = [NSArray new];
            NSString *selectedString;
            switch (selectedBreak) {
                case 0:
                    selectedString = @"AT";
                    break;
                case 1:
                    selectedString = @"BELOW";
                    break;
                case 2:
                    selectedString = @"ABOVE";
                    break;
                case 3:
                    selectedString = @"NEAR";
                    break;
                case 4:
                    selectedString = @"TO";
                    break;
                default:
                    break;
            }
            
            titleArray = [siteName componentsSeparatedByString:[NSString stringWithFormat:@" %@ ", selectedString]];
            
            if (titleArray.count > 2) {
                switch (titleArray.count) {
                    case 3:
                    {
                        NSString *tempHolder = titleArray[2];
                        nameHolder = [titleArray objectAtIndex:0];
                        locationHolder = [titleArray objectAtIndex:1];
                        locationHolder = [locationHolder stringByAppendingString:[NSString stringWithFormat:@" %@ %@",selectedString, tempHolder]];
                    }
                        break;
                    case 4:
                    {
                        //TODO NEVER GETS HIT
                        NSString *tempOneHolder = titleArray[2];
                        NSString *tempTwoHolder = titleArray[3];
                        nameHolder = [titleArray objectAtIndex:0];
                        locationHolder = [titleArray objectAtIndex:1];
                        locationHolder = [locationHolder stringByAppendingString:[NSString stringWithFormat:@" %@ %@ %@",selectedString, tempOneHolder, tempTwoHolder]];
                    }
                        break;
                    default:
                        break;
                }
            }else{
                nameHolder = [titleArray objectAtIndex:0];
                locationHolder = [titleArray objectAtIndex:1];
                locationHolder = [NSString stringWithFormat:@"%@ %@", selectedString, locationHolder];
            }
            
            nameHolder = [nameHolder capitalizedString];
            locationHolder = [locationHolder capitalizedString];
            
            [returnDict setObject:nameHolder forKey:@"nameHolder"];
            [returnDict setObject:locationHolder forKey:@"locationHolder"];
            
        }else{
            //fallback here
            if (stationCounter == 0 && stationHolderString.length == 0) {
                stationHolderString = siteName;
                stationCounter++;
            }else if(stationCounter < 5){
                stationCounter++;
            }else{
#pragma mark - TODO clean up here
            }
        }
    }
    
    if (!returnDict[@"nameHolder"]) {
        NSString *tempName = [[NSString stringWithFormat:@"%@", siteName] capitalizedString];
        [returnDict setObject:tempName forKey:@"nameHolder"];
        [returnDict setObject:@"" forKey:@"locationHolder"];
    }
    
    return returnDict;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionArray = [arrayForTable filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"(siteName beginswith[c] %@)", [alphabetsArray objectAtIndex:indexPath.section]]];
    NSDictionary *cellDict = sectionArray[indexPath.row];
    
    NSString *siteName = cellDict[@"siteName"];
    siteName = [siteName uppercaseString];
    NSMutableDictionary *location;
    if ([siteName length] && isnumber([siteName characterAtIndex:0])) {
        [location setObject:siteName forKey:@"nameHolder"];
    }else{
        location = [self locationName:siteName];
    }
    
    NSMutableArray *selectedStationArray = [[defaults objectForKey:@"selectedStationArray"] mutableCopy];
    if (!selectedStationArray) {
        selectedStationArray = [NSMutableArray new];
    }
    
    //add station
    NSMutableDictionary *holderDict = [[NSMutableDictionary alloc] initWithObjectsAndKeys:cellDict[@"siteName"], @"stationTitle", cellDict[@"siteNumber"], @"stationNumber", location, @"cleanedTitle", nil];
    [selectedStationArray addObject:holderDict];
    [defaults setObject:selectedStationArray forKey:@"selectedStationArray"];
    [defaults setObject:[NSNumber numberWithBool:YES] forKey:@"selectedStationUpdated"];
}

#pragma mark - index bar

- (NSUInteger)numberOfIndexesForIndexBar:(GDIIndexBar *)indexBar
{
    return alphabetsArray.count;
}

- (NSString *)stringForIndex:(NSUInteger)index
{
    return [alphabetsArray objectAtIndex:index];
}

- (void)indexBar:(GDIIndexBar *)indexBar didSelectIndex:(NSUInteger)index
{
    [_mainTable scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
                      atScrollPosition:UITableViewScrollPositionTop
                              animated:NO];
}

- (IBAction)cancelClicked:(id)sender {
    [self.navigationController popToRootViewControllerAnimated:NO];
}

- (IBAction)backClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

@end
