//
//  Photo+CoreDataProperties.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/1.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Photo {

    @NSManaged var imageData: NSData?
    @NSManaged var imageURL: String?
    @NSManaged var title: String?
    @NSManaged var owner: String?
    @NSManaged var isDownloading: NSNumber?
    @NSManaged var fetchImageDataTimedOut: NSNumber?
    
    @NSManaged var pin: Pin?

}
