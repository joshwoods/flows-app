//
//  AppDelegate.m
//
//  Copyright © 2015 Matt Riddoch. All rights reserved.
//

#import "AppDelegate.h"
#import <PromiseKit/PromiseKit.h>
#import "Reachability.h"
#import "FLminMaxFlows.h"
#import <CoreLocation/CoreLocation.h>
#import "UIColor+Hexadecimal.h"

@interface AppDelegate ()

@property (strong, nonatomic) NSMutableArray *resultArray;
@property (strong, nonatomic) NSMutableArray *minMaxArray;
@property (strong, nonatomic) NSMutableArray *testlocationArray;
@property (strong, nonatomic) NSString *detailData;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [self applyAppearance];
    
    self.selectedStationArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedStationArray"] mutableCopy];
    
    self.minMaxArray = [NSMutableArray new];
    
    Reachability* reach = [Reachability reachabilityWithHostname:@"www.apple.com"];
    
    // Set the blocks
    reach.reachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"reachable"];
        });
    };
    
    reach.unreachableBlock = ^(Reachability*reach)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [[NSUserDefaults standardUserDefaults] setBool:NO forKey:@"reachable"];
        });
    };
    
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    if (self.selectedStationArray.count > 0) {
        NSDate *lastUSGSupdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUSGSupdateDate"];
        NSTimeInterval secondsSinceUpdateInterval = [lastUSGSupdateDate timeIntervalSinceNow];
        int minutesSinceUpdateInterval = secondsSinceUpdateInterval*-1/60;
        if (minutesSinceUpdateInterval > 30) {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"shouldUpdate"];
        } else {
            [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"shouldUpdate"];
        }
    }
}

- (void)applyAppearance {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[UINavigationBar appearance] setTitleTextAttributes: [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [UIColor colorWithRed:255.0/255.0 green:255.0/255.0 blue:255.0/255.0 alpha:1.0], NSForegroundColorAttributeName,
                                                           [UIFont fontWithName:@"HelveticaNeue-Thin" size:20.0f], NSFontAttributeName, nil]];

    NSDictionary *barButtonAppearanceDict = @{NSFontAttributeName : [UIFont fontWithName:@"HelveticaNeue-Thin" size:17.0], NSForegroundColorAttributeName: [UIColor colorWithHex:@"ACACAC"]};
    [[UIBarButtonItem appearance] setTitleTextAttributes:barButtonAppearanceDict forState:UIControlStateNormal];
    [[UIBarButtonItem appearance] setTintColor:[UIColor colorWithHex:@"ACACAC"]];
    
    [[UINavigationBar appearance] setShadowImage:[UIImage new]];
    [[UINavigationBar appearance] setBackgroundImage:[UIImage new] forBarMetrics:UIBarMetricsDefault];
}

