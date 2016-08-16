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


// MARK: - Properties
class PhotoAlbumViewController: CoreDataCollectionViewController {
    
    // MARK: Properties
    lazy private var mapRegion: MKCoordinateRegion = {
        let centerCoordinate = CLLocationCoordinate2DMake(Double(self.pin.latitude!), Double(self.pin.longitude!))
        let coordinateSpan = MKCoordinateSpanMake(Double(self.pin.latitudeDelta!) * 0.28, Double(self.pin.longitudeDelta!) * 0.28)
        let region = MKCoordinateRegionMake(centerCoordinate, coordinateSpan)
        return region
    }()
    
    lazy private var imageCache: NSCache = {
       return NSCache()
    }()
    
    // MARK: Outlets
    @IBOutlet weak var flowLayout: UICollectionViewFlowLayout!
}


// MARK: - View Life Cycle
extension PhotoAlbumViewController {
    
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
        let photo = fetchedResultsControllerForPhotos!.objectAtIndexPath(indexPath) as! Photo
        cell.urlString = photo.imageURL!
        
        populateImage(WithPhoto: photo, ForCell: cell)
        return cell
    }
    
    override func collectionView(collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, atIndexPath indexPath: NSIndexPath) -> UICollectionReusableView {
        switch kind {
        case UICollectionElementKindSectionHeader:
            let headerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "header", forIndexPath: indexPath) as! VTCollectionReusableHeaderView
            setMapViewAnnotation(ForMapView: headerView.mapView)
            return headerView
            
        case UICollectionElementKindSectionFooter:
            let footerView = collectionView.dequeueReusableSupplementaryViewOfKind(kind, withReuseIdentifier: "footer", forIndexPath: indexPath) as! VTCollectionReusableFooterView
            let newAlbumButton = footerView.newAlbumButton
            newAlbumButton.addTarget(self, action: #selector(downloadPhotos), forControlEvents: .TouchUpInside)
            
            if fetchedResultsControllerForPhotos!.sections?[0].numberOfObjects == 0 {
                newAlbumButton.alpha = 0
            }
            
            self.newAlbumButton = newAlbumButton
            return footerView
            
        default:
            assert(false, "Unexpected element kind")
        }
    }
    
    private func setMapViewAnnotation(ForMapView mapView: MKMapView) {
        if mapView.annotations.isEmpty {
            let annotation = MKPointAnnotation()
            let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
            annotation.coordinate = coordinate
            mapView.addAnnotation(annotation)
            
            mapView.regionThatFits(mapRegion)
            mapView.setRegion(mapRegion, animated: false)
        }
    }
}


// MARK: - Load Image For Cell
extension PhotoAlbumViewController {
    
    private func populateImage(WithPhoto photo: Photo, ForCell cell: VTCollectionViewCell) {
        cell.imageView.image = UIImage(named: "placeholder")
        if cell.selected {
            cell.checkmarkImageView.image = checkmarkImage
        } else {
            cell.checkmarkImageView.image = nil
        }
        
        if let imageFromCache = imageCache.objectForKey(photo.imageURL!) as? UIImage {
            cell.imageView.image = imageFromCache
            cell.imageView.alpha = 1
            return
        }
        
        if let imageData = photo.imageData {
            
            guard let image = UIImage(data: imageData) else {
                print("No image returned from existed imageData in photo \(photo)")
                return
            }
            setImage(image, WithPhoto: photo, ForCell: cell)
            
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
                    self.setImage(image, WithPhoto: photo, ForCell: cell)
                }
            }
        }
    }
    
    private func setImage(image: UIImage, WithPhoto photo: Photo, ForCell cell: VTCollectionViewCell) {
        if let imageURLString = photo.imageURL {
            if cell.urlString == imageURLString {
                cell.imageView.image = image
            }
            imageCache.setObject(image, forKey: imageURLString)
        }
    }
}
