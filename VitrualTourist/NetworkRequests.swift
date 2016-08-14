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
    
    func downloadPhotosBackground(WithStack coreDataStack: CoreDataStack, ForPin pin: Pin) {
        
        self.getPhotosModelWithPin(coreDataStack.context, pin: pin) {
            
            coreDataStack.performBackgroundBatchOperation { workerContext in
                for photo in pin.photos! {
                    let photo = photo as! Photo
                    self.downloadImageDataForPhoto(coreDataStack.backgroundContext, photo: photo, completionHandler: nil)
                }
            }
        }
    }
    
    func getPhotosModelWithPin(context:NSManagedObjectContext, pin: Pin, completionHandler:(() -> Void)?) {
        
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
            
            self.setFetchPhotosTimedOutForPin(pin)
            pin.noPhoto = false
            
            context.processPendingChanges()
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
    
    func downloadImageDataForPhoto(context:NSManagedObjectContext, photo: Photo, completionHandler:(() -> Void)?) {
        
        if Bool(photo.isDownloading!) {
            // print("Abort downloading image data for 'Photo \(photo.objectID)'. Managed object is processing downloading in another thread.")
            return
        }
        
        photo.isDownloading = true

        let imageURL = NSURL(string: photo.imageURL!)
        
        VTClient.sharedInstance().taskForGETImageData(imageURL!) { (data, error) in
            if let error = error {
                
                print("Error occurred when downloading image From URL (\(photo.imageURL!)) " + error.localizedDescription)
                switch error.code {
                case -1001:
                    photo.fetchImageDataTimedOut = true
                default:
                    break
                }

                context.processPendingChanges()
                return
            }
            
            if photo.imageURL == nil {
                print("Discard downloaded image data for 'Photo \(photo.objectID)'. Managed object has been removed from its context.")
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
        if Bool(pin.fetchPhotosTimedOut!) {
            pin.fetchPhotosTimedOut = false
        }
    }
}
