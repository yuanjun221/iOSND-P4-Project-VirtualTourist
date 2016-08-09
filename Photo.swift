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
    
    convenience init(context: NSManagedObjectContext, dictionary:[String: AnyObject]) {
        if let entity = NSEntityDescription.entityForName("Photo", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            title = (dictionary[VTClient.ResponseKeys.Title] as! String)
            imageURL = (dictionary[VTClient.ResponseKeys.MediumURL] as! String)
            owner = (dictionary[VTClient.ResponseKeys.Owner] as! String)
        } else {
            fatalError("Unable to find Entity name 'Photo'!")
        }
    }
    
    static func photosFromResults(context: NSManagedObjectContext, results: [[String: AnyObject]]) -> [Photo] {
        var photos = [Photo]()
        
        for result in results {
            photos.append(Photo(context: context, dictionary: result))
        }
        
        return photos
    }
    
}
