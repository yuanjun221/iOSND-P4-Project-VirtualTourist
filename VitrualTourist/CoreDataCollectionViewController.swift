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
    
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var infoLabelButton: UIBarButtonItem!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
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
    
    private var infoLabel = UILabel(frame: CGRectZero)
    private var isSelecting: Bool = false
    private var photosSelected: Int = 0
    
    lazy private var checkmarkImage: UIImage = {
        let checkmarkImage = UIImage(named: "Checkmark")!
        return checkmarkImage
    }()
 
}


// MARK: - View Life Cycle
extension CoreDataCollectionViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        
        collectionView?.alwaysBounceVertical = true
        collectionView?.showsVerticalScrollIndicator = false
        navigationController?.setToolbarHidden(true, animated: false)
        
        infoLabel.backgroundColor = UIColor.clearColor()
        infoLabel.textAlignment = .Center
        infoLabelButton.customView = infoLabel
        
        infoLabel.text = "Tap photos to select"
        infoLabel.sizeToFit()
        trashButton.enabled = false
        
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
            } else if fetchedResultsControllerForPhotos?.sections![0].numberOfObjects == 0 {
                performAnimation {
                    self.newAlbumButton?.alpha = 1
                }
            }
        } else {
            activityIndicator.startAnimating()
        }
    }
}


// MARK: - Buttons Action
extension CoreDataCollectionViewController {
    
    @IBAction func selectButtonPressed(sender: AnyObject) {
        isSelecting = !isSelecting
        selectButton.title = ""
        selectButton.title = isSelecting ? "Done" : "Select"
        
        navigationController?.setToolbarHidden(!isSelecting, animated: true)
        
        if isSelecting {
            refreshControl.endRefreshing()
            refreshControl.removeFromSuperview()
            performAnimation {
                self.newAlbumButton?.alpha = 0
            }
        } else {
            deselectCell()
            resetToolbar()
            photosSelected = 0
            collectionView?.addSubview(refreshControl)
            performAnimation {
                self.newAlbumButton?.alpha = 1
            }
        }
        
        collectionView?.allowsMultipleSelection = isSelecting
    }
    
    @IBAction func trashButtonPressed(sender: AnyObject) {
        
        let photoString = photosSelected == 1 ? "This photo" : "These photos"
        let alertTitle = "\(photoString) will be removed from the album."
        
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let deleteActionTitle = photosSelected == 1 ? "Remove Photo" : "Remove \(photosSelected) Photos"
        let deleteAction = UIAlertAction(title: deleteActionTitle, style: .Destructive) { deleteAction in
            self.deleteSelectedPhotos()
            self.quitSelectingState()
            
            if self.fetchedResultsControllerForPhotos?.sections![0].numberOfObjects == 0 {
                self.downloadPhotos()
            }
            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    func quitSelectingState() {
        isSelecting = false
        selectButton.title = "Select"
        
        navigationController?.setToolbarHidden(true, animated: true)
        resetToolbar()
        photosSelected = 0
        collectionView?.addSubview(refreshControl)
        performAnimation {
            self.newAlbumButton?.alpha = 1
        }
    }
    
    func resetToolbar() {
        infoLabel.text = "Tap photos to select"
        trashButton.enabled = false
    }
    
    func deselectCell() {
        if let indexPaths = collectionView?.indexPathsForSelectedItems() {
            for indexPath in indexPaths {
                setCheckmarkImage(nil, forCellAtIndexPath: indexPath)
                collectionView?.deselectItemAtIndexPath(indexPath, animated: false)
            }
        }
    }
    
    func deleteSelectedPhotos() {
        if let indexPaths = collectionView?.indexPathsForSelectedItems(), context = fetchedResultsControllerForPhotos?.managedObjectContext {
            for indexPath in indexPaths {
                let photo = fetchedResultsControllerForPhotos?.objectAtIndexPath(indexPath) as! Photo
                context.deleteObject(photo)
                collectionView?.deselectItemAtIndexPath(indexPath, animated: false)
            }
            context.processPendingChanges()
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
            if count > 0 {
                selectButton.enabled = true
            } else {
                selectButton.enabled = false
            }
            return count
        }
        selectButton.enabled = false
        return 0
    }
}


// MARK: - Collection View Delegate
extension CoreDataCollectionViewController {
    
    override func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        if isSelecting {
            configureToolbarWithIndicator(true)
            setCheckmarkImage(checkmarkImage, forCellAtIndexPath: indexPath)
        }
    }
    
    override func collectionView(collectionView: UICollectionView, didDeselectItemAtIndexPath indexPath: NSIndexPath) {
        if isSelecting {
            configureToolbarWithIndicator(false)
            setCheckmarkImage(nil, forCellAtIndexPath: indexPath)
        }
    }
    
    func setCheckmarkImage(image: UIImage?, forCellAtIndexPath indexPath: NSIndexPath) {
        let selectedCell = collectionView?.cellForItemAtIndexPath(indexPath) as! VTCollectionViewCell
        selectedCell.checkmarkImageView.image = image
    }
    
    func configureToolbarWithIndicator(indicator: Bool) {
        photosSelected += Bool(indicator) ? 1 : -1
        
        if photosSelected == 0 {
            resetToolbar()
        } else {
            let photoString = photosSelected == 1 ? "photo" : "photos"
            infoLabel.text = "\(photosSelected) \(photoString) selected"
            trashButton.enabled = true
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
        
        if controller == fetchedResultsControllerForPin && !pin.fault {
            
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
                
            case .Move:
                blockOperations.append(NSBlockOperation {
                    self.collectionView?.deleteItemsAtIndexPaths([indexPath!])
                    self.collectionView?.insertItemsAtIndexPaths([newIndexPath!])
                    })
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
        } else {
            updateUIForDeletePhotos()
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
