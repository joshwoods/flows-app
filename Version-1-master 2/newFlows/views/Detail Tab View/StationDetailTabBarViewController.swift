//
//  StationDetailTabBarViewController.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit


class StationDetailTabBarViewController: UITabBarController {

    // MARK: - Properties

    let model = StationDetailTabBarViewDataModel()
    private var tabBarViewControllers = [UIViewController]()

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        applyDesign()
        
        StationManager.shared.getWeatherForSelectedStation { [weak self] (success) in
            DispatchQueue.main.async {
                guard let weakSelf = self else { return }
                if success == true {
                    weakSelf.model.update()
                    weakSelf.setupTabBar()
                }
                else {
                    weakSelf.presentErrorAlert()
                }
            }
        }
    }
    
    private func configureTabBarModel(_ model: StationDetailTabBarItemModel) {
        guard let viewController = model.viewController else { return }
        let tabBarItem = UITabBarItem(title: model.title, image: model.image, selectedImage: model.selectedImage)
        viewController.tabBarItem = tabBarItem
        tabBarViewControllers.append(viewController)
    }

    // MARK: - Private
    
    private func applyDesign() {
        tabBar.tintColor = .white
        setupTabBar()
    }
    
    private func setupTabBar() {
        tabBarViewControllers.removeAll()
        
        tabBar.isHidden = model.dataSource.count > 1 ? false : true
        
        for model in model.dataSource {
            configureTabBarModel(model)
        }
        
        setViewControllers(tabBarViewControllers, animated: false)
    }
    
    private func presentErrorAlert() {
        let alert = UIAlertController(title: "Error!", message: "There seems to have been an issue loading the data you requested. Please try again!", preferredStyle: .alert)
        let okay = UIAlertAction(title: "Okay", style: .default) { (_) in
            self.dismiss(animated: true, completion: nil)
        }
        alert.addAction(okay)
        present(alert, animated: true, completion: nil)
    }
}
