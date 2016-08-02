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
    
    convenience init(context: NSManagedObjectContext, id: String, latitude: Double, longitude: Double, locationName: String? = nil) {
        
        if let entity = NSEntityDescription.entityForName("Pin", inManagedObjectContext: context) {
            self.init(entity: entity, insertIntoManagedObjectContext: context)
            self.latitude = NSNumber(double: latitude)
            self.longitude = NSNumber(double: longitude)
            self.id = id
            self.locationName = locationName
            self.dateCreated = NSDate()
            self.dateUpdated = self.dateCreated
            self.isSelected = false
        } else {
            fatalError("Unable to find Entity name!")
        }
    }

}
