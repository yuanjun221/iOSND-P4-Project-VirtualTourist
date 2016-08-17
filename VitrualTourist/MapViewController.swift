//
//  MapViewController.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/7/29.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit
import MapKit
import CoreData


// MARK: - Properties
class MapViewController: UIViewController {
    
    // MARK: Properties
    lazy private var fetchedResultsControllerForPins: NSFetchedResultsController = {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        let sortDescriptor = NSSortDescriptor(key: "latitude", ascending: true)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }()
    
    lazy private var userDefaults: NSUserDefaults = {
        return NSUserDefaults.standardUserDefaults()
    }()
    
    lazy private var pins = [Pin]()
    
    private var infoLabel = UILabel(frame: CGRectZero)
    private var isSelecting: Bool = false
    private var pinsSelected: Int = 0
    private var pinToBeDelivered: Pin!
    
    // MARK: Outlets
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var infoLabelButton: UIBarButtonItem!
    @IBOutlet weak var trashButton: UIBarButtonItem!
}


// MARK: - View Life Cycle
extension MapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        navigationController?.setToolbarHidden(true, animated: false)
        
        infoLabel.backgroundColor = UIColor.clearColor()
        infoLabel.textAlignment = .Center
        infoLabelButton.customView = infoLabel
        
        infoLabel.text = "Tap pins to select"
        infoLabel.sizeToFit()
        trashButton.enabled = false
        
        setMapRegionFromUserDefaults()
        dropExistedPins()
    }
    
    override func viewWillDisappear(animated: Bool) {
        super.viewWillDisappear(animated)
        saveMapRegionToUserDefaults()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "pushPhotoAlbumView" {
            
            if let photoAlbumViewController = segue.destinationViewController as? PhotoAlbumViewController {
                
                let predicateForPhotos = NSPredicate(format: "pin == %@", pinToBeDelivered)
                let sortDescriptorForPhotos = NSSortDescriptor(key: "owner", ascending: true)
                let fetchedResultsControllerForPhotos = fetchedResultsController(entityName: "Photo", predicate: predicateForPhotos, sortDescriptors: [sortDescriptorForPhotos])
                photoAlbumViewController.fetchedResultsControllerForPhotos = fetchedResultsControllerForPhotos
                

                let predicateForPin = NSPredicate(format: "self == %@", pinToBeDelivered)
                let sortDescriptorForPin = NSSortDescriptor(key: "latitude", ascending: true)
                let fetchedResultsControllerForPin = fetchedResultsController(entityName: "Pin", predicate: predicateForPin, sortDescriptors: [sortDescriptorForPin])
                photoAlbumViewController.fetchedResultsControllerForPin = fetchedResultsControllerForPin
                
                photoAlbumViewController.pin = pinToBeDelivered
            }
        }
    }
    
    private func saveMapRegionToUserDefaults() {
        userDefaults.setBool(true, forKey: VTClient.UserDefaultsKeys.HasLaunchedBefore)
        userDefaults.setValue(mapView.centerCoordinate.latitude, forKey: VTClient.UserDefaultsKeys.Latitude)
        userDefaults.setValue(mapView.centerCoordinate.longitude, forKey: VTClient.UserDefaultsKeys.Longitude)
        userDefaults.setValue(mapView.region.span.latitudeDelta, forKey: VTClient.UserDefaultsKeys.LatitudeDelta)
        userDefaults.setValue(mapView.region.span.longitudeDelta, forKey: VTClient.UserDefaultsKeys.LongitudeDelta)
    }
    
    private func setMapRegionFromUserDefaults() {
        if userDefaults.boolForKey(VTClient.UserDefaultsKeys.HasLaunchedBefore) {
            let latitude = userDefaults.doubleForKey(VTClient.UserDefaultsKeys.Latitude)
            let longitude = userDefaults.doubleForKey(VTClient.UserDefaultsKeys.Longitude)
            let latitudeDelta = userDefaults.doubleForKey(VTClient.UserDefaultsKeys.LatitudeDelta)
            let longitudeDelta = userDefaults.doubleForKey(VTClient.UserDefaultsKeys.LongitudeDelta)
            
            let centerCoordinate = CLLocationCoordinate2DMake(latitude, longitude)
            let coordinateSpan = MKCoordinateSpanMake(latitudeDelta, longitudeDelta)
            let region = MKCoordinateRegionMake(centerCoordinate, coordinateSpan)
            
            mapView.setRegion(region, animated: false)
        }
    }
}