#pragma mark - data pull
-(void)refreshData {
    dispatch_promise(^{
        return [self urlStringfromStations:self.selectedStationArray];
    }).then(^(NSString *md5){
        //example from USGS
        
        //http://waterservices.usgs.gov/nwis/iv/
        //?format=rdb
        //&sites=06006000,06012500,06016000,06017000,06018500
        //&period=P1D
        //&modifiedSince=PT30M
        //&parameterCd=00060
        
        NSDate *lastUSGSupdateDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastUSGSupdateDate"];
        NSTimeInterval secondsSinceUpdateInterval = [lastUSGSupdateDate timeIntervalSinceNow];
        int minutesSinceUpdateInterval = secondsSinceUpdateInterval*-1/60;
        
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUSGSupdateDate"];
        return [NSURLConnection GET:[NSString stringWithFormat:@"https://waterservices.usgs.gov/nwis/iv/?format=rdb&modifiedSince=PT%iM&sites=%@&parameterCd=00060", minutesSinceUpdateInterval, md5]];
    }).then(^(NSString *returnData){
        return [self currentDataPull:returnData isFirstPull:NO];
        
    }).then(^(NSMutableArray *responseArray){
        dispatch_async(dispatch_get_main_queue(),^{
            [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshSpinNotification" object:self];
        });
    });
}

- (void)runLiveUpdate {
    self.selectedStationArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"selectedStationArray"] mutableCopy];
    if (self.selectedStationArray.count > 0) {
#pragma mark - TODO refresh
        dispatch_promise(^{
            return [self urlStringfromStations:self.selectedStationArray];
        }).then(^(NSString *md5){
            [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"lastUSGSupdateDate"];
            return [NSURLConnection GET:[NSString stringWithFormat:@"https://waterservices.usgs.gov/nwis/iv/?format=rdb&sites=%@&parameterCd=00060", md5]];
        }).then(^(NSString *returnData){
            return [self currentDataPull:returnData isFirstPull:YES];
        }).then(^(NSMutableArray *returnArray){
            BOOL selectedStationUpdated = [[NSUserDefaults standardUserDefaults] boolForKey:@"selectedStationUpdated"];
            
            NSDate *savedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"updatedDate"];
            
            NSDate *todaysDate = [NSDate date];
            NSCalendar *gregorian = [NSCalendar currentCalendar];
            NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
            [dateComponents setYear:1];
            NSDate *targetDate = [gregorian dateByAddingComponents:dateComponents toDate:todaysDate options:0];
            
            if ([savedDate compare:targetDate] == NSOrderedDescending || selectedStationUpdated) {
                //web pull
                //Add station ID pull here
                dispatch_promise(^{
                    //pull station ID here!!
                    NSLog(@"stationtest");
                }).then(^{
                    return [self urlStringfromStations:self.selectedStationArray];
                }).then(^(NSString *md5){
                    return [NSURLConnection GET:[NSString stringWithFormat:@"https://waterdata.usgs.gov/nwis/dvstat/?site_no=%@&format=rdb&submitted_form=parameter_selection_list&PARAmeter_cd=00060", md5]];
                }).then(^(NSString *returnData){
                    [self fetchedFlowData:returnData];
                    return [self urlStringfromStations:self.selectedStationArray];
                }).then(^(NSString *md5){
                    return [NSURLConnection GET:[NSString stringWithFormat:@"https://waterdata.usgs.gov/nwis/inventory?agency_code=USGS&site_no=%@&format=rdb", md5]];
                }).then(^(NSString *responseString){
                    return [self detailDataPull:responseString];
                }).then(^(NSMutableArray *responseArray){
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:@"selectedStationUpdated"];
                    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:@"pullNewWeather"];
                    dispatch_async(dispatch_get_main_queue(),^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"LiveUpdateNotification" object:self];
                    });
                });
            } else {
                //local pull
                dispatch_promise(^{
                    NSString* flowData = [[NSUserDefaults standardUserDefaults] objectForKey:@"minMaxData"];
                    return [self fetchedFlowData:flowData];
                }).then(^(NSString *responseString){
                    dispatch_async(dispatch_get_main_queue(),^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:@"RefreshSpinNotification" object:self];
                    });
                });
            }
        });
    }
}

- (NSString*)urlStringfromStations:(NSMutableArray*)incomingStations {
    NSString *tempHolderString = [NSString new];
    for (int i = 0;i < self.selectedStationArray.count; i++) {
        NSMutableDictionary *tempDict = self.selectedStationArray[i];
        NSString *tempString = tempDict[@"stationNumber"];
        if (i < self.selectedStationArray.count-1) {
            NSString *commaString = [NSString stringWithFormat:@"%@,", tempString];
            tempHolderString = [NSString stringWithFormat:@"%@%@", tempHolderString, commaString];
        }else if(self.selectedStationArray.count == 1){
            tempHolderString = [NSString stringWithFormat:@"%@%@", tempHolderString, tempString];
        }else{
            tempHolderString = [NSString stringWithFormat:@"%@%@", tempHolderString, tempString];
        }
    }
    
    return tempHolderString;
}

#pragma mark - pull data

