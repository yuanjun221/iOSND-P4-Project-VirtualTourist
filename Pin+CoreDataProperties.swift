//
//  Pin+CoreDataProperties.swift
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

extension Pin {

    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var isSelected: NSNumber?
    @NSManaged var dateCreated: NSDate?
    @NSManaged var id: String?
    @NSManaged var locationName: String?
    @NSManaged var photos: NSSet?

}
