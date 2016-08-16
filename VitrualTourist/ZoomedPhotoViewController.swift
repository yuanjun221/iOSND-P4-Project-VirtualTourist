//
//  ZoomedPhotoViewController.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/15.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit
import CoreData

class ZoomedPhotoViewController: UIViewController {
    
    var photo: Photo!
    var index: Int!
    var fetchedResultsControllerForPhoto: NSFetchedResultsController? {
        didSet {
            fetchedResultsControllerForPhoto?.delegate = self
            executeSearchPhoto()
        }
    }

    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    

    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
}


extension ZoomedPhotoViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let imageData = photo.imageData {
            if let image = UIImage(data: imageData) {
                imageView.image = image
                activityIndicator.stopAnimating()
            }
        } else {
            activityIndicator.startAnimating()
        }
    }
    
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateMinZoomScaleForSize(view.bounds.size)
    }
    
}


extension ZoomedPhotoViewController {
    
    private func updateMinZoomScaleForSize(size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        
        self.scrollView.minimumZoomScale = minScale
        self.scrollView.zoomScale = minScale

    }
    
    private func updateConstraintsForSize(size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset

        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        
        view.layoutIfNeeded()
    }
}


extension ZoomedPhotoViewController: UIScrollViewDelegate {
    
    func viewForZoomingInScrollView(scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(scrollView: UIScrollView) {
        updateConstraintsForSize(view.bounds.size)
    }
}


extension ZoomedPhotoViewController {
    
    func executeSearchPhoto(){
        if let fc = fetchedResultsControllerForPhoto {
            do {
                try fc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: " + error.localizedDescription)
            }
        }
    }
}


extension ZoomedPhotoViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        print(photo)
        if let imageData = photo.imageData {
            if let image = UIImage(data: imageData) {
                imageView.image = image
                activityIndicator.stopAnimating()
            }
        }
    }
}