- (NSMutableArray*)currentDataPull:(NSString *)responseHolder isFirstPull:(BOOL)firstPull{
    self.resultArray = [[[NSUserDefaults standardUserDefaults] objectForKey:@"resultArray"] mutableCopy];
    
    if (self.resultArray.count == 0 || firstPull) {
        self.resultArray = [NSMutableArray new];
    }
    
    NSArray *components = [responseHolder componentsSeparatedByString:@"\n"];
    NSMutableArray *workingDataArray = [[NSMutableArray alloc] initWithArray:components];
    for (int i=0; i<workingDataArray.count; i++) {
        NSString *matchCriteria = @"USGS";
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", matchCriteria];
        BOOL filePathMatches = [pred evaluateWithObject:[workingDataArray objectAtIndex:i]];
        
        if (filePathMatches) {
            NSArray *tempHolderArray = [[workingDataArray objectAtIndex:i] componentsSeparatedByString:@"\t"];
            //NSLog(@"object: %@", tempHolderArray);
            NSDictionary *tempHolder = [[NSDictionary alloc] initWithObjectsAndKeys:[tempHolderArray objectAtIndex:1], @"siteNumber", [tempHolderArray objectAtIndex:4], @"siteValue", [tempHolderArray objectAtIndex:3], @"timeZone", [tempHolderArray objectAtIndex:2], @"timeStamp", nil];
            
            if (firstPull) {
                [self.resultArray addObject:tempHolder];
            } else {
                for (int i=0; i < self.resultArray.count; i++) {
                    NSDictionary *dictionaryToReplace = self.resultArray[i];
                    if ([tempHolder[@"siteNumber"] isEqualToString:dictionaryToReplace[@"siteNumber"]]) {
                        [self.resultArray replaceObjectAtIndex:i withObject:tempHolder];
                    }
                }
            }
        }
    }
    
    NSDate *date = [NSDate date];
    NSDateFormatter *dateFormatter = [NSDateFormatter new];
    dateFormatter.dateFormat = @"hh:mm a";
    NSString *updateString = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
    [[NSUserDefaults standardUserDefaults] setObject:updateString forKey:@"updateString"];
#pragma mark - TODO update time string
    // _updateString = [NSString stringWithFormat:@"%@", [dateFormatter stringFromDate:date]];
    
    [[NSUserDefaults standardUserDefaults] setObject:self.resultArray forKey:@"resultArray"];
    
    return self.resultArray;
}

- (NSMutableArray*)detailDataPull:(NSString *)responseHolder {
    
    [[NSUserDefaults standardUserDefaults] setObject:responseHolder forKey:@"gpsData"];
    NSArray *components = [responseHolder componentsSeparatedByString:@"\n"];
    NSMutableArray *returnArray = [NSMutableArray arrayWithArray:components];
    self.detailData = responseHolder;
    [[NSUserDefaults standardUserDefaults] setObject:self.detailData forKey:@"detailData"];
    [self pullGeoLocationForTest];
    
    return returnArray;
}

#pragma mark - min max data pull

- (NSMutableArray*)fetchedFlowData:(NSString *)responseHolder {
    
    [[NSUserDefaults standardUserDefaults] setObject:responseHolder forKey:@"minMaxData"];
    NSDate *todaysDate = [NSDate date];
    [[NSUserDefaults standardUserDefaults] setObject:todaysDate forKey:@"updatedDate"];
    NSArray *components = [responseHolder componentsSeparatedByString:@"\n"];
    NSMutableArray *workingDataArray = [[NSMutableArray alloc] initWithArray:components];
    NSMutableArray *cleanedHolderArray = [[NSMutableArray alloc] init];
    NSMutableArray *objectHolderArray = [[NSMutableArray alloc] init];
    for (int i=0; i<workingDataArray.count; i++) {
        NSString *matchCriteria = @"USGS";
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", matchCriteria];
        BOOL filePathMatches = [pred evaluateWithObject:[workingDataArray objectAtIndex:i]];
        if (filePathMatches) {
            
            NSArray *tempHolderArray = [[workingDataArray objectAtIndex:i] componentsSeparatedByString:@"\t"];
            
            FLminMaxFlows *flowHolder = [[FLminMaxFlows alloc] init];
            
            flowHolder.agencyCd = [tempHolderArray objectAtIndex:0];
            flowHolder.siteNum = [tempHolderArray objectAtIndex:1];
            flowHolder.paramaterCd = [tempHolderArray objectAtIndex:2];
            flowHolder.monthNu = [tempHolderArray objectAtIndex:4];
            flowHolder.dayNu = [tempHolderArray objectAtIndex:5];
            flowHolder.meanVa = [tempHolderArray objectAtIndex:13];
            flowHolder.p25Va = [tempHolderArray objectAtIndex:17];
            flowHolder.p75Va = [tempHolderArray objectAtIndex:19];
            
            [objectHolderArray addObject:flowHolder];
            
            flowHolder = nil;
            
            [cleanedHolderArray addObject:tempHolderArray];
        }
    }
    
    NSDate *currentDate = [NSDate date];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* dateComp = [calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:currentDate]; // Get necessary date components
    
    NSInteger month = [dateComp month]; //gives you month
    NSInteger day = [dateComp day]; //gives you day
    
    int foundValue = -1;
    NSString *siteNumberString;
    for (FLminMaxFlows *temp in objectHolderArray) {
        if (siteNumberString.length==0) {
            siteNumberString = temp.siteNum;
        }
        if ([temp.monthNu isEqualToString:[NSString stringWithFormat:@"%li", (long)month]]) {
            if ([temp.dayNu isEqualToString:[NSString stringWithFormat:@"%li", (long)day]]) {
                
                NSDictionary *holderDict = [[NSDictionary alloc] initWithObjectsAndKeys:temp.meanVa, @"meanValue", temp.p25Va, @"25Value", temp.p75Va, @"75Value", temp.siteNum, @"siteNumber", nil];
                [self.minMaxArray addObject:holderDict];
                foundValue = 1;
            }
        }
    }
    
    if (foundValue==-1) {
        NSDictionary *holderDict = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithBool:YES], @"missingData", siteNumberString, @"siteNumber", nil];
        [self.minMaxArray addObject:holderDict];
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:self.minMaxArray forKey:@"minMaxArray"];
    
    return self.minMaxArray;
}