// MARK: - View Gesture Response
extension MapViewController {
    
    @IBAction func longPressView(sender: AnyObject) {
        if !isSelecting && sender.state == .Began {
            let point = sender.locationInView(mapView)
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: mapView)
            let coordinateSpan = mapView.region.span
            
            let pin = Pin(context:fetchedResultsControllerForPins.managedObjectContext, latitude: coordinate.latitude, longitude: coordinate.longitude, latitudeDelta: coordinateSpan.latitudeDelta, longitudeDelta: coordinateSpan.longitudeDelta)
            
            let annotaion = VTMKPointAnnotation()
            annotaion.coordinate = coordinate
            annotaion.pin = pin
            
            mapView.addAnnotation(annotaion)
            
            if selectButton.enabled == false {
                selectButton.enabled = true
            }
            
            downloadPhotosBackgroundForPin(pin)
        }
    }
}


// MARK: - Button Actions
extension MapViewController {
    
    @IBAction func selectButtonPressed(sender: AnyObject) {
        isSelecting = !isSelecting
        selectButton.title = ""
        selectButton.title = isSelecting ? "Done" : "Select"
        navigationController?.setToolbarHidden(!isSelecting, animated: true)
        enableDraggableForAnnotationView(!isSelecting)
        
        if !isSelecting {
            deselectPins()
            resetToolbar()
            pinsSelected = 0
        }
    }
    
    @IBAction func trashButtonPressed(sender: AnyObject) {
        let pinString = pinsSelected == 1 ? "This pin" : "These pins"
        let alertTitle = "\(pinString) will be removed from the map."
        
        let alertController = UIAlertController(title: alertTitle, message: nil, preferredStyle: .ActionSheet)
        
        let deleteActionTitle = pinsSelected == 1 ? "Remove Pin" : "Remove \(pinsSelected) Pins"
        let deleteAction = UIAlertAction(title: deleteActionTitle, style: .Destructive) { deleteAction in
            self.deleteSelectedPins()
            self.quitSelectingState()
            if self.mapView.annotations.isEmpty {
                self.selectButton.enabled = false
            }
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .Cancel, handler: nil)
        
        alertController.addAction(deleteAction)
        alertController.addAction(cancelAction)
        presentViewController(alertController, animated: true, completion: nil)
        
    }
    
    private func quitSelectingState() {
        isSelecting = false
        selectButton.title = ""
        selectButton.title = "Select"
        navigationController?.setToolbarHidden(true, animated: true)
        resetToolbar()
        pinsSelected = 0
    }
    
    private func enableDraggableForAnnotationView(enabled: Bool) {
        for annotation in mapView.annotations {
            
            let pinAnnotation = annotation as! VTMKPointAnnotation
            pinAnnotation.draggable = enabled
            
            if let annotationView = mapView.viewForAnnotation(annotation) {
                annotationView.draggable = enabled
            }
        }
    }
    
    private func deselectPins() {
        for annotation in mapView.annotations {
            
            let annotation = annotation as! VTMKPointAnnotation
            let pin = annotation.pin
            
            if Bool(pin.isSelected!) {
                pin.isSelected = false
            }
            
            if let annotaionView = mapView.viewForAnnotation(annotation) as? MKPinAnnotationView {
                if annotaionView.pinTintColor == UIColor.lightGrayColor() {
                    annotaionView.pinTintColor = MKPinAnnotationView.redPinColor()
                }
            }
        }
    }
    
