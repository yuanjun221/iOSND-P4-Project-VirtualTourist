//
//  VTConvenience.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/5.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import Foundation
import CoreData

// MARK: - Request Method Convenience
extension VTClient {
    
    func getPhotosModelWithPin(context:NSManagedObjectContext, pin: Pin, completionHandlerForPhotosModel: (result: Bool, error: NSError?) -> Void) {
        let latitude = Double(pin.latitude!)
        let longitude = Double(pin.longitude!)
        
        VTClient.sharedInstance().getRandomPageWithLocation(latitude, longitude: longitude) { (randomPage, error) in
            
            guard error == nil else {
                completionHandlerForPhotosModel(result: false, error: error)
                return
            }
            
            VTClient.sharedInstance().getPhotosArray(latitude, longitude: longitude, page: randomPage!) { (photosArray, error) in
            
                guard error == nil else {
                    completionHandlerForPhotosModel(result: false, error: error)
                    return
                }
                
                let photos = Photo.photosFromResults(context, results: photosArray!)
                
                pin.photos = NSOrderedSet(array: photos)
                
                completionHandlerForPhotosModel(result: true, error: nil)
            }
        }
    }
    
    func getRandomPageWithLocation(latitude: Double, longitude: Double, completionHandlerForRandomPage: (result: Int?, error: NSError?) -> Void) {
        
        let parameters: [String: AnyObject] = [
            ParameterKeys.Method: Methods.SearchPhotos,
            ParameterKeys.ApiKey: ParameterValues.APIKey,
            ParameterKeys.Latitude: latitude,
            ParameterKeys.Longitude: longitude,
            ParameterKeys.PerPage: ParameterValues.PerPage,
            ParameterKeys.Format: ParameterValues.Json,
            ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback
        ]
        
        let errorDomain = "getRandomPage parsing"
        
        taskForGETMethod(WithParameters: parameters) { (results, error) in
            guard error == nil else {
                completionHandlerForRandomPage(result: nil, error: error)
                return
            }
            
            guard let photos = results[ResponseKeys.Photos] as? [String: AnyObject] else {
                completionHandlerForRandomPage(result: nil, error: NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find key '\(ResponseKeys.Photos)' in \(results)"]))
                return
            }
            
            guard let pages = photos[ResponseKeys.Pages] as? Int else {
                completionHandlerForRandomPage(result: nil, error: NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find key '\(ResponseKeys.Pages)' in \(photos)"]))
                return
            }
            
            if pages == 0 {
                completionHandlerForRandomPage(result: nil, error: NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Pages number is 0. No photo returned."]))
                return
            }
            
            let maxPage = min(pages, 40)
            let randomPage = Int(arc4random_uniform(UInt32(maxPage)) + 1)
            completionHandlerForRandomPage(result: randomPage, error: nil)
        }
    }
    
    func getPhotosArray(latitude: Double, longitude: Double, page: Int, completionHandlerForPhotosArray: (result: [[String: AnyObject]]?, error: NSError?) -> Void) {
        
        let parameters: [String: AnyObject] = [
            ParameterKeys.Method: Methods.SearchPhotos,
            ParameterKeys.ApiKey: ParameterValues.APIKey,
            ParameterKeys.Latitude: latitude,
            ParameterKeys.Longitude: longitude,
            ParameterKeys.PerPage: ParameterValues.PerPage,
            ParameterKeys.Format: ParameterValues.Json,
            ParameterKeys.NoJSONCallback: ParameterValues.DisableJSONCallback,
            ParameterKeys.Extras: ParameterValues.MediumURL,
            ParameterKeys.Page: page
        ]
        
        let errorDomain = "getPhotosDictionary parsing"
        
        taskForGETMethod(WithParameters: parameters) { (results, error) in
            guard error == nil else {
                completionHandlerForPhotosArray(result: nil, error: error)
                return
            }
            
            guard let photos = results[ResponseKeys.Photos] as? [String: AnyObject] else {
                completionHandlerForPhotosArray(result: nil, error: NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find key '\(ResponseKeys.Photos)' in \(results)"]))
                return
            }
            
            guard let photosDictionary = photos[ResponseKeys.Photo] as? [[String: AnyObject]] else {
                completionHandlerForPhotosArray(result: nil, error: NSError(domain: errorDomain, code: 0, userInfo: [NSLocalizedDescriptionKey: "Could not find key '\(ResponseKeys.Photo)' in \(photos)"]))
                return
            }
            
            completionHandlerForPhotosArray(result: photosDictionary, error: nil)
        }
    }
}
