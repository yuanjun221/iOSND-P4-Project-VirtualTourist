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
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var retryButton: UIButton!
    
    @IBOutlet weak var imageViewTopConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewLeadingConstraint: NSLayoutConstraint!
    @IBOutlet weak var imageViewTrailingConstraint: NSLayoutConstraint!
}


extension ZoomedPhotoViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        retryButton.layer.cornerRadius = 4.0
        retryButton.layer.borderColor = UIColor.lightGrayColor().CGColor
        retryButton.layer.borderWidth = 1.0
        retryButton.alpha = 0
        
        if let title = photo.title {
            titleLabel.layer.shadowColor = UIColor.whiteColor().CGColor
            titleLabel.layer.shadowOffset = CGSizeMake(0, 0)
            titleLabel.layer.shadowRadius = 2.0
            titleLabel.layer.shadowOpacity = 1.0
            titleLabel.text = title
        } else {
            titleLabel.text = nil
        }

        if let imageData = photo.imageData {
            if let image = UIImage(data: imageData) {
                
                let imageSize = image.size
                imageView.bounds.size = imageSize
                
                imageView.image = image
                activityIndicator.stopAnimating()
            }
        } else if Bool(photo.fetchImageDataTimedOut!) {
            retryButton.alpha = 1
        } else {
            activityIndicator.startAnimating()
        }
    }
    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        updateMinZoomScaleForSize(view.bounds.size)
//        centerImageView()
//    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        updateMinZoomScaleForSize(view.bounds.size)
        centerImageView()
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        updateMinZoomScaleForSize(view.bounds.size)
        centerImageView()
        view.layoutIfNeeded()
    }
}


extension ZoomedPhotoViewController {
    @IBAction func retryButtonPressed(sender: AnyObject) {
        performAnimation {
            self.retryButton.alpha = 0
        }
        activityIndicator.startAnimating()
        downloadImageDataForPhoto(photo, completionHandler: nil)
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
    }
    
    private func centerImageView() {
        let bounds = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < bounds.width {
            frameToCenter.origin.x = (bounds.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.height < bounds.height {
            frameToCenter.origin.y = (bounds.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
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
        
        if let imageData = photo.imageData {
            if let image = UIImage(data: imageData) {
                imageView.image = image
                activityIndicator.stopAnimating()
                if retryButton.alpha == 1 {
                    performAnimation {
                        self.retryButton.alpha = 0
                    }
                }
            }
        } else if Bool(photo.fetchImageDataTimedOut!) {
            activityIndicator.stopAnimating()
            performAnimation {
                self.retryButton.alpha = 1
            }
        }
    }
}