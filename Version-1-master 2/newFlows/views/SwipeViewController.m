//
//  SwipeViewController.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "SwipeViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "UIView+Facade.h"
#import <QuartzCore/QuartzCore.h>
#import <PromiseKit/PromiseKit.h>
#import "CustomSwipeview.h"

#define METERS_PER_MILE 1609.344

@interface SwipeViewController () <SwipeViewDataSource, SwipeViewDelegate, MKMapViewDelegate>

@property (weak, nonatomic) IBOutlet SwipeView *swipeView;

@end

@implementation SwipeViewController{
    UIPageControl *pageControl;
    UIButton *backButton;
    UIButton *mapButton;
    BOOL mapEnabled;
    NSMutableArray *weatherCacheArray;
    NSUserDefaults *defaults;
    BOOL firstViewLoad;
    NSString *incomingData;
    NSMutableArray *incomingItems;
    NSMutableArray *locationArray;
    NSMutableArray *resultArray;
    NSMutableArray *minMaxArray;
    BOOL isLoading;
    BOOL isLoadingSecond;
}

@synthesize testArray;

- (void)awakeFromNib
{
    [super awakeFromNib];

    defaults = [NSUserDefaults standardUserDefaults];
    
    incomingData = [defaults objectForKey:@"detailData"];
    incomingItems = [defaults objectForKey:@"selectedStationArray"];
    resultArray = [defaults objectForKey:@"resultArray"];
    minMaxArray = [defaults objectForKey:@"minMaxArray"];
    weatherCacheArray = [defaults objectForKey:@"weatherArray"];
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    firstViewLoad = YES;
    
    //configure swipeView
    _swipeView.pagingEnabled = YES;
    
    backButton = [[UIButton alloc] init];
    [backButton setTag:1001];
    [backButton setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:backButton];
    [backButton anchorTopLeftWithLeftPadding:0 topPadding:27 width:50 height:50];
    UIImage *backArrow = [UIImage imageNamed:@"BackIcon"];
    [backButton setImage:backArrow forState:UIControlStateNormal];
    [backButton addTarget:self action:@selector(backClickedPage:) forControlEvents:UIControlEventTouchUpInside];
    
    mapButton = [[UIButton alloc] init];
    [mapButton setTag:1002];
    [mapButton setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:mapButton];
    UIImage *mapNavIcon = [UIImage imageNamed:@"GreyMapIcon"];
    [mapButton setImage:mapNavIcon forState:UIControlStateNormal];
    [mapButton anchorTopRightWithRightPadding:0 topPadding:27 width:50 height:50];
    [mapButton addTarget:self action:@selector(mapClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    if (incomingItems.count > 1) {
        pageControl = [[UIPageControl alloc] init];
        [self.view addSubview:pageControl];
        [pageControl setNumberOfPages:incomingItems.count];
        [pageControl anchorBottomCenterFillingWidthWithLeftAndRightPadding:50 bottomPadding:10 height:20];
        
        [pageControl addTarget:self action:@selector(changePage:) forControlEvents:UIControlEventValueChanged];
    }
    
    int incoming = (int)[defaults integerForKey:@"selectedIndex"];
    if (incoming==0) {
        isLoading = NO;
        isLoadingSecond = NO;
    }else{
        isLoading = NO;
        isLoadingSecond = NO;
        [_swipeView scrollToItemAtIndex:incoming duration:0.01f];
    }
}

#pragma mark iCarousel methods

- (NSInteger)numberOfItemsInSwipeView:(SwipeView *)swipeView
{
    return [incomingItems count];
}

- (UIView *)swipeView:(SwipeView *)swipeView viewForItemAtIndex:(NSInteger)index reusingView:(CustomSwipeview *)view
{
    if (view == nil)
    {
        view = [[[NSBundle mainBundle]
                         loadNibNamed:@"SwipeView"
                         owner:self options:nil]
                        firstObject];
        view.bounds = self.swipeView.bounds;
        view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
            view.mainMap.zoomEnabled = NO;
            view.mainMap.scrollEnabled = NO;
            view.mainMap.userInteractionEnabled = NO;
            view.backGroundImage.alpha = 0.95f;
    }

    NSDictionary *stationDict = incomingItems[index];
    CLLocationCoordinate2D stationLocation;
    stationLocation.longitude = (CLLocationDegrees) [stationDict[@"longTotal"] doubleValue];
    stationLocation.latitude = (CLLocationDegrees) [stationDict[@"latTotal"] doubleValue];
    
    MKCoordinateRegion viewRegion = MKCoordinateRegionMakeWithDistance(stationLocation, 5*METERS_PER_MILE, 5*METERS_PER_MILE);
    
    MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:stationLocation addressDictionary:nil];
    view.mainMap.centerCoordinate = stationLocation;
    [view.mainMap setDelegate:self];
    [view.mainMap setMapType:MKMapTypeHybrid];
        [view.mainMap addAnnotation:placemark];
        [view.mainMap setRegion:viewRegion animated:YES];

    NSDictionary *titleDict = stationDict[@"cleanedTitle"];
    view.titleLabel.text = titleDict[@"nameHolder"];
    view.titleLabel.alpha = 0.0f;
    view.subTitleLabel.text = titleDict[@"locationHolder"];
    view.subTitleLabel.alpha = 0.0f;
    
    NSDictionary *resultDict;
    for (NSDictionary *loopDict in resultArray) {
        if ([stationDict[@"stationNumber"] isEqualToString:loopDict[@"siteNumber"]]) {
            view.resultLabel.text = loopDict[@"siteValue"];
            resultDict = loopDict;
        }
    }
    
    NSMutableAttributedString *string = [NSMutableAttributedString new];
    view.resultLabel.alpha = 0.0f;
    for (NSDictionary *meanDict in minMaxArray) {
        if ([meanDict[@"siteNumber"] isEqualToString:resultDict[@"siteNumber"]]) {
            if (meanDict[@"missingData"]) {
                //code for missing mean min
                if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                    view.resultLabel.text = @"N/A";
                    [view.resultLabel setTextColor:[UIColor whiteColor]];
                }else{
                    string = [[NSMutableAttributedString alloc] initWithString:@"" attributes:nil];
                    [view.resultLabel setTextColor:[UIColor whiteColor]];
                }
            }else{
                if ([resultDict[@"siteValue"] isEqualToString:@"Ssn"] || [resultDict[@"siteValue"] isEqualToString:@"Dis"] || [resultDict[@"siteValue"] isEqualToString:@"Ice"]) {
                    view.resultLabel.text = @"N/A";
                    [view.resultLabel setTextColor:[UIColor whiteColor]];
                }else{
                    if ([resultDict[@"siteValue"] doubleValue] < [meanDict[@"25Value"] doubleValue] && meanDict[@"25Value"] != [NSNull null]) {
                        string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"low historical average is %@",meanDict[@"meanValue"]]];
                        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.93 green:0.39 blue:0.25 alpha:1.0] range:NSMakeRange(0,3)];
                        [view.resultLabel setTextColor:[UIColor colorWithRed:0.93 green:0.39 blue:0.25 alpha:1.0]];
                        
                    } else if ([resultDict[@"siteValue"] doubleValue] > [meanDict[@"75Value"] doubleValue] && meanDict[@"75Value"] != [NSNull null]) {
                        string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"high historical average is %@",meanDict[@"meanValue"]]];
                        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.15 green:0.58 blue:1.00 alpha:1.0] range:NSMakeRange(0,4)];
                        [view.resultLabel setTextColor:[UIColor colorWithRed:0.15 green:0.58 blue:1.00 alpha:1.0]];
                        
                        
                    }else{
                        string = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"normal historical average is %@",meanDict[@"meanValue"]]];
                        [string addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.42 green:0.91 blue:0.46 alpha:1.0] range:NSMakeRange(0,6)];
                        [view.resultLabel setTextColor:[UIColor colorWithRed:0.42 green:0.91 blue:0.46 alpha:1.0]];
                    }
                }
            }
        }
    }
    
    [view.averageLabel setAttributedText:string];

    if (weatherCacheArray.count>0) {
        
        NSMutableArray *innerArray;
        
        for (NSMutableArray *holderArray in weatherCacheArray) {
            NSDictionary *tempDict = [holderArray firstObject];
            if (![tempDict[@"error"] isEqualToString:@"error occured"]) {
                if ([stationDict[@"stationNumber"] isEqualToString:tempDict[@"stationNumber"]]) {
                    innerArray = holderArray;
                }
            }
        }
        
        if (innerArray.count>0) {
            NSDate *currentDate = [NSDate date];
            NSDateFormatter *df = [[NSDateFormatter alloc] init];
            df.locale = [NSLocale currentLocale];
            [df setDateFormat:@"EEEE"];
            NSString *currentDayString = [df stringFromDate:currentDate];
            BOOL shouldOffset = NO;
            for (int i=0; i<innerArray.count; i++) {
                NSDictionary *weatherDict = innerArray[i];
                if (i==0) {
                    if ([currentDayString isEqualToString:weatherDict[@"dateString"]]) {
                        shouldOffset = YES;
                    }
                }
                NSNumberFormatter *formatter = [[NSNumberFormatter alloc] init];
                [formatter setMaximumFractionDigits:0];
                
                switch (i) {
                    case 0:
                    {
                        if (shouldOffset) {
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            [view.weatherOneResultLabel setAttributedText:hiAttrString];
                            [view.weatherOneImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherOneDateLabel setText:@"Today"];
                        }
                    }
                        break;
                    case 1:
                    {
                        if (shouldOffset) {
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            
                            //switch to attributed string
                            [view.weatherTwoResultLabel setAttributedText:hiAttrString];
                            [view.weatherTwoImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherTwoDateLabel setText:[NSString stringWithFormat:@"%@", weatherDict[@"dateString"]]];
                        }else{
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            
                            [view.weatherOneResultLabel setAttributedText:hiAttrString];
                            [view.weatherOneImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherOneDateLabel setText:@"Today"];
                        }
                    }
                        break;
                    case 2:
                    {
                        if (shouldOffset) {
                            //orig code
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            
                            //switch to attributed string
                            [view.weatherThreeResultLabel setAttributedText:hiAttrString];
                            [view.weatherThreeImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherThreeDateLabel setText:[NSString stringWithFormat:@"%@", weatherDict[@"dateString"]]];
                        }else{
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            
                            //switch to attributed string
                            [view.weatherTwoResultLabel setAttributedText:hiAttrString];
                            [view.weatherTwoImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherTwoDateLabel setText:[NSString stringWithFormat:@"%@", weatherDict[@"dateString"]]];
                        }
                    }
                        break;
                    case 3:
                    {
                        if (!shouldOffset) {
                            NSMutableAttributedString *hiAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@° ", [formatter stringFromNumber:weatherDict[@"highNum"]]]];
                            [hiAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor whiteColor] range:NSMakeRange(0,hiAttrString.length)];
                            
                            NSMutableAttributedString *loAttrString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@°", [formatter stringFromNumber:weatherDict[@"lowNum"]]]];
                            [loAttrString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.67 green:0.67 blue:0.67 alpha:1.0] range:NSMakeRange(0,loAttrString.length)];
                            
                            [hiAttrString appendAttributedString:loAttrString];
                            
                            //switch to attributed string
                            [view.weatherThreeResultLabel setAttributedText:hiAttrString];
                            [view.weatherThreeImageView setImage:[UIImage imageNamed:weatherDict[@"iconString"]]];
                            [view.weatherThreeDateLabel setText:[NSString stringWithFormat:@"%@", weatherDict[@"dateString"]]];
                        }
                    }
                        break;
                    default:
                        break;
                }
            }
        }else{
            [view.weatherOneImageView setImage:[UIImage imageNamed:@"na"]];
            [view.weatherTwoImageView setImage:[UIImage imageNamed:@"na"]];
            [view.weatherThreeImageView setImage:[UIImage imageNamed:@"na"]];
        }
    }

    [UIView beginAnimations:@"fadew1r" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherOneResultLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew1d" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherOneDateLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew1i" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherOneImageView.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew2t" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherTwoResultLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew2i" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherTwoImageView.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew2d" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherTwoDateLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew3r" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherThreeResultLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew3i" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherThreeImageView.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadew3d" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherThreeDateLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadews1" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherSeperatorOne.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadews3" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.weatherSeperatorThree.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadeTitle" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.titleLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadeSubtitle" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.subTitleLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    [UIView beginAnimations:@"fadeResult" context:NULL];
    [UIView setAnimationDuration:1.0];
    view.resultLabel.alpha = 1.0f;
    [UIView commitAnimations];
    
    return view;
}

