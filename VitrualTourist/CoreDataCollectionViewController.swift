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
    
    var pin: Pin!
    
    private var blockOperationsForCollectionView: [NSBlockOperation]!
    private var activityIndicator: UIActivityIndicatorView!
    private var label: UILabel!
}


extension CoreDataCollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.showsVerticalScrollIndicator = false
        
        activityIndicator = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        activityIndicator.frame = CGRectMake((view.frame.width - 20) / 2, (view.frame.width * 0.6) + 20, 20, 20)
        collectionView!.addSubview(activityIndicator)
        
        label = UILabel()
        label.frame = CGRectMake(0, (view.frame.width * 0.6) + 20, view.frame.width, 20)
        label.textAlignment = .Center
        label.textColor = UIColor.grayColor()
        label.text = "No photos were found."
        label.alpha = 0
        collectionView?.addSubview(label)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)

        if let noPhoto = pin.noPhoto {
            if activityIndicator.isAnimating() {
                activityIndicator.stopAnimating()
            }
            
            if Bool(noPhoto) {
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
                        UIView.animateWithDuration(0.25) {
                            self.label.alpha = 1
                        }
                        }, completion: nil)
                }
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
