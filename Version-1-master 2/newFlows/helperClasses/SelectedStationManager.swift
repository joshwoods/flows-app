//
//  SelectedStationManager.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import Foundation
import ForecastIO

// TODO: - Remove the NSObject when this project is convereted fully to Swift
class StationManager: NSObject {
    
    // MARK: - Properties
    
    let client = DarkSkyClient(apiKey: "5decbd5c3ac3d3dc35a9ae7666dcfa65")
    var selectedStation: NSMutableDictionary? {
        didSet {
            if let latitude = selectedStation?["latTotal"] as? Double {
                self.latitude = latitude
            }
            
            if let longitude = selectedStation?["longTotal"] as? Double {
                self.longitude = longitude
            }
        }
    }
    
    var latitude: Double?
    var longitude: Double?
    var forecast: Forecast?
    
    static let shared = StationManager()
    
    
    func getWeatherForSelectedStation(completionHandler: @escaping (Bool) -> Void) {
        guard let latitude = self.latitude, let longitude = self.longitude else {
            completionHandler(false)
            return
        }
        
        client.getForecast(latitude: latitude, longitude: longitude, extendHourly: false, excludeFields: [.alerts, .flags, .minutely, .hourly]) { (result) in
            switch result {
            case .success(let currentForecast, _):
                guard currentForecast.daily?.data.isEmpty == false else {
                    completionHandler(false)
                    return
                }
                
                self.forecast = currentForecast
                completionHandler(true)
            default:
                completionHandler(false)
            }
        }
    }
    
    private func parse(_ forecast: Forecast) {
        
        
        print(forecast)
    }
    //    NSDictionary *testRespDict = [NSDictionary dictionaryWithDictionary:JSON];
    //
    //    NSDictionary *dailyDict = testRespDict[@"daily"];
    //
    //    NSNumber *offsetNumber = testRespDict[@"offset"];
    //
    //    NSArray *dailyArray = dailyDict[@"data"];
    //
    //    NSMutableArray *intermediateArray = [NSMutableArray new];
    //
    //    for (int i = 0; i < 4; i++){
    //    NSDictionary *innerDict = dailyArray[i];
    //    NSNumber *secondsPerHour = @(3600);
    //    int offsetInSeconds = [offsetNumber intValue] * [secondsPerHour intValue];
    //    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    //
    //    int finalSeconds = [innerDict[@"time"] intValue] + offsetInSeconds;
    //    NSDate *preOffsetDate = [NSDate dateWithTimeIntervalSince1970:[innerDict[@"time"] intValue]];
    //    NSDate *date = [NSDate dateWithTimeIntervalSince1970:finalSeconds];
    //
    //    formatter.locale = [NSLocale currentLocale];
    //    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
    //
    //    NSDateFormatter *df = [[NSDateFormatter alloc] init];
    //    df.locale = [NSLocale currentLocale];
    //    [df setDateFormat:@"EEEE"];
    //
    //    NSString *dateString = [df stringFromDate:preOffsetDate];
    //
    //    NSLog(@"intial %@", [formatter stringFromDate:preOffsetDate]);
    //    NSLog(@"intial %@", [df stringFromDate:preOffsetDate]);
    //    NSLog(@"%@", [formatter stringFromDate:date]);
    //    NSLog(@"%@", [df stringFromDate:date]);
    //
    //    NSNumber *lowNum = innerDict[@"temperatureMin"];
    //    NSNumber *highNum = innerDict[@"temperatureMax"];
    //
    //    NSString *iconString = innerDict[@"icon"];
    //
    //    NSDictionary *weatherDict = [[NSDictionary alloc] initWithObjectsAndKeys:lowNum, @"lowNum", highNum, @"highNum", dateString, @"dateString", iconString, @"iconString", stationDict[@"stationNumber"], @"stationNumber", nil];
    //
    //    [intermediateArray addObject:weatherDict];
    //    }
    //
    //    [weatherDataArray addObject:intermediateArray];
    //    dispatch_group_leave(group);
    //    NSLog(@"test");
    //    } failure:^(NSError *error, id response) {
    //    NSLog(@"Error while retrieving forecast.\n\n%@\n\n%@", error, response);
    //    }];
    //
    //    }
    //
    //    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
    //    // All Requests have finished
    //    [[NSUserDefaults standardUserDefaults] setObject:weatherDataArray forKey:@"weatherArray"];
    //    #pragma mark - TODO refresh
    //    [self.spinnerView endRefreshing];
    //    
    //    [self performSegueWithIdentifier:@"StationDetailSegue" sender:self];
    //    });
    //    }

    
}
