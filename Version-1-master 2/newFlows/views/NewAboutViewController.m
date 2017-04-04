//
//  NewAboutViewController.m
//
//  Copyright © 2016 Matt Riddoch. All rights reserved.
//

#import "NewAboutViewController.h"
#import "UIColor+Hexadecimal.h"
#import "pushAnimator.h"
#import "popAnimator.h"

@interface NewAboutViewController () <UINavigationControllerDelegate>

@end

@implementation NewAboutViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = [UIImage new];
    self.navigationController.navigationBar.translucent = YES;
    
    self.navigationController.delegate = self;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 44)];
    label.backgroundColor = [UIColor clearColor];
    label.numberOfLines = 0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0f];
    label.textColor = [UIColor whiteColor];
    label.text = @"Add Station";
    
    [self.navigationItem.titleView sizeToFit];
    self.navigationItem.titleView = label;
    
    NSDictionary *barButtonAppearanceDict = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Thin" size:18.0], NSForegroundColorAttributeName: [UIColor colorWithHex:@"ACACAC"]};
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    
    [self.navigationItem setHidesBackButton:YES animated:NO];
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

@end
