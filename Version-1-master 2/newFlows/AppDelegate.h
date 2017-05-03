//
//  AppDelegate.h
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) NSMutableArray *selectedStationArray;

- (void)runLiveUpdate;
- (void)refreshData;

@end
