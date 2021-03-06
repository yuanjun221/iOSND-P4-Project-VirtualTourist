//
//  GlobalHelperFunctions.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/11.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import Foundation
import UIKit
import CoreData


var coreDataStack: CoreDataStack = {
    return (UIApplication.sharedApplication().delegate as! AppDelegate).coreDataStack
}()

func performUIUpdatesOnMain(updates: () -> Void) {
    dispatch_async(dispatch_get_main_queue()) {
        updates()
    }
}

func performAnimation(updates: () -> Void) {
    UIView.animateWithDuration(0.25) {
        updates()
    }
}

func awakeUIAfterSeconds(seconds: Int, updates:() -> Void) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (Int64)(UInt64(seconds) * NSEC_PER_SEC)), dispatch_get_main_queue()){
        updates()
    }
}

func fetchedResultsController(entityName entityName: String, predicate: NSPredicate, sortDescriptors: [NSSortDescriptor]) -> NSFetchedResultsController {
    let fetchRequest = NSFetchRequest(entityName: entityName)
    fetchRequest.predicate = predicate
    fetchRequest.sortDescriptors = sortDescriptors
    let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: coreDataStack.context, sectionNameKeyPath: nil, cacheName: nil)
    return fetchedResultsController
}