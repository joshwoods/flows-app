//
//  StationDetailGraphViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit

class StationDetailGraphViewController: UIViewController {

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        applyDesign()
    }

    // MARK: - Private
    
    private func applyDesign() {
        self.tabBarController?.navigationController?.navigationBar.shadowImage = UIImage()
        self.tabBarController?.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.tabBarController?.navigationController?.navigationBar.isTranslucent = true
    }
    
    // MARK: - Actions
    
    @IBAction func exitTapped() {
        dismiss(animated: true, completion: nil)
    }
    
}
