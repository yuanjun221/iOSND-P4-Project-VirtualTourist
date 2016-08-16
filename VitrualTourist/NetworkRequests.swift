//
//  ReusableMethods.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/7.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import CoreData
import Foundation
import UIKit

extension UIViewController {
    
    func downloadPhotosBackgroundForPin(pin: Pin) {
        
        guard let context = pin.managedObjectContext else {
            print("Abort fetching photos for 'Pin \(pin)'. Managed object has been deleted from its context.")
            return
        }
        
        self.getPhotosModelWithPin(context, pin: pin) {
            for photo in pin.photos! {
                let photo = photo as! Photo
                self.downloadImageDataForPhoto(photo, completionHandler: nil)
            }
        }
    }
    
    private func getPhotosModelWithPin(context:NSManagedObjectContext, pin: Pin, completionHandler:(() -> Void)?) {
        
        VTClient.sharedInstance().getPhotosModelWithPin(context, pin: pin) { (result, error) in
            
            if let error = error {
                print("Error occurred when getting Photos: " + error.localizedDescription)
                                
                switch error.code {
                case -1001, -1009:
                    pin.fetchPhotosTimedOut = true
                    
                case -3000:
                    pin.noPhoto = true
                    self.setFetchPhotosTimedOutForPin(pin)
                    
                default:
                    self.setFetchPhotosTimedOutForPin(pin)
                }
                
                context.processPendingChanges()
                return
            }
            
            if pin.fault {
                print("Discard assign relationshiop photos to 'Pin \(pin.objectID)'. Managed object has been deleted from its context.")
                return
            }
            
            pin.photos = NSOrderedSet(array: result!)
            
            self.setFetchPhotosTimedOutForPin(pin)
            pin.noPhoto = false
            
            context.processPendingChanges()
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
    
    func downloadImageDataForPhoto(photo: Photo, completionHandler:(() -> Void)?) {
        
        guard let context = photo.managedObjectContext else {
            print("Abort downloading data for 'Photo \(photo)'. Managed object has been deleted from its context.")
            return
        }
        
        if Bool(photo.isDownloading!) {
            return
        }
        
        photo.isDownloading = true

        let imageURL = NSURL(string: photo.imageURL!)
        
        VTClient.sharedInstance().taskForGETImageData(imageURL!) { (data, error) in
            if let error = error {
                
                photo.isDownloading = false
                print("Error occurred when downloading image for 'Photo \(photo)' " + error.localizedDescription)
                switch error.code {
                case -1001:
                    photo.fetchImageDataTimedOut = true
                default:
                    break
                }

                context.processPendingChanges()
                return
            }
            
            if photo.fault {
                print("Discard downloaded image data for 'Photo \(photo.objectID)'. Managed object has been deleted from its context.")
                return
            }
            
            photo.imageData = data!
            photo.isDownloading = false
            if Bool(photo.fetchImageDataTimedOut!) {
                photo.fetchImageDataTimedOut = false
            }
            context.processPendingChanges()
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
    
    private func setFetchPhotosTimedOutForPin(pin: Pin) {
        if !pin.fault && Bool(pin.fetchPhotosTimedOut!) {
            pin.fetchPhotosTimedOut = false
        }
    }
}
