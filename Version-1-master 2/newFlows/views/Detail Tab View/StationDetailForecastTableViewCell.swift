//
//  StationDetailForecastTableViewCell.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit
import ForecastIO

class StationDetailForecastTableViewCell: UITableViewCell {

    // MARK: - Outlets
    
    @IBOutlet weak var dateLabel: UILabel!
    @IBOutlet weak var highLabel: UILabel!
    @IBOutlet weak var lowLabel: UILabel!
    @IBOutlet weak var weatherImageView: UIImageView!
    
    // MARK: - Lifecycle
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        applyDesign()
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        dateLabel.text = nil
        highLabel.text = nil
        lowLabel.text = nil
        weatherImageView.image = nil
    }
    
    // MARK: - Public
    
    public func configure(with dataPoint: DataPoint?) {
        guard let dataPoint = dataPoint else { return }
        
        if let icon = dataPoint.icon {
            switch icon {
            case .clearDay:
                weatherImageView.image = #imageLiteral(resourceName: "clear-day")
                
            case .clearNight:
                weatherImageView.image = #imageLiteral(resourceName: "clear-night")
                
            case .rain:
                weatherImageView.image = #imageLiteral(resourceName: "rain")
                
            case .snow:
                weatherImageView.image = #imageLiteral(resourceName: "snow")
                
            case .sleet:
                weatherImageView.image = #imageLiteral(resourceName: "sleet")
                
            case .wind:
                weatherImageView.image = #imageLiteral(resourceName: "wind")
                
            case .fog:
                weatherImageView.image = #imageLiteral(resourceName: "fog")
                
            case .cloudy:
                weatherImageView.image = #imageLiteral(resourceName: "cloudy")
                
            case .partlyCloudyDay:
                weatherImageView.image = #imageLiteral(resourceName: "partly-cloudy-day")
                
            case .partlyCloudyNight:
                weatherImageView.image = #imageLiteral(resourceName: "partly-cloudy-night")
                
            }
        }
        
        if let max = dataPoint.temperatureMax {
            highLabel.text = String(format: "%.0f°", max)
        }

        if let min = dataPoint.temperatureMin {
            lowLabel.text = String(format: "%.0f°", min)
        }
        
        if Calendar.current.isDateInToday(dataPoint.time) == true {
            dateLabel.text = "Today"
        }
        else {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "EEEE"
            dateLabel.text = dateFormatter.string(from: dataPoint.time)
        }
    }
    
    // MARK: - Private
    
    private func applyDesign() {
        dateLabel.textColor = .lightGray
        lowLabel.textColor = .lightGray
        highLabel.textColor = .white
        weatherImageView.image = #imageLiteral(resourceName: "na")
    }

}
