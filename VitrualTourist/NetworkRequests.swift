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
    
    func getPhotosModelWithPin(context:NSManagedObjectContext, pin: Pin, completionHandler:(() -> Void)?) {
        
        VTClient.sharedInstance().getPhotosModelWithPin(context, pin: pin) { (result, error) in
            
            guard error == nil else {
                print(error?.localizedDescription)
                
                if error!.code == -3000 {
                    pin.noPhoto = true
                }
                
                return
            }
            
            pin.noPhoto = false
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
    
    func downloadImageDataForPhoto(photo: Photo, completionHandler:(() -> Void)?) {
        
        let imageURL = NSURL(string: photo.imageURL!)
        
        VTClient.sharedInstance().taskForGETImageData(imageURL!) { (data, error) in
            guard error == nil else {
                print(error?.localizedDescription)
                return
            }
            
            photo.imageData = data!
            
            if let completionHandler = completionHandler {
                completionHandler()
            }
        }
    }
}



