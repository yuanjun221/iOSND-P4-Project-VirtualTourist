//
//  CoreDataCollectionViewController.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/8.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit
import CoreData


// MARK: - Properties
class CoreDataCollectionViewController: UICollectionViewController {
    
    var fetchedResultsControllerForPhotos: NSFetchedResultsController? {
        didSet {
            fetchedResultsControllerForPhotos?.delegate = self
            executeSearchPhotos()
        }
    }
    
    var fetchedResultsControllerForPin: NSFetchedResultsController? {
        didSet {
            fetchedResultsControllerForPin?.delegate = self
            executeSearchPin()
        }
    }
    
    lazy var coreDataStack: CoreDataStack = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack
    }()
    
    var pin: Pin!
    
    private var blockOperationsForCollectionView: [NSBlockOperation]!
    
    lazy private var activityIndicator: UIActivityIndicatorView = {
        let activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.frame = CGRectMake((self.view.frame.width - 20) / 2, self.view.frame.width * 0.6 + 40, 20, 20)
        self.collectionView!.addSubview(activityIndicator)
        
        return activityIndicator
    }()
    
    lazy private var label: UILabel = {
        let label = UILabel()
        label.frame = CGRectMake(0, self.view.frame.width * 0.6 + 40, self.view.frame.width, 20)
        label.textAlignment = .Center
        label.textColor = UIColor.grayColor()
        label.font = label.font.fontWithSize(14)
        label.alpha = 0
        self.collectionView?.addSubview(label)
        
        return label
    }()
    
    lazy private var retryButton: UIButton = {
        let button = UIButton()
        button.frame = CGRectMake((self.view.frame.width - 66) / 2, self.view.frame.width * 0.6 + 100, 66, 40)
        button.setTitle("Retry", forState: .Normal)
        button.setTitleColor(UIColor.lightGrayColor(), forState: .Normal)
        button.layer.cornerRadius = 4.0
        button.layer.borderColor = UIColor.lightGrayColor().CGColor
        button.layer.borderWidth = 1.0
        self.collectionView?.addSubview(button)
        
        return button
    }()
}


extension CoreDataCollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.showsVerticalScrollIndicator = false
        
        if Bool(pin.fetchPhotosTimedOut!) {
            downloadPhotosModelBackground(WithStack: coreDataStack, ForPin: pin)
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let noPhoto = pin.noPhoto {
            if activityIndicator.isAnimating() {
                activityIndicator.stopAnimating()
            }
            
            if Bool(noPhoto) {
                label.text = "No photos were found at this location."
                UIView.animateWithDuration(0.25) {
                    self.label.alpha = 1
                }
            }
        } else {
            activityIndicator.startAnimating()
        }
    }
}


// MARK: - Subclass responsability
extension CoreDataCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        fatalError("This method MUST be implemented by a subclass of CoreDataTableViewController")
    }
}


// MARK: - Collection View Data Source
extension CoreDataCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if let fetchedResultsController = fetchedResultsControllerForPhotos {
            return fetchedResultsController.sections![section].numberOfObjects;
        } else {
            return 0
        }
    }
}


// MARK: - Fetches
extension CoreDataCollectionViewController {
    
    func executeSearchPhotos(){
        if let fc = fetchedResultsControllerForPhotos {
            do {
                try fc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: " + error.localizedDescription)
            }
        }
    }
    
    func executeSearchPin() {
        if let fc = fetchedResultsControllerForPin {
            do {
                try fc.performFetch()
            } catch let error as NSError {
                print("Error while trying to perform a search: " + error.localizedDescription)
            }
        }
    }
}


// MARK: - Fetched Results Controller Delegate
extension CoreDataCollectionViewController: NSFetchedResultsControllerDelegate {
    
    func controllerWillChangeContent(controller: NSFetchedResultsController) {

        collectionView?.performBatchUpdates({
            if self.activityIndicator.isAnimating() {
                self.activityIndicator.stopAnimating()
            }
            }, completion: nil)
        
        if controller == fetchedResultsControllerForPhotos {
            blockOperationsForCollectionView = []
        }
        
        if controller == fetchedResultsControllerForPin {
            
            if let noPhoto = pin.noPhoto {
                if Bool(noPhoto) {
                    collectionView?.performBatchUpdates({
                        self.label.text = "No photos were found at this location."
                        UIView.animateWithDuration(0.25) {
                            self.label.alpha = 1
                        }
                        }, completion: nil)
                }
            }
            
            if Bool(pin.fetchPhotosTimedOut!) {
                collectionView?.performBatchUpdates({
                    self.label.text = "Fetching photos timed out."
                    self.retryButton.addTarget(self, action: #selector(self.downloadPhotosBackground), forControlEvents: .TouchUpInside)
                    self.retryButton.alpha = 0
                    UIView.animateWithDuration(0.25) {
                        self.label.alpha = 1
                        self.retryButton.alpha = 1
                    }
                    }, completion: {success in
                })
            }
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if controller == fetchedResultsControllerForPhotos {
            switch type {
            case .Insert:
                blockOperationsForCollectionView.append(NSBlockOperation(block: {
                    self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
                }))
                
            default:
                break
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        if controller == fetchedResultsControllerForPhotos {
            collectionView?.performBatchUpdates({
                for operation in self.blockOperationsForCollectionView {
                    operation.start()
                }
                
                }, completion: nil)
        }
    }
}


extension CoreDataCollectionViewController {
    func downloadPhotosBackground() {
        UIView.animateWithDuration(0.25) {
            self.retryButton.alpha = 0
            self.label.alpha = 0
        }
        self.label.text = ""
        downloadPhotosModelBackground(WithStack: coreDataStack, ForPin: pin)
    }
}