    private func resetToolbar() {
        infoLabel.text = "Tap pins to select"
        trashButton.enabled = false
    }
}


// MARK: - Map View Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? VTMKPinAnnotationView
        pinView?.pinTintColor = MKPinAnnotationView.redPinColor()
        
        if pinView == nil {
            pinView = VTMKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        pinView!.draggable = (annotation as! VTMKPointAnnotation).draggable
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        let pinView = view as! VTMKPinAnnotationView
        let pinAnnotation = pinView.annotation as! VTMKPointAnnotation
        
        let pin = pinAnnotation.pin
        
        if self.isSelecting {
            pin.isSelected = !(Bool(pin.isSelected!))
            
            let isPinSelected = Bool(pin.isSelected!)

            pinView.pinTintColor = isPinSelected ? UIColor.lightGrayColor() : MKPinAnnotationView.redPinColor()
            
            self.configureToolbarWithIndicator(isPinSelected)
            
        } else {
            if pinView.dragged {
                pinView.dragged = false
            } else {
                self.pinToBeDelivered = pin
                self.performSegueWithIdentifier("pushPhotoAlbumView", sender: self)
            }
        }
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        if !isSelecting {
            let pinView = view as! VTMKPinAnnotationView
            
            switch newState {
            case .Ending:
                pinView.dragged = true
                
                let annotation = pinView.annotation as! VTMKPointAnnotation
                let pin = annotation.pin
                
                let coordinateSpan = mapView.region.span
                
                pin.latitude = annotation.coordinate.latitude
                pin.longitude = annotation.coordinate.longitude
                pin.latitudeDelta = coordinateSpan.latitudeDelta
                pin.longitudeDelta = coordinateSpan.longitudeDelta
                deleteCurrentPhotosForPin(pin)
                
                self.downloadPhotosBackgroundForPin(pin)
            case .Canceling:
                pinView.dragged = true
            default:
                break
            }
        }
    }
    
    private func configureToolbarWithIndicator(indicator: Bool) {
        pinsSelected += Bool(indicator) ? 1 : -1
        
        if pinsSelected == 0 {
            resetToolbar()
        } else {
            let pinString = pinsSelected == 1 ? "pin" : "pins"
            infoLabel.text = "\(pinsSelected) \(pinString) selected"
            trashButton.enabled = true
        }
    }
    
    private func deleteCurrentPhotosForPin(pin: Pin) {
        if let context = pin.managedObjectContext, let photos = pin.photos {
            if photos.count > 0 {
                for photo in photos {
                    let photo = photo as! Photo
                    context.deleteObject(photo)
                }
                context.processPendingChanges()
            }
        }
    }
}


// MARK: - Data Model Manipulating
extension MapViewController {
    
    private func executeSearchExistedPins() {
        do {
            try fetchedResultsControllerForPins.performFetch()
        } catch let error as NSError {
            print("Error while trying to perform a search: " + error.localizedDescription)
        }
    }
    
    private func dropExistedPins() {
        executeSearchExistedPins()
        
        if let pins = fetchedResultsControllerForPins.fetchedObjects as? [Pin] where fetchedResultsControllerForPins.sections![0].numberOfObjects > 0 {
            for pin in pins {
                if Bool(pin.isSelected!) {
                    pin.isSelected = false
                }
                
                let annotation = VTMKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
                annotation.coordinate = coordinate
                annotation.pin = pin
                mapView.addAnnotation(annotation)
            }
        } else {
            selectButton.enabled = false
        }
    }
    
    private func deleteSelectedPins() {
        for annotation in mapView.annotations {
            let pinAnnotation = annotation as! VTMKPointAnnotation
            
            let pin = pinAnnotation.pin
            
            if let context = pin.managedObjectContext where Bool(pin.isSelected!) {
                context.deleteObject(pin)
                mapView.removeAnnotation(annotation)
            }
        }
        enableDraggableForAnnotationView(true)
    }
}
