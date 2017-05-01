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

@interface PurchaseViewController ()

@property (weak, nonatomic) IBOutlet UIButton *upgradeButton;

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
    
    self.navigationController.navigationBar.translucent = YES;
    
    UIImageView* img = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"HeaderLogo"]];
    self.navigationItem.titleView = img;
}

- (void)purchaseUpgradewithNote:(NSNotification*)incomingNote
{
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

- (IBAction)cancelTapped:(id)sender
{
    CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    transition.type = kCATransitionPush;
    transition.subtype = kCATransitionFade;
    
    [self.navigationController.view.layer addAnimation:transition forKey:nil];
    [self.navigationController popViewControllerAnimated:NO];
}

- (IBAction)upgradeTapped:(id)sender
{
    [[MKStoreKit sharedKit] initiatePaymentRequestForProductWithIdentifier:@"com.flowsapp.flowspro"];
}

@end
