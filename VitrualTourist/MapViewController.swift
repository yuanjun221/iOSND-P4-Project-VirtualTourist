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


// MARK: View Controller Properties
class MapViewController: UIViewController {

    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var selectButton: UIBarButtonItem!
    @IBOutlet weak var infoLabelButton: UIBarButtonItem!
    @IBOutlet weak var trashButton: UIBarButtonItem!
    
    lazy var coreDataStack: CoreDataStack = {
        return (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack
    }()
    
    lazy var pins = [Pin]()
    
    private var infoLabel = UILabel(frame: CGRectZero)
    private var isSelecting: Bool = false
    private var pinsSelected: Int = 0
    private var pinToBeDelivered: Pin!
}


// MARK: - View Controller Life Cycle
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
        
        setPinsDeselected()
        dropExistedPins()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
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
                

                let predicateForPin = NSPredicate(format: "id == %@", pinToBeDelivered.id!)
                let sortDescriptorForPin = NSSortDescriptor(key: "id", ascending: true)
                let fetchedResultsControllerForPin = fetchedResultsController(entityName: "Pin", predicate: predicateForPin, sortDescriptors: [sortDescriptorForPin])
                photoAlbumViewController.fetchedResultsControllerForPin = fetchedResultsControllerForPin
                
                photoAlbumViewController.pin = pinToBeDelivered
            }
        }
    }
    
    private func fetchedResultsController(entityName entityName: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> NSFetchedResultsController {
        let fetchRequest = NSFetchRequest(entityName: entityName)
        fetchRequest.predicate = predicate
        fetchRequest.sortDescriptors = sortDescriptors
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
        return fetchedResultsController
    }
    
    private func saveMapRegionToUserDefaults() {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        userDefaults.setBool(true, forKey: VTClient.UserDefaultsKeys.HasLaunchedBefore)
        userDefaults.setValue(mapView.centerCoordinate.latitude, forKey: VTClient.UserDefaultsKeys.Latitude)
        userDefaults.setValue(mapView.centerCoordinate.longitude, forKey: VTClient.UserDefaultsKeys.Longitude)
        userDefaults.setValue(mapView.region.span.latitudeDelta, forKey: VTClient.UserDefaultsKeys.LatitudeDelta)
        userDefaults.setValue(mapView.region.span.longitudeDelta, forKey: VTClient.UserDefaultsKeys.LongitudeDelta)
    }
    
    private func setMapRegionFromUserDefaults() {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
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
            let id = NSUUID().UUIDString
            
            let pin = Pin(context:coreDataStack.context, id: id, latitude: coordinate.latitude, longitude: coordinate.longitude, latitudeDelta: coordinateSpan.latitudeDelta, longitudeDelta: coordinateSpan.longitudeDelta)
            coreDataStack.context.processPendingChanges()
            
            let annotaion = VTMKPointAnnotation()
            annotaion.coordinate = coordinate
            annotaion.id = id
            
            mapView.addAnnotation(annotaion)
            
            if selectButton.enabled == false {
                selectButton.enabled = true
            }
            
            downloadPhotosBackground(WithStack: coreDataStack, ForPin: pin)
        }
    }
    
}


// MARK: - Buttons Action
extension MapViewController {
    
