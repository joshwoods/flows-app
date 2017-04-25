//
//  AddStationViewController.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "AddStationViewController.h"
#import "GDIIndexBar.h"
#import "AddDetailViewController.h"
#import "UIColor+Hexadecimal.h"
#import "pushAnimator.h"
#import "popAnimator.h"

@interface AddStationViewController () <UITableViewDataSource, UITableViewDelegate, GDIIndexBarDelegate, UINavigationControllerDelegate, UIViewControllerTransitioningDelegate>

@property (weak, nonatomic) IBOutlet UITableView *mainTable;

@end

@implementation AddStationViewController{
    BOOL isInState;
    NSMutableArray *alphabetsArray;
    NSMutableArray *riverAlphabetsArray;
    NSMutableArray *stateHolder;
    NSMutableArray *queryHolder;
    NSMutableArray *sortedDetailForTable;
    GDIIndexBar *indexBar;
    NSString *stateToPass;
    NSString *longStateToPass;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.mainTable setSeparatorColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];

    self.navigationItem.title = @"Add Station";
    
    self.navigationController.navigationBar.alpha = 1.0f;
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    _mainTable.tableFooterView = [UIView new];
    
    stateHolder = [[NSMutableArray alloc] initWithObjects:@"Alabama", @"Alaska", @"Arizona", @"Arkansas", @"California", @"Colorado", @"Connecticut", @"Delaware", @"Dist. of Columbia", @"Florida", @"Georgia", @"Guam", @"Hawaii", @"Idaho", @"Illinois", @"Indiana", @"Iowa", @"Kansas", @"Kentucky", @"Louisiana", @"Maine", @"Maryland", @"Massachusetts", @"Michigan", @"Minnesota", @"Missouri", @"Montana", @"Nebraska", @"Nevada", @"New Hampshire", @"New Jersey", @"New Mexico", @"New York", @"North Carolina", @"North Dakota", @"Ohio", @"Oklahoma", @"Oregon", @"Pennsylvania", @"Puerto Rico", @"Rhode Island", @"South Carolina", @"South Dakota", @"Tennessee", @"Texas", @"Utah", @"Vermont", @"Virginia", @"Virgin Islands", @"Washington", @"West Virginia", @"Wisconsin", @"Wyoming", nil];
    queryHolder = [[NSMutableArray alloc] initWithObjects:@"al", @"ak", @"az", @"ar", @"ca", @"co", @"ct", @"de", @"dc", @"fl", @"ga", @"gu", @"hi", @"id", @"il", @"in", @"ia", @"ks", @"ky", @"la", @"me", @"md", @"ma", @"mi", @"mn", @"mo", @"mt", @"ne", @"nv", @"nh", @"nj", @"nm", @"ny", @"nc", @"nd", @"oh", @"ok", @"or", @"pa", @"pr", @"ri", @"sc", @"sd", @"tn", @"tx", @"ut", @"vt", @"va", @"vi", @"wa", @"wv", @"wi", @"wy", nil];
    
    alphabetsArray = [[NSMutableArray alloc] init];
    
    [self createAlphabetArray];
    
    [_mainTable setBackgroundColor:[UIColor clearColor]];
    
    indexBar = [[GDIIndexBar alloc] initWithTableView:_mainTable];
    [[GDIIndexBar appearance] setTextColor:[UIColor colorWithHex:@"ACACAC"]];
    [[GDIIndexBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[GDIIndexBar appearance] setBarBackgroundColor:[UIColor clearColor]];
    indexBar.textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:13.0f];
    indexBar.delegate = self;
    [indexBar setTextOffset:UIOffsetMake(5.0, 0.0)];
    [self.view addSubview:indexBar];
    
    
    if ([[NSUserDefaults standardUserDefaults] boolForKey:@"segueToRivers"]) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"segueToRivers"];
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

- (IBAction)backClicked:(id)sender{
    [self.navigationController popViewControllerAnimated:NO];
    NSLog(@"back clicked");
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return alphabetsArray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [alphabetsArray objectAtIndex:section]]];
    return sectionArray.count;
    
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
        [cell setSeparatorInset:UIEdgeInsetsZero];
        [cell setPreservesSuperviewLayoutMargins:NO];
        [cell setLayoutMargins:UIEdgeInsetsZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"addCell";
    
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    
    [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
    
    NSArray *sectionArray = [stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [alphabetsArray objectAtIndex:indexPath.section]]];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0f], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    NSAttributedString *cellString = [[NSAttributedString alloc] initWithString:[sectionArray objectAtIndex:indexPath.row] attributes:attributes];
    
    [cell.textLabel setAttributedText:cellString];
    
    [cell.textLabel setTextColor:[UIColor whiteColor]];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
    
    return cell;
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionArray = [queryHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [alphabetsArray objectAtIndex:indexPath.section]]];
    NSArray *stateNameArray = [stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [alphabetsArray objectAtIndex:indexPath.section]]];
    stateToPass = [sectionArray objectAtIndex:indexPath.row];
    longStateToPass= [stateNameArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"stationDetailView" sender:self];
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

#pragma mark - data prep

#pragma mark - Create Alphabet Array
- (void)createAlphabetArray {
    [alphabetsArray removeAllObjects];

    for (int i = 0; i < [stateHolder count]; i++) {
        NSString *letterString = [[stateHolder objectAtIndex:i] substringToIndex:1].uppercaseString;
        if (![alphabetsArray containsObject:letterString]) {
            [alphabetsArray addObject:letterString];
        }
    }
}

- (IBAction)cancelClicked:(id)sender {
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    AddDetailViewController *vc = [segue destinationViewController];
    [vc setIncomingValue:stateToPass];
    [vc setSelectedState:longStateToPass];
}

@end
