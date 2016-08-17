//
//  Photo.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/1.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import Foundation
import CoreData


class Photo: NSManagedObject {
    
    // MARK: - Convenience Initializer
    convenience init(context: NSManagedObjectContext, dictionary:[String: AnyObject]) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            title = (dictionary[VTClient.ResponseKeys.Title] as! String)
            
            if let imageURL = dictionary[VTClient.ResponseKeys.MediumURL] as? String {
                self.imageURL = imageURL
            } else {
                let scheme = VTClient.Constants.ApiScheme
                if let farmNum = dictionary[VTClient.ResponseKeys.Farm] as? Int, let server = dictionary[VTClient.ResponseKeys.Server], let id = dictionary[VTClient.ResponseKeys.ID], let secret = dictionary[VTClient.ResponseKeys.Secret] {
                    imageURL = "\(scheme)://farm\(farmNum).staticflickr.com/\(server)/\(id)_\(secret).jpg"
                }
            }
            
            owner = (dictionary[VTClient.ResponseKeys.Owner] as! String)
        } else {
            fatalError("Unable to find Entity name 'Photo'!")
        }
    }
    
    // MARK: - Generate Photos Array
    static func photosFromResults(context: NSManagedObjectContext, results: [[String: AnyObject]]) -> [Photo] {
        var photos = [Photo]()
        
        context.performBlockAndWait {
            for result in results {
                photos.append(Photo(context: context, dictionary: result))
            }
        }

        
        return photos
    }
}
