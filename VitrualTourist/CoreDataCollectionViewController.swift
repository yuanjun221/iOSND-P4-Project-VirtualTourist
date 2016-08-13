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
    
    lazy private var refreshControl: UIRefreshControl = {
        let refreshControl = UIRefreshControl()
        self.collectionView?.addSubview(refreshControl)
        return refreshControl
    }()
    
    var newAlbumButton: UIButton?
    
}


// MARK: - View Life Cycle
extension CoreDataCollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(pin)
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.showsVerticalScrollIndicator = false
        
        refreshControl.addTarget(self, action: #selector(downloadPhotos), forControlEvents: .ValueChanged)
        
        if Bool(pin.fetchPhotosTimedOut!) {
            downloadPhotos()
        }
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if let noPhoto = pin.noPhoto {
            if Bool(noPhoto) {
                activityIndicator.stopAnimating()
                newAlbumButton?.alpha = 0
                self.refreshControl.endRefreshing()
                refreshControl.removeFromSuperview()
                label.text = "No photos were found at this location."
                performAnimation {
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

        if controller == fetchedResultsControllerForPhotos {
    
            blockOperationsForCollectionView = []

        }
        
        if controller == fetchedResultsControllerForPin {
            
            if let noPhoto = pin.noPhoto {
                
                // getPhotosModel returned no photo result: stop indicator animating, hide newAlbum button, remove refreshControl, configure label
                if Bool(noPhoto) {
                    
                    collectionView?.performBatchUpdates(nil) { success in
                        
                        self.activityIndicator.stopAnimating()
                        
                        self.newAlbumButton?.alpha = 0
                        
                        self.refreshControl.endRefreshing()
                        self.refreshControl.removeFromSuperview()
                        
                        self.label.text = "No photos were found at this location."
                        self.label.alpha = 0
                        
                        performAnimation {
                            self.label.alpha = 1
                        }
                    }
                    return
                }
                
                // After delete current photos: start indicator animating and disable all other UI elements.
                if pin.photos?.count == 0 && !Bool(noPhoto) && !Bool(pin.fetchPhotosTimedOut!) {
                    
                    collectionView?.performBatchUpdates(nil) { success in
                        self.activityIndicator.startAnimating()
                        
                        self.newAlbumButton?.alpha = 0
                        self.label.alpha = 0
                        self.label.text = ""
                        self.retryButton.alpha = 0
                        self.refreshControl.endRefreshing()
                        self.refreshControl.removeFromSuperview()
                    }
                    return
                }
            }
            
            // getPhotosModel timed out: stop indicator animating, hide newAlbum button, add refreshControl, configure label, add retryButton, enable refreshControl.
            if Bool(pin.fetchPhotosTimedOut!) {

                collectionView?.performBatchUpdates(nil) { success in
                    
                    self.activityIndicator.stopAnimating()
                    
                    self.newAlbumButton?.alpha = 0
                    
                    self.label.text = "Fetching photos timed out."
                    self.label.alpha = 0
                    
                    self.retryButton.addTarget(self, action: #selector(self.downloadPhotos), forControlEvents: .TouchUpInside)
                    self.retryButton.alpha = 0
                    

                    self.collectionView?.addSubview(self.refreshControl)
                    
                    performAnimation {
                        self.label.alpha = 1
                        self.retryButton.alpha = 1
                    }
                }
                return
            }
            
            // getPhotosModel returned normal state (often from previous getPhotosModel timed out state):
            // stop indicator animating, diable all UI elements except refreshControl and newAlbumButton.
            collectionView?.performBatchUpdates(nil) { success in
                
                self.activityIndicator.stopAnimating()
                
                self.label.alpha = 0
                self.label.text = ""
                
                self.retryButton.alpha = 0

                awakeUIAfterSeconds(1) {
                    self.collectionView?.addSubview(self.refreshControl)
                    performAnimation {
                        self.newAlbumButton?.alpha = 1
                    }
                }
            }
        
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if controller == fetchedResultsControllerForPhotos {
            switch type {
            case .Insert:
                let blockOperation = NSBlockOperation {
                    self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
                }
                blockOperationsForCollectionView.append(blockOperation)
                
            case .Delete:
                let blockOperation = NSBlockOperation {
                    self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
                }
                blockOperationsForCollectionView.append(blockOperation)
                
            case .Update:
                let blockOperation = NSBlockOperation {
                    self.collectionView?.reloadItemsAtIndexPaths([indexPath!])
                }
                blockOperationsForCollectionView.append(blockOperation)
            
                
            case .Move:
                let blockOperationToDelete = NSBlockOperation {
                    self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
                }
                let blockOperationToInsert = NSBlockOperation {
                    self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
                }
                blockOperationsForCollectionView.append(blockOperationToDelete)
                blockOperationsForCollectionView.append(blockOperationToInsert)
            

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
}


extension CoreDataCollectionViewController {
    func downloadPhotos() {
        
        activityIndicator.startAnimating()
        retryButton.alpha = 0
        label.alpha = 0
        newAlbumButton?.alpha = 0
        self.refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
        label.text = ""
        
        deleteCurrentPhotos()

        downloadPhotosBackground(WithStack: coreDataStack, ForPin: pin)
    }
    
    func deleteCurrentPhotos() {
        if let photos = pin.photos {
            if photos.count > 0 {
                for photo in photos {
                    let photo = photo as! Photo
                    coreDataStack.context.deleteObject(photo)
                }
            }
            coreDataStack.context.processPendingChanges()
        }
    }
}