    @IBAction func selectButtonPressed(sender: AnyObject) {
        isSelecting = !isSelecting
        selectButton.title = ""
        selectButton.title = isSelecting ? "Done" : "Select"
        
        navigationController?.setToolbarHidden(!isSelecting, animated: true)
        
        if isSelecting {
            enableDraggableForAnnotationView(false)
            fetchExistedPins()      // TODO: Can be removed?
        } else {
            enableDraggableForAnnotationView(true)
            setPinsDeselected()
            setPinAnnotationsDeselected()
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
    
    func quitSelectingState() {
        isSelecting = false
        selectButton.title = "Select"
        navigationController?.setToolbarHidden(true, animated: true)
        resetToolbar()
        pinsSelected = 0
    }
    
    func enableDraggableForAnnotationView(enabled: Bool) {
        for annotation in mapView.annotations {
            
            let pinAnnotation = annotation as! VTMKPointAnnotation
            pinAnnotation.draggable = enabled
            
            if let annotationView = mapView.viewForAnnotation(annotation) {
                annotationView.draggable = enabled
            }
        }
    }
    
    func setPinAnnotationsDeselected() {
        for annotation in mapView.annotations {
            if let annotaionView = mapView.viewForAnnotation(annotation) as? MKPinAnnotationView {
                let pinAnnotation = annotaionView.annotation as! VTMKPointAnnotation
                
                if pinAnnotation.isSelected {
                    annotaionView.pinTintColor = MKPinAnnotationView.redPinColor()
                    pinAnnotation.isSelected = false
                }
            }
        }
    }
    
    func resetToolbar() {
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
        let predicate = NSPredicate(format: "id == %@", pinAnnotation.id)
        
        fetchPinsWithPredicate(predicate) { results in
            guard let results = results else {
                return
            }
            
            guard let pin = results.first else {
                return
            }
            
            if self.isSelecting {
                pin.isSelected = NSNumber(bool: !(Bool(pin.isSelected!)))
                
                let isPinSelected = Bool(pin.isSelected!)
                pinAnnotation.isSelected = isPinSelected
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
        }
        
        mapView.deselectAnnotation(view.annotation, animated: false)
    }
    
    func configureToolbarWithIndicator(indicator: Bool) {
        pinsSelected += Bool(indicator) ? 1 : -1
        
        if pinsSelected == 0 {
            resetToolbar()
        } else {
            let pinString = pinsSelected == 1 ? "pin" : "pins"
            infoLabel.text = "\(pinsSelected) \(pinString) selected"
            trashButton.enabled = true
        }
    }
    
    func mapView(mapView: MKMapView, annotationView view: MKAnnotationView, didChangeDragState newState: MKAnnotationViewDragState, fromOldState oldState: MKAnnotationViewDragState) {
        
        if !isSelecting {
            if newState == .Ending {
                
                let pinView = view as! VTMKPinAnnotationView
                
                pinView.dragged = true
                
                let pointAnnotation = pinView.annotation as! VTMKPointAnnotation
                
                let predicate = NSPredicate(format: "id == %@", pointAnnotation.id)
                
                fetchPinsWithPredicate(predicate) { results in
                    guard let results = results else {
                        return
                    }
                    
                    guard let pin = results.first else {
                        return
                    }
                    
                    self.coreDataStack.context.deleteObject(pin)
                    
                    let coordinateSpan = mapView.region.span
                    let newPin = Pin(context: self.coreDataStack.context, id: pointAnnotation.id, latitude: pointAnnotation.coordinate.latitude, longitude: pointAnnotation.coordinate.longitude, latitudeDelta: coordinateSpan.latitudeDelta, longitudeDelta: coordinateSpan.longitudeDelta)
                    
                    self.downloadPhotosBackground(WithStack: self.coreDataStack, ForPin: newPin)
                }
            }
        }
    }
}


// MARK: - Data Model Manipulating
extension MapViewController {
    
    func fetchExistedPins() {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        
        do {
            pins = try coreDataStack.context.executeFetchRequest(fetchRequest) as! [Pin]
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func dropExistedPins() {
        fetchExistedPins()
        
        if !pins.isEmpty {
            for pin in pins {
                let annotation = VTMKPointAnnotation()
                let coordinate = CLLocationCoordinate2D(latitude: Double(pin.latitude!), longitude: Double(pin.longitude!))
                annotation.coordinate = coordinate
                annotation.id = pin.id
                mapView.addAnnotation(annotation)
            }
        } else {
            selectButton.enabled = false
        }
    }
    
    func fetchPinsWithPredicate(predicate: NSPredicate, completionHandler: (results: [Pin]?) -> Void) {
        let fetchRequest = NSFetchRequest(entityName: "Pin")
        fetchRequest.predicate = predicate
        
        do {
            let results = try coreDataStack.context.executeFetchRequest(fetchRequest) as! [Pin]
            completionHandler(results: results)
        } catch let error as NSError {
            completionHandler(results: nil)
            print("Could not fetch \(error), \(error.userInfo)")
        }
    }
    
    func setPinsDeselected() {
        let predicate = NSPredicate(format: "isSelected == %@", true)
        
        fetchPinsWithPredicate(predicate) { results in
            guard let results = results else {
                return
            }
            
            for pin in results {
                pin.isSelected = false
            }
        }
    }
    
    func deleteSelectedPins() {
        
        for annotation in mapView.annotations {
            let pinAnnotation = annotation as! VTMKPointAnnotation
            if pinAnnotation.isSelected {
                mapView.removeAnnotation(annotation)
            }
        }
        
        let predicate = NSPredicate(format: "isSelected == %@", true)
        
        fetchPinsWithPredicate(predicate) { results in
            guard let results = results else {
                return
            }
            
            for pin in results {
                self.coreDataStack.context.deleteObject(pin)
            }
        }
        
        enableDraggableForAnnotationView(true)
    }
}
