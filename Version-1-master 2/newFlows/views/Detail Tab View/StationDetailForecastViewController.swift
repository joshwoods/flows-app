//
//  StationDetailForecastViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit

class StationDetailForecastViewController: UIViewController {

    // MARK: - Outlets
    
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