- (void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    for(MKPinAnnotationView *eachView in views) {
        eachView.pinTintColor = [UIColor colorWithRed:0.15 green:0.56 blue:1.00 alpha:1.0];
    }
}

- (CGSize)swipeViewItemSize:(SwipeView *)swipeView
{
    return self.swipeView.bounds.size;
}

-(void)changePage:(UIPageControl*)control{
    NSLog(@"page clicked %li", (long)control.currentPage);
    [_swipeView scrollToItemAtIndex:control.currentPage duration:0.01f];
}

- (void) backClickedPage:(id)sender{
    NSLog(@"back");
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void) mapClicked:(id)sender{
    if (!mapEnabled) {
        UIView *v = [self.view viewWithTag:1001];
        [v removeFromSuperview];
        
        UIButton *Button = [self.view viewWithTag:1002];
        [Button setImage:[UIImage imageNamed:@"New_Close_Icon"] forState:UIControlStateNormal];
        
        CustomSwipeview *view = [_swipeView itemCustomViewAtIndex:pageControl.currentPage];
        mapEnabled = YES;
        
        view.mainMap.zoomEnabled = YES;
        view.mainMap.scrollEnabled = YES;
        view.mainMap.userInteractionEnabled = YES;
        view.backGroundImage.alpha = 0.95f;
        view.weatherContainerView.hidden = NO;
        view.resultContainerView.hidden = NO;
        view.titleContainerView.hidden = NO;
        pageControl.hidden = NO;
        view.weatherContainerView.alpha =1.0f;
        view.resultContainerView.alpha = 1.0f;
        view.titleContainerView.alpha = 1.0f;
        pageControl.alpha = 1.0f;
        
        [UIView beginAnimations:@"fadeOutMapView" context:NULL];
        [UIView setAnimationDuration:1.0];
        
        view.backGroundImage.alpha = 0.0f;
        view.weatherContainerView.alpha =0.0f;
        view.resultContainerView.alpha = 0.0f;
        view.titleContainerView.alpha = 0.0f;
        pageControl.alpha = 0.0f;
        pageControl.hidden = YES;
        view.weatherContainerView.hidden = YES;
        view.resultContainerView.hidden = YES;
        view.titleContainerView.hidden = YES;
        
        [UIView commitAnimations];
        
    }else{
        backButton = [[UIButton alloc] init];
        [backButton setTag:1001];
        [backButton setBackgroundColor:[UIColor clearColor]];
        [self.view addSubview:backButton];
        [backButton anchorTopLeftWithLeftPadding:0 topPadding:27 width:50 height:50];
        UIImage *backArrow = [UIImage imageNamed:@"BackIcon"];
        [backButton setImage:backArrow forState:UIControlStateNormal];
        [backButton addTarget:self action:@selector(backClickedPage:) forControlEvents:UIControlEventTouchUpInside];
        
        UIButton *Button = [self.view viewWithTag:1002];
        [Button setImage:[UIImage imageNamed:@"GreyMapIcon"] forState:UIControlStateNormal];
        
        CustomSwipeview *view = [_swipeView itemCustomViewAtIndex:pageControl.currentPage];
        
        mapEnabled = NO;
        
        view.mainMap.zoomEnabled = NO;
        view.mainMap.scrollEnabled = NO;
        view.mainMap.userInteractionEnabled = NO;
        view.backGroundImage.alpha = 0.0f;
        view.weatherContainerView.alpha =0.0f;
        view.resultContainerView.alpha = 0.0f;
        view.titleContainerView.alpha = 0.0f;
        pageControl.alpha = 0.0f;
        pageControl.hidden = YES;
        view.weatherContainerView.hidden = YES;
        view.resultContainerView.hidden = YES;
        view.titleContainerView.hidden = YES;
        
        [UIView beginAnimations:@"fadeInMapView" context:NULL];
        [UIView setAnimationDuration:1.0];
        view.backGroundImage.alpha = 0.95f;
        
        view.weatherContainerView.alpha =1.0f;
        view.resultContainerView.alpha = 1.0f;
        view.titleContainerView.alpha = 1.0f;
        pageControl.alpha = 1.0f;
        pageControl.hidden = NO;
        view.weatherContainerView.hidden = NO;
        view.resultContainerView.hidden = NO;
        view.titleContainerView.hidden = NO;
        
        [UIView commitAnimations];
    }
}

- (void)swipeViewDidEndScrollingAnimation:(SwipeView *)swipeView{
    NSLog(@"did end");
    pageControl.currentPage = swipeView.currentPage;
}

- (void)swipeViewCurrentItemIndexDidChange:(SwipeView *)swipeView{
    NSLog(@"did scroll");
    pageControl.currentPage = swipeView.currentPage;
}

@end
