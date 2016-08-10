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
    
    func downloadPhotosModelBackground(WithStack coreDataStack:CoreDataStack, ForPin pin: Pin) {
        coreDataStack.performBackgroundBatchOperation { workerContext in
            self.getPhotosModelWithPin(coreDataStack.context, pin: pin) {
                for photo in pin.photos! {
                    let photo = photo as! Photo
                    self.downloadImageDataForPhoto(photo, completionHandler: nil)
                }
            }
        }
    }
    
    func getPhotosModelWithPin(context:NSManagedObjectContext, pin: Pin, completionHandler:(() -> Void)?) {
        
        VTClient.sharedInstance().getPhotosModelWithPin(context, pin: pin) { (result, error) in
            
            guard error == nil else {
                print("Error occurred when getting Photos: " + error!.localizedDescription)
                                
                switch error!.code {
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
    
    func downloadImageDataForPhoto(photo: Photo, completionHandler:(() -> Void)?) {
        
        let imageURL = NSURL(string: photo.imageURL!)
        
        VTClient.sharedInstance().taskForGETImageData(imageURL!) { (data, error) in
            guard error == nil else {
                print("Error occurred when downloading image From URL (\(photo.imageURL!)) " + error!.localizedDescription)
                return
            }
            
            photo.imageData = data!
            
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



