//
//  Pin+CoreDataProperties.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/8.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var id: String?
    @NSManaged var isSelected: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var locationName: String?
    @NSManaged var longitude: NSNumber?
    
    @NSManaged var photos: NSOrderedSet?

}
