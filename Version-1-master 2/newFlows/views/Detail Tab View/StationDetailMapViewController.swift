//
//  StationDetailMapViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit
import MapKit

class StationDetailMapViewController: UIViewController {

    // MARK: - Constants
    
    static let MetersPerMile = 1609.344
    
    // MARK: - Outlets
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subTitleLabel: UILabel!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDesign()
    }
    
    // MARK: - Private
    
    private func applyDesign() {
        tabBarController?.tabBar.isHidden = false
        
        mapView.isZoomEnabled = false
        mapView.isScrollEnabled = false
        mapView.isUserInteractionEnabled = false

        if let latitude = StationManager.shared.latitude, let longitude = StationManager.shared.longitude {
            let stationLocation = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
            let viewRegion = MKCoordinateRegionMakeWithDistance(stationLocation, 5 * StationDetailMapViewController.MetersPerMile, 5 * StationDetailMapViewController.MetersPerMile)
            
            let placemark = MKPlacemark(coordinate: stationLocation, addressDictionary: nil)
            mapView.centerCoordinate = stationLocation
            mapView.addAnnotation(placemark)
            mapView.setRegion(viewRegion, animated: true)
        }
        
        if let titleDict = StationManager.shared.selectedStation?["cleanedTitle"] as? [String : String] {
            titleLabel.text = titleDict["nameHolder"]
            subTitleLabel.text = titleDict["locationHolder"]
        }
        else {
            titleLabel.text = ""
            subTitleLabel.text = ""
        }
    }

    // MARK: - Actions

    @IBAction func exitTapped() {
        dismiss(animated: true, completion: nil)
    }

}
