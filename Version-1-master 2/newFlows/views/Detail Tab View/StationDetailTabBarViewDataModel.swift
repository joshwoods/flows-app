//
//  StationDetailTabBarViewDataModel.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import Foundation

class StationDetailTabBarViewDataModel {
    
    var dataSource = [StationDetailTabBarItemModel]()

    init() {
        let loadingModel = StationDetailTabBarItemModel(title: "", imageName: "", selectedImageName: "", storyboardName: "Main", storyboardIdentifier: "StationDetailLoadingViewController")
        dataSource = [loadingModel]
    }
    
    public func update() {
        dataSource.removeAll()
        
        let graphModel = StationDetailTabBarItemModel(title: "", imageName: "graph_inactive", selectedImageName: "graph_active", storyboardName: "Main", storyboardIdentifier: "StationDetailGraphViewController")
        let forecastModel = StationDetailTabBarItemModel(title: "", imageName: "weather_inactive", selectedImageName: "weather_active", storyboardName: "Main", storyboardIdentifier: "StationDetailForecastViewController")
        let mapModel = StationDetailTabBarItemModel(title: "", imageName: "map_inactive", selectedImageName: "map_active", storyboardName: "Main", storyboardIdentifier: "StationDetailMapViewController")
        dataSource = [graphModel, forecastModel, mapModel]
    }
    
}
