//
//  StationDetailTabBarViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit

class StationDetailTabBarViewController: UITabBarController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        applyDesign()
    }

    // MARK: - Private
    
    private func applyDesign() {
        tabBar.tintColor = .white
    }
    
}
