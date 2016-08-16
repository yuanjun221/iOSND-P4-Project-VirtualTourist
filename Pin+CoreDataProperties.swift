//
//  Pin+CoreDataProperties.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/14.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Pin {

    @NSManaged var fetchPhotosTimedOut: NSNumber?
    @NSManaged var isSelected: NSNumber?
    @NSManaged var latitude: NSNumber?
    @NSManaged var longitude: NSNumber?
    @NSManaged var noPhoto: NSNumber?
    @NSManaged var latitudeDelta: NSNumber?
    @NSManaged var longitudeDelta: NSNumber?
    @NSManaged var photos: NSOrderedSet?
}
