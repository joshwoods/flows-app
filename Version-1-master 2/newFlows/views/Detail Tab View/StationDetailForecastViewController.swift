//
//  StationDetailForecastViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit

class StationDetailForecastViewController: UIViewController {
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDesign()
    }
    
    // MARK: - Private
    
    private func applyDesign() {
        tabBarController?.tabBar.isHidden = false
    }
    
    // MARK: - Actions
    
    @IBAction func exitTapped() {
        dismiss(animated: true, completion: nil)
    }

}
