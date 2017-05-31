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
        
        client.getForecast(latitude: latitude, longitude: longitude, extendHourly: false, excludeFields: [.alerts, .flags, .minutely, .hourly]) { [weak self] (result) in
            guard let weakSelf = self else { return }
            switch result {
            case .success(let currentForecast, _):
                guard currentForecast.daily?.data.isEmpty == false else {
                    completionHandler(false)
                    return
                }
                
                weakSelf.forecast = currentForecast
                completionHandler(true)
            default:
                completionHandler(false)
            }
        }
    }
        
}
