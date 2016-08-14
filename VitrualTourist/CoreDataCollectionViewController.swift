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
    
    private var blockOperations = [NSBlockOperation]()
    
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
                updateUIForNoPhoto()
            }
        } else {
            activityIndicator.startAnimating()
        }
    }
}


// MARK: - Collection View Data Source
extension CoreDataCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        fatalError("This method MUST be implemented by a subclass of CoreDataTableViewController")
    }
    
    override func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if let count = fetchedResultsControllerForPhotos!.sections?[section].numberOfObjects {
            return count
        }
        return 0
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
        
        if controller == fetchedResultsControllerForPin {
            
            if let noPhoto = pin.noPhoto {
                
                // getPhotosModel returned no photo result
                if Bool(noPhoto) {
                    
                    collectionView?.performBatchUpdates(nil) { success in
                        self.updateUIForNoPhoto()
                    }
                    return
                }
                
                // After delete current photos
                if fetchedResultsControllerForPhotos!.sections?[0].numberOfObjects == 0 && !Bool(noPhoto) && !Bool(pin.fetchPhotosTimedOut!) {
                    
                    collectionView?.performBatchUpdates(nil) { success in
                        self.updateUIForDeletePhotos()
                    }
                    return
                }
            }
            
            // getPhotosModel timed out
            if Bool(pin.fetchPhotosTimedOut!) {

                collectionView?.performBatchUpdates(nil) { success in
                    self.updateUIForFetchPhotosTimedOut()
                }
                return
            }
            
            // getPhotosModel new album fetched
            collectionView?.performBatchUpdates(nil) { success in
                self.updateUIForNewAlbumFetched()
            }
        
        }
    }
    
    func controller(controller: NSFetchedResultsController, didChangeObject anObject: AnyObject, atIndexPath indexPath: NSIndexPath?, forChangeType type: NSFetchedResultsChangeType, newIndexPath: NSIndexPath?) {
        
        if controller == fetchedResultsControllerForPhotos {
            switch type {
            case .Insert:
                blockOperations.append(NSBlockOperation {
                    self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
                })
                
            case .Delete:
                blockOperations.append(NSBlockOperation {
                    self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
                })
                
            case .Update:
                blockOperations.append(NSBlockOperation {
                    self.collectionView?.reloadItemsAtIndexPaths([indexPath!])
                })
            
            default:
                break
            }
        }
    }
    
    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        
        if controller == fetchedResultsControllerForPhotos {
            collectionView?.performBatchUpdates({
                for operation in self.blockOperations {
                    operation.start()
                }
                }, completion: nil)
        }
    }
}


// MARK: - Network Request
extension CoreDataCollectionViewController {
    
    func downloadPhotos() {
        deleteCurrentPhotos()
        downloadPhotosBackground(WithStack: coreDataStack, ForPin: pin)
    }
    
    func deleteCurrentPhotos() {
        
        if fetchedResultsControllerForPhotos!.sections?[0].numberOfObjects > 0 {
            
            let photos = fetchedResultsControllerForPhotos?.fetchedObjects as! [Photo]
            
            for photo in photos {
                coreDataStack.context.deleteObject(photo)
            }
            coreDataStack.context.processPendingChanges()
        }
    }
}


// MARK: - UI Configuration
extension CoreDataCollectionViewController {
    
    func updateUIForNoPhoto() {
        activityIndicator.stopAnimating()
        
        newAlbumButton?.alpha = 0
        
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
        
        label.text = "No photos were found at this location."
        label.alpha = 0
        
        performAnimation {
            self.label.alpha = 1
        }
    }
    
    func updateUIForDeletePhotos() {
        label.alpha = 0
        label.text = ""
        retryButton.alpha = 0
        newAlbumButton?.alpha = 0
        refreshControl.endRefreshing()
        refreshControl.removeFromSuperview()
        
        activityIndicator.startAnimating()
    }
    
    func updateUIForFetchPhotosTimedOut() {
        activityIndicator.stopAnimating()
        
        newAlbumButton?.alpha = 0
        
        label.text = "Fetching photos timed out."
        label.alpha = 0
        
        retryButton.addTarget(self, action: #selector(self.downloadPhotos), forControlEvents: .TouchUpInside)
        retryButton.alpha = 0
        
        collectionView?.addSubview(self.refreshControl)
        
        performAnimation {
            self.label.alpha = 1
            self.retryButton.alpha = 1
        }
    }
    
    func updateUIForNewAlbumFetched() {
        activityIndicator.stopAnimating()
        
        label.alpha = 0
        label.text = ""
        
        retryButton.alpha = 0
        
        awakeUIAfterSeconds(1) {
            self.collectionView?.addSubview(self.refreshControl)
            self.newAlbumButton?.alpha = 0
            performAnimation {
                self.newAlbumButton?.alpha = 1
            }
        }
    }
}
