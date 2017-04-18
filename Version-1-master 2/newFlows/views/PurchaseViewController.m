//
//  PurchaseViewController.m
//
//  Copyright © 2016 Matt Riddoch. All rights reserved.
//

#import "PurchaseViewController.h"
#import "UIColor+Hexadecimal.h"
#import "MKStoreKit.h"
#import "UIScrollView+EmptyDataSet.h"
#import "MKStoreKit.h"

@interface PurchaseViewController () <UITableViewDataSource, UITableViewDelegate, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate>
@property (weak, nonatomic) IBOutlet UITableView *mainTable;

@end

@implementation PurchaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[MKStoreKit sharedKit] startProductRequest];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitProductsAvailableNotification
                                                      object:nil
                                                       queue:[[NSOperationQueue alloc] init]
                                                  usingBlock:^(NSNotification *note) {
                                                      
                                                      NSLog(@"Products available: %@", [[MKStoreKit sharedKit] availableProducts]);
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitProductPurchasedNotification
                                                      object:nil
                                                       queue:[[NSOperationQueue alloc] init]
                                                  usingBlock:^(NSNotification *note) {
                                                      [self purchaseUpgradewithNote:note];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitRestoredPurchasesNotification
                                                      object:nil
                                                       queue:[[NSOperationQueue alloc] init]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"Restored Purchases");
                                                      [self purchaseUpgradewithNote:note];
                                                  }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:kMKStoreKitRestoringPurchasesFailedNotification
                                                      object:nil
                                                       queue:[[NSOperationQueue alloc] init]
                                                  usingBlock:^(NSNotification *note) {
                                                      NSLog(@"Failed restoring purchases with error: %@", [note object]);
                                                  }];
    
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    self.navigationItem.titleView = img;
    
    _mainTable.tableFooterView = [UIView new];
}

- (void)purchaseUpgradewithNote:(NSNotification*)incomingNote{
    dispatch_async(dispatch_get_main_queue(), ^{
        NSLog(@"Purchased/Subscribed to product with id: %@", [incomingNote object]);
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"upgradePurchased"];
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"segueToRivers"];
        CATransition *transition = [CATransition animation];
        transition.duration = 0.5;
        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        transition.type = kCATransitionPush;
        transition.subtype = kCATransitionFade;
        
        [self.navigationController.view.layer addAnimation:transition forKey:nil];
        [self.navigationController popViewControllerAnimated:NO];
    });
}

- (IBAction)cancelClicked:(id)sender {
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFade;
    
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

#pragma mark - EmptyDataset

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    NSString *text = @"$.99 gets you access to 10 stations";
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    paragraphStyle.headIndent = 20.0;
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.firstLineHeadIndent = 20.0;
    paragraphStyle.tailIndent = -20.0;
    
    NSDictionary *attributes = @{NSFontAttributeName: [UIFont fontWithName:@"HelveticaNeue-Thin" size:26.0f],
                                 NSForegroundColorAttributeName: [UIColor colorWithHex:@"FFFFFF"],
                                 NSParagraphStyleAttributeName: paragraphStyle};
    
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:text attributes:attributes];
    [attributedString addAttribute:NSKernAttributeName
                             value:@(-2.0)
                             range:NSMakeRange(22, 3)];
    
    return attributedString;
}

- (NSAttributedString *)buttonTitleForEmptyDataSet:(UIScrollView *)scrollView forState:(UIControlState)state
{
    UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:17.0f];
    UIColor *textColor = [UIColor colorWithHex:(state == UIControlStateNormal) ? @"ffffff" : @"acacac"];
    NSMutableDictionary *attributes = [NSMutableDictionary new];
    if (font) [attributes setObject:font forKey:NSFontAttributeName];
    if (textColor) [attributes setObject:textColor forKey:NSForegroundColorAttributeName];
    
    return [[NSAttributedString alloc] initWithString:@"Upgrade" attributes:attributes];
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
    return YES;
}

#pragma mark - UITableviewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 0;
}

#pragma mark -

- (void)emptyDataSetDidTapButton:(UIScrollView *)scrollView
{
    [[MKStoreKit sharedKit] initiatePaymentRequestForProductWithIdentifier:@"com.flowsapp.flowspro"];
}

@end
