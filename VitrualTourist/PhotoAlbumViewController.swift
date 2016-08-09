//
//  PhotoAlbumViewController.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/2.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit
import MapKit
import CoreData

class PhotoAlbumViewController: CoreDataCollectionViewController {

    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
    
    var pin: Pin!
    
    lazy var coreDataStack: CoreDataStack = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack
    }()
}


extension PhotoAlbumViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionView?.showsVerticalScrollIndicator = false
    }
    
    override func viewWillTransitionToSize(size: CGSize, withTransitionCoordinator coordinator: UIViewControllerTransitionCoordinator) {
        let size = getCellSize()
        flowLayout.itemSize = size
        flowLayout.invalidateLayout()
    }
}


// MARK: - Collection View Delegate Flow Layout
extension PhotoAlbumViewController: UICollectionViewDelegateFlowLayout{
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        
        return getCellSize()
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat {
        return 1.0
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let size = CGSizeMake(view.frame.width, view.frame.width * 0.6)
        return size
    }
    
    func getCellSize() -> CGSize {
        let width = self.view.frame.size.width
        let dimension: CGFloat!
        let size: CGSize!
        let orientation = UIApplication.sharedApplication().statusBarOrientation
        
        if orientation.isPortrait {
            dimension = (width - 3.0) / 4.0
            size = CGSizeMake(dimension, dimension)
        } else {
            dimension = (width - 6.0) / 7.0
            size = CGSizeMake(dimension, dimension)
        }
        
        return size
    }
}


// MARK: - Collection View Data Source
extension PhotoAlbumViewController {
    
    override func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("photoCell", forIndexPath: indexPath) as! VTCollectionViewCell
        
        let photo = fetchedResultsController!.objectAtIndexPath(indexPath) as! Photo
        
        populateImage(WithPhoto: photo, ForCell: cell)

        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "mapCell", forIndexPath: indexPath) as! VTCollectionReusableView
            setMapViewAnnotation(ForMapView: headerView.mapView)
            return headerView
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    func setMapViewAnnotation(ForMapView mapView: MKMapView) {
        let annotation = MKPointAnnotation()
        let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
        annotation.coordinate = coordinate
        mapView.addAnnotation(annotation)
        mapView.setCenterCoordinate(coordinate, animated: false)
        
        let region = CLCircularRegion(center: coordinate, radius: 5000, identifier: "Town")
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(coordinate, region.radius * 2, region.radius * 2)
        mapView.regionThatFits(coordinateRegion)
        mapView.setRegion(coordinateRegion, animated: false)
    }
}


// MARK: -
extension PhotoAlbumViewController {
    
    func populateImage(WithPhoto photo: Photo, ForCell cell: VTCollectionViewCell) {
        if let imageData = photo.imageData {
            
            guard let image = UIImage(data: imageData) else {
                print("No image returned from existed imageData in photo \(photo)")
                return
            }
            
            cell.imageView.image = image
            
        } else {
            downloadImageDataForPhoto(photo) {
                
                guard let imageData = photo.imageData else {
                    print("No imageData in photo \(photo)")
                    return
                }
                
                guard let image = UIImage(data: imageData) else {
                    print("No image returned from existed imageData in photo \(photo)")
                    return
                }
                
                performUIUpdatesOnMain() {
                    cell.imageView.image = image
                }
            }
        }
    }
}
