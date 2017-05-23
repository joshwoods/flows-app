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
    @IBOutlet weak var temperatureLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        applyDesign()
    }
    
    // MARK: - Private
    
    private func applyDesign() {
        tabBarController?.tabBar.isHidden = false
        tableView.estimatedRowHeight = 100
        tableView.rowHeight = UITableViewAutomaticDimension
        
        if let titleDict = StationManager.shared.selectedStation?["cleanedTitle"] as? [String : String] {
            titleLabel.text = titleDict["nameHolder"]
            subTitleLabel.text = titleDict["locationHolder"]
        }
        else {
            titleLabel.text = ""
            subTitleLabel.text = ""
        }
        
        if let temperature = StationManager.shared.forecast?.currently?.temperature {
            let noDecimalString = String(format: "%.0f°", temperature)
            temperatureLabel.text = noDecimalString
        }
        else {
            temperatureLabel.text = ""
        }
        
        tableView.tableFooterView = UIView()
    }
    
    // MARK: - Actions
    
    @IBAction func exitTapped() {
        dismiss(animated: true, completion: nil)
    }

}

extension StationDetailForecastViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return StationManager.shared.forecast?.daily?.data.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "StationDetailForecastTableViewCell", for: indexPath) as! StationDetailForecastTableViewCell
        cell.configure(with: StationManager.shared.forecast?.daily?.data[indexPath.row])
        return cell
    }
    
}