-(void)pullGeoLocationForTest {
    NSArray *components = [self.detailData componentsSeparatedByString:@"\n"];
    NSMutableArray *workingArray = [[NSMutableArray alloc] initWithArray:components];
    NSMutableArray *stationArray = [NSMutableArray new];
    
    for (int i=0; i<workingArray.count; i++) {
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"self BEGINSWITH %@", @"USGS"];
        BOOL filePathMatches = [pred evaluateWithObject:[workingArray objectAtIndex:i]];
        if (filePathMatches) {
            NSArray *tempHolderArray = [[workingArray objectAtIndex:i] componentsSeparatedByString:@"\t"];
            [stationArray addObject:tempHolderArray];
        }
    }
    
    self.testlocationArray = [NSMutableArray new];
    
    for (int i=0; i<stationArray.count; i++) {
        NSArray *tempHolderArray = stationArray[i];
        
        NSString *tempStationNumber = tempHolderArray[1];
        NSString *latString = tempHolderArray[6];
        NSString *longString = tempHolderArray[7];
        
        NSString *endOneLatString;
        NSString *endTwoLatString;
        
        NSString *endOneLongString;
        NSString *endTwoLongString;
        
        NSCharacterSet *latcset = [NSCharacterSet characterSetWithCharactersInString:@"."];
        NSRange latrange = [latString rangeOfCharacterFromSet:latcset];
        if (latrange.location == NSNotFound) {
            // no ( or ) in the string
        } else {
            NSRange latRange = [latString rangeOfString:@"."];
            latString = [latString substringToIndex:latRange.location];
        }
        
        NSCharacterSet *longcset = [NSCharacterSet characterSetWithCharactersInString:@"."];
        NSRange longrange = [longString rangeOfCharacterFromSet:longcset];
        if (longrange.location == NSNotFound) {
            // no ( or ) in the string
        } else {
            NSRange longRange = [longString rangeOfString:@"."];
            longString = [longString substringToIndex:longRange.location];
        }
        
        endOneLatString = [latString substringToIndex:[latString length] - 4];
        endOneLongString = [longString substringToIndex:[longString length] - 4];
        endTwoLatString = [latString substringFromIndex:[latString length] - 4];
        endTwoLongString = [longString substringFromIndex:[longString length] - 4];
        
        NSString *longSec = [endTwoLongString substringFromIndex:[endTwoLongString length] - 2];
        NSString *longMin = [endTwoLongString substringToIndex:[endTwoLongString length] - 2];
        double longMinutes = [longMin doubleValue] / 60;
        double longSeconds = [longSec doubleValue] / 3600;
        double longTotal = [endOneLongString doubleValue] + longMinutes + longSeconds;
        longTotal = -longTotal;
        NSString *latSec = [endTwoLatString substringFromIndex:[endTwoLatString length] - 2];
        NSString *latMin = [endTwoLatString substringToIndex:[endTwoLatString length] - 2];
        double latMinutes = [latMin doubleValue] / 60;
        double LatSeconds = [latSec doubleValue] / 3600;
        double latTotal = [endOneLatString doubleValue] + latMinutes + LatSeconds;
        
        for (int i=0; i < self.selectedStationArray.count; i++) {
            NSMutableDictionary *stationDict = [self.selectedStationArray[i] mutableCopy];
            if ([stationDict[@"stationNumber"] isEqualToString:tempStationNumber]) {
                [stationDict setObject:[NSNumber numberWithDouble:longTotal] forKey:@"longTotal"];
                [stationDict setObject:[NSNumber numberWithDouble:latTotal] forKey:@"latTotal"];
#pragma mark - TODO test for nil weatherInfo station data
                [self.selectedStationArray replaceObjectAtIndex:i withObject:stationDict];
                [[NSUserDefaults standardUserDefaults] setObject:self.selectedStationArray forKey:@"selectedStationArray"];
            }
        }
    }
}

@end
