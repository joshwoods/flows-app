//
//  customNavBar.m
//
//  Copyright © 2016 Matt Riddoch. All rights reserved.
//

#import "customNavBar.h"
#define kAppNavBarHeight 66.0

@implementation customNavBar

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self setupAppearance];
    }
    return self;
}

- (void)setupAppearance {
    
    static BOOL appearanceInitialised = NO;
    
    if (!appearanceInitialised) {
        
        // Update the appearance of this bar to shift the icons back up to their normal position
        
        CGFloat offset = 54 - kAppNavBarHeight;
        
        [[customNavBar appearance] setTitleVerticalPositionAdjustment:offset forBarMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setBackgroundVerticalPositionAdjustment:offset forBarMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setBackButtonBackgroundVerticalPositionAdjustment:offset forBarMetrics:UIBarMetricsDefault];
        [[UIBarButtonItem appearanceWhenContainedIn:[UINavigationBar class], nil] setBackButtonTitlePositionAdjustment:UIOffsetMake(0, offset) forBarMetrics:UIBarMetricsDefault];
        
        
    }
}

- (CGSize)sizeThatFits:(CGSize)size {
    
    return CGSizeMake(self.superview.frame.size.width, kAppNavBarHeight);
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    UIView *bottomSeperatorView = [[UIView alloc] initWithFrame:CGRectMake(0, self.bounds.size.height-0.5f, self.bounds.size.width, 0.5f)];
    [bottomSeperatorView setBackgroundColor:[UIColor colorWithRed:0.20 green:0.20 blue:0.20 alpha:1.0]];
    [self addSubview:bottomSeperatorView];
}

- (UINavigationItem *)popNavigationItemAnimated:(BOOL)animated {
    return [super popNavigationItemAnimated:NO];
}

@end
