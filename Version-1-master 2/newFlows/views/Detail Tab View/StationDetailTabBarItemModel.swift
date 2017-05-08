//
//  StationDetailTabBarItemModel.swift
//
//  Copyright © 2017 Matt Riddoch. All rights reserved.
//

import UIKit

public class StationDetailTabBarItemModel: NSObject {
    
    // MARK: - Properties
    
    public var title: String
    private var imageName: String?
    private var selectedImageName: String?
    private var storyboardName: String?
    private var storyboardIdentifier: String?
    
    var image: UIImage? {
        guard let imageName = imageName else { return nil }
        
        return UIImage(named: imageName)?.withRenderingMode(.alwaysOriginal)
    }
    
    var selectedImage: UIImage? {
        guard let selectedImageName = selectedImageName else { return nil }
        
        return UIImage(named: selectedImageName)?.withRenderingMode(.alwaysOriginal)
    }
    
    var viewController: UIViewController? {
        guard let storyboardName = self.storyboardName else { return nil }
        
        let storyboard = UIStoryboard(name: storyboardName, bundle: nil)
        
        if let storyboardIdentifier = self.storyboardIdentifier {
            return storyboard.instantiateViewController(withIdentifier: storyboardIdentifier)
        }
        
        return storyboard.instantiateInitialViewController()
    }
    
    // MARK: - Initialization
    
    public init(title: String, imageName: String?, selectedImageName: String?, storyboardName: String?, storyboardIdentifier: String?) {
        self.title = title
        self.imageName = imageName
        self.selectedImageName = selectedImageName
        self.storyboardName = storyboardName
        self.storyboardIdentifier = storyboardIdentifier
    }
    
}
