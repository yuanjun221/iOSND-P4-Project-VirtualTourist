//
//  Pin.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/1.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import Foundation
import CoreData


class Pin: NSManagedObject {
    
    convenience init(context: NSManagedObjectContext, id: String, latitude: Double, longitude: Double, latitudeDelta: Double, longitudeDelta: Double, locationName: String? = nil) {
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = latitude
            self.longitude = longitude
            self.latitudeDelta = latitudeDelta
            self.longitudeDelta = longitudeDelta
            self.id = id
            self.locationName = locationName
            self.isSelected = false
            self.fetchPhotosTimedOut = false
        } else {
            fatalError("Unable to find Entity name 'Pin'!")
        }
    }

}
