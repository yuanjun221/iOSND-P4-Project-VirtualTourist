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
        return (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack!
    }()
    lazy var pins = [Pin]()
    
    private var infoLabel = UILabel(frame: CGRectZero)
    private var isSelecting: Bool = false
    private var pinsSelected: Int = 0
    
}


// MARK: - View Controller Life Cycle
extension MapViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.delegate = self
        
        navigationController?.toolbarHidden = true
        
        infoLabel.backgroundColor = UIColor.clearColor()
        infoLabel.textAlignment = .Center

        infoLabelButton.customView = infoLabel
        
        setPinsDeselected()
        dropExistedPins()

    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        infoLabel.text = "Tap pins to select"
        infoLabel.sizeToFit()
        trashButton.enabled = false
    }
}


// MARK: - View Gesture Response
extension MapViewController {
    
    @IBAction func longPressView(sender: AnyObject) {
        if !isSelecting && sender.state == .Began {
            let point = sender.locationInView(mapView)
            let coordinate = self.mapView.convertPoint(point, toCoordinateFromView: mapView)
            let id = NSUUID().UUIDString

            let pin = NSEntityDescription.insertNewObjectForEntityForName("Pin", inManagedObjectContext: coreDataStack.context) as! Pin
            pin.dateCreated = NSDate()
            pin.latitude = NSNumber(double: coordinate.latitude)
            pin.longitude = NSNumber(double: coordinate.longitude)
            pin.id = id
            
            coreDataStack.saveContext()
            
            let annotaion = VTMKPointAnnotation()
            annotaion.coordinate = coordinate
            annotaion.id = id
            
            mapView.addAnnotation(annotaion)
            
            if selectButton.enabled == false {
                selectButton.enabled = true
            }
        }
    }
    
}


// MARK: - Buttons Action
extension MapViewController {
    
    @IBAction func selectButtonPressed(sender: AnyObject) {
        isSelecting = !isSelecting
        selectButton.title = ""
        selectButton.title = isSelecting ? "Done" : "Select"
        
        UIView.animateWithDuration(0.25) {
            self.navigationController?.toolbarHidden = !self.isSelecting
        }
        
        if isSelecting {
            fetchExistedPins()
        } else {
            setPinsDeselected()
            
            for annotation in mapView.annotations {
                let annotaionView = mapView.viewForAnnotation(annotation) as! MKPinAnnotationView
                if annotaionView.pinTintColor == MKPinAnnotationView.greenPinColor() {
                    annotaionView.pinTintColor = MKPinAnnotationView.redPinColor()
                }
            }
            
            pinsSelected = 0
            infoLabel.text = "Tap pins to select"
            trashButton.enabled = false
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
        UIView.animateWithDuration(0.25) {
            self.navigationController?.toolbarHidden = true
        }
        pinsSelected = 0
        infoLabel.text = "Tap pins to select"
        trashButton.enabled = false
    }
}


// MARK: - Map View Delegate
extension MapViewController: MKMapViewDelegate {
    
    func mapView(mapView: MKMapView, viewForAnnotation annotation: MKAnnotation) -> MKAnnotationView? {
        
        let reuseId = "pin"
        var pinView = mapView.dequeueReusableAnnotationViewWithIdentifier(reuseId) as? MKPinAnnotationView
        pinView?.pinTintColor = MKPinAnnotationView.redPinColor()
        
        if pinView == nil {
            pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
            pinView!.canShowCallout = false
            pinView!.animatesDrop = true
        } else {
            pinView!.annotation = annotation
        }
        
        return pinView
    }
    
    func mapView(mapView: MKMapView, didSelectAnnotationView view: MKAnnotationView) {
        if isSelecting {
            if let pinView = view as? MKPinAnnotationView {
                
                let predicate = NSPredicate(format: "id == %@", (pinView.annotation as! VTMKPointAnnotation).id)
                
                fetchPinsWithPredicate(predicate) { results in
                    guard let results = results else {
                        return
                    }
                    
                    guard let pin = results.first else {
                        return
                    }

                    pin.isSelected = NSNumber(bool: !(Bool(pin.isSelected!)))
                    self.coreDataStack.saveContext()

                    pinView.pinTintColor = Bool(pin.isSelected!) ? MKPinAnnotationView.greenPinColor() : MKPinAnnotationView.redPinColor()
                    
                    self.pinsSelected += Bool(pin.isSelected!) ? 1 : -1
                    
                    if self.pinsSelected == 0 {
                        self.infoLabel.text = "Tap pins to select"
                        self.trashButton.enabled = false
                    } else {
                        let pinString = self.pinsSelected == 1 ? "pin" : "pins"
                        self.infoLabel.text = "\(self.pinsSelected) \(pinString) selected"
                        self.trashButton.enabled = true
                    }
                    
                }

                mapView.deselectAnnotation(view.annotation, animated: true)
            }
        }
    }
    
}


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
            self.coreDataStack.saveContext()
        }

    }
    
    func deleteSelectedPins() {
        let predicate = NSPredicate(format: "isSelected == %@", true)
        
        fetchPinsWithPredicate(predicate) { results in
            guard let results = results else {
                return
            }
            
            for pin in results {
                self.coreDataStack.context.deleteObject(pin)

                for annotation in self.mapView.annotations {
                    let pinAnnotation = annotation as! VTMKPointAnnotation
                    if pinAnnotation.id == pin.id {
                        self.mapView.removeAnnotation(annotation)
                    }
                }
            }
            
            self.coreDataStack.saveContext()
        }
    }
    
}
