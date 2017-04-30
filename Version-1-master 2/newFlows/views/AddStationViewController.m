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

@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (strong, nonatomic) NSMutableArray *alphabetsAray;
@property (strong, nonatomic) NSMutableArray *riverAlphabetsArray;
@property (strong, nonatomic) NSMutableArray *stateHolder;
@property (strong, nonatomic) NSMutableArray *queryHolder;
@property (strong, nonatomic) NSMutableArray *sortedDetailForTable;

@property (assign, nonatomic) BOOL isInState;

@property (strong, nonatomic) NSString *stateToPass;
@property (strong, nonatomic) NSString *longStateToPass;

@property (strong, nonatomic) GDIIndexBar *indexBar;

@end

@implementation AddStationViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.title = @"Add Station";
    
    self.navigationController.navigationBar.alpha = 1.0f;
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
    
    self.tableView.estimatedRowHeight = 50.0;
    self.tableView.rowHeight = UITableViewAutomaticDimension;
    self.tableView.tableFooterView = [UIView new];
    
    self.stateHolder = [[NSMutableArray alloc] initWithObjects:@"Alabama", @"Alaska", @"Arizona", @"Arkansas", @"California", @"Colorado", @"Connecticut", @"Delaware", @"Dist. of Columbia", @"Florida", @"Georgia", @"Guam", @"Hawaii", @"Idaho", @"Illinois", @"Indiana", @"Iowa", @"Kansas", @"Kentucky", @"Louisiana", @"Maine", @"Maryland", @"Massachusetts", @"Michigan", @"Minnesota", @"Missouri", @"Montana", @"Nebraska", @"Nevada", @"New Hampshire", @"New Jersey", @"New Mexico", @"New York", @"North Carolina", @"North Dakota", @"Ohio", @"Oklahoma", @"Oregon", @"Pennsylvania", @"Puerto Rico", @"Rhode Island", @"South Carolina", @"South Dakota", @"Tennessee", @"Texas", @"Utah", @"Vermont", @"Virginia", @"Virgin Islands", @"Washington", @"West Virginia", @"Wisconsin", @"Wyoming", nil];
    self.queryHolder = [[NSMutableArray alloc] initWithObjects:@"al", @"ak", @"az", @"ar", @"ca", @"co", @"ct", @"de", @"dc", @"fl", @"ga", @"gu", @"hi", @"id", @"il", @"in", @"ia", @"ks", @"ky", @"la", @"me", @"md", @"ma", @"mi", @"mn", @"mo", @"mt", @"ne", @"nv", @"nh", @"nj", @"nm", @"ny", @"nc", @"nd", @"oh", @"ok", @"or", @"pa", @"pr", @"ri", @"sc", @"sd", @"tn", @"tx", @"ut", @"vt", @"va", @"vi", @"wa", @"wv", @"wi", @"wy", nil];
    
    [self createAlphabetArray];
    
    self.indexBar = [[GDIIndexBar alloc] initWithTableView:self.tableView];
    [[GDIIndexBar appearance] setTextColor:[UIColor colorWithHex:@"ACACAC"]];
    [[GDIIndexBar appearance] setBackgroundColor:[UIColor clearColor]];
    [[GDIIndexBar appearance] setBarBackgroundColor:[UIColor clearColor]];
    self.indexBar.textFont = [UIFont fontWithName:@"HelveticaNeue-Thin" size:13.0f];
    self.indexBar.delegate = self;
    [self.indexBar setTextOffset:UIOffsetMake(5.0, 0.0)];
    [self.view addSubview:self.indexBar];
    
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

- (IBAction)backClicked:(id)sender
{
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.alphabetsAray.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.alphabetsAray objectAtIndex:section]]];
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
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"AddStationCellIdentifier" forIndexPath:indexPath];
        
    NSArray *sectionArray = [self.stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.alphabetsAray objectAtIndex:indexPath.section]]];
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0f], NSForegroundColorAttributeName: [UIColor whiteColor]};
    
    NSAttributedString *cellString = [[NSAttributedString alloc] initWithString:[sectionArray objectAtIndex:indexPath.row] attributes:attributes];
    
    [cell.textLabel setAttributedText:cellString];
        
    return cell;
    
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionArray = [self.queryHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.alphabetsAray objectAtIndex:indexPath.section]]];
    NSArray *stateNameArray = [self.stateHolder filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"SELF beginswith[c] %@", [self.alphabetsAray objectAtIndex:indexPath.section]]];
    self.stateToPass = [sectionArray objectAtIndex:indexPath.row];
    self.longStateToPass = [stateNameArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:@"stationDetailView" sender:self];
}

#pragma mark - index bar

- (NSUInteger)numberOfIndexesForIndexBar:(GDIIndexBar *)indexBar
{
    return self.alphabetsAray.count;
}

- (NSString *)stringForIndex:(NSUInteger)index
{
    return [self.alphabetsAray objectAtIndex:index];
}

- (void)indexBar:(GDIIndexBar *)indexBar didSelectIndex:(NSUInteger)index
{
    [self.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:index]
                      atScrollPosition:UITableViewScrollPositionTop
                              animated:NO];
}

#pragma mark - data prep

#pragma mark - Create Alphabet Array
- (void)createAlphabetArray {
    self.alphabetsAray = [[NSMutableArray alloc] init];

    [self.alphabetsAray removeAllObjects];

    for (int i = 0; i < [self.stateHolder count]; i++) {
        NSString *letterString = [[self.stateHolder objectAtIndex:i] substringToIndex:1].uppercaseString;
        if (![self.alphabetsAray containsObject:letterString]) {
            [self.alphabetsAray addObject:letterString];
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
    [vc setIncomingValue:self.stateToPass];
    [vc setSelectedState:self.longStateToPass];
}

@end
