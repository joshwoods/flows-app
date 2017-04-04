//
//  CustomNavigationViewController.m
//
//  Copyright © 2016 Matt Riddoch. All rights reserved.
//

#import "CustomNavigationViewController.h"

@interface CustomNavigationViewController ()

@end

@implementation CustomNavigationViewController

- (UIStoryboardSegue *)segueForUnwindingToViewController:(UIViewController *)toViewController fromViewController:(UIViewController *)fromViewController identifier:(NSString *)identifier {
    return [UIStoryboardSegue segueWithIdentifier:identifier source:fromViewController destination:toViewController performHandler:^{
        UIView *fromView = fromViewController.view;
        UIView *toView = toViewController.view;
        UIView *containerView = fromView.superview;
        NSTimeInterval duration = 1.0;
        
        CGRect initialFrame = fromView.frame;
        CGRect offscreenRect = initialFrame;
        offscreenRect.origin.x -= CGRectGetWidth(initialFrame);
        toView.frame = offscreenRect;
        [containerView addSubview:toView];

        [UIView animateWithDuration:duration
                              delay:0
             usingSpringWithDamping:0
              initialSpringVelocity:0
                            options:0
                         animations: ^{
                             [toViewController.navigationController popToViewController:toViewController animated:NO];
                         } completion: ^(BOOL finished) {
                         }];
        
        
    }];    
}
@end
