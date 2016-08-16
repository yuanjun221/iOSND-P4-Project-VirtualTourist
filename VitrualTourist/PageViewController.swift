//
//  PageViewController.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/16.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit

// MARK: - Properties
class PageViewController: UIPageViewController {

    var photos: [Photo]!
    var currentIndex: Int!
}


// MARK: - View Life Cycle
extension PageViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        
        if let zoomedPhotoViewController = zoomedPhotoViewControllerForPage(currentIndex) {
            setViewControllers([zoomedPhotoViewController], direction: .Forward, animated: false, completion: nil)
        }
    }
}


// MARK: - Page View Controller Data Source
extension PageViewController: UIPageViewControllerDataSource {
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerBeforeViewController viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? ZoomedPhotoViewController {
            var index = viewController.index
            
            guard index != NSNotFound && index != 0 else {
                return nil
            }
            
            index = index - 1
            
            return zoomedPhotoViewControllerForPage(index)
        }
        return nil
    }
    
    func pageViewController(pageViewController: UIPageViewController, viewControllerAfterViewController viewController: UIViewController) -> UIViewController? {
        if let viewController = viewController as? ZoomedPhotoViewController {
            var index = viewController.index
            
            guard index != NSNotFound else {
                return nil
            }
            
            index = index + 1
            
            guard index != photos.count else {
                return nil
            }
            
            return zoomedPhotoViewControllerForPage(index)
        }
        return nil
    }
    
    private func zoomedPhotoViewControllerForPage(index: Int) -> ZoomedPhotoViewController? {
        if let pageVC = storyboard?.instantiateViewControllerWithIdentifier("zoomedPhotoViewController") as? ZoomedPhotoViewController {
            let photo = photos[index]
            pageVC.photo = photo
            pageVC.index = index
            
            let predicate = NSPredicate(format: "self == %@", photo)
            let sortDescriptor = NSSortDescriptor(key: "owner", ascending: true)
            let fetchedResultsControllerForPhoto = fetchedResultsController(entityName: "Photo", predicate: predicate, sortDescriptors: [sortDescriptor])
            pageVC.fetchedResultsControllerForPhoto = fetchedResultsControllerForPhoto
            
            return pageVC
        }
        return nil
    }
}
