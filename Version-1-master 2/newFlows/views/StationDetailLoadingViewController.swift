//
//  StationDetailLoadingViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import Foundation
import JTMaterialSpinner

class StationDetailLoadingViewController: UIViewController {
    
    // MARK: - Outlets
    
    @IBOutlet var spinnerView: JTMaterialSpinner!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        tabBarController?.tabBar.isHidden = true

        // Customize the line width
        self.spinnerView.circleLayer.lineWidth = 2.0
        
        // Change the color of the line
        self.spinnerView.circleLayer.strokeColor = UIColor.white.cgColor

        spinnerView.beginRefreshing()
    }
    
}
