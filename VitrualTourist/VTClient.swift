//
//  VTClient.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/5.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import Foundation


// MARK: - Properties
class VTClient: NSObject {
    
    // MARK: Properties
    lazy private var session = NSURLSession.sharedSession()
    
    // MARK: Initializers
    override init() {
        super.init()
    }
    
    // MARK: Shared Instance
    class func sharedInstance() -> VTClient {
        struct Singleton {
            static var sharedInstance = VTClient()
        }
        return Singleton.sharedInstance
    }
}


// MARK: - Request Methods
extension VTClient {
    
    // MARK: GET Method
    func taskForGETMethod(WithParameters parameters: [String: AnyObject], completionHandlerForGET: (result: AnyObject!, error: NSError?) -> Void) -> NSURLSessionDataTask {
        let request = NSMutableURLRequest(URL: URLFromParameters(parameters))
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            
            func sendError(errorMessage: String) {
                let error = NSError(domain: "taskForGETMethod", code: 1, userInfo:[NSLocalizedDescriptionKey : errorMessage])
                completionHandlerForGET(result: nil, error: error)
            }
            
            guard error == nil else {
                completionHandlerForGET(result: nil, error: error)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            self.convertDataWithCompletionHandler(data, completionHandlerForConvertData: completionHandlerForGET)
        }
        
        task.resume()
        return task
    }
    
    // MARK: GET Image Data
    func taskForGETImageData(url: NSURL, completionHandlerForGETImageData: (imageData: NSData?, error: NSError?) -> Void) -> NSURLSessionTask {
        let request = NSURLRequest(URL: url)
        let task = session.dataTaskWithRequest(request) { (data, response, error) in
            func sendError(error: String) {
                let error = NSError(domain: "taskForGETImageData", code: 1, userInfo: [NSLocalizedDescriptionKey : error])
                completionHandlerForGETImageData(imageData: nil, error: error)
            }
            
            guard (error == nil) else {
                completionHandlerForGETImageData(imageData: nil, error: error)
                return
            }
            
            guard let statusCode = (response as? NSHTTPURLResponse)?.statusCode where statusCode >= 200 && statusCode <= 299 else {
                sendError("Your request returned a status code other than 2xx!")
                return
            }
            
            guard let data = data else {
                sendError("No data was returned by the request!")
                return
            }
            
            completionHandlerForGETImageData(imageData: data, error: nil)
        }
        
        task.resume()
        return task
    }
}


// MARK: - Helper Methods
extension VTClient {
    
    private func URLFromParameters(parameters: [String: AnyObject]) -> NSURL {
        let components = NSURLComponents()
        components.scheme = Constants.ApiScheme
        components.host = Constants.ApiHost
        components.path = Constants.ApiPath
        components.queryItems = [NSURLQueryItem]()
        
        for (key, value) in parameters {
            let queryItem = NSURLQueryItem(name: key, value: "\(value)")
            components.queryItems!.append(queryItem)
        }
        
        return components.URL!
    }
    
    private func convertDataWithCompletionHandler(data: NSData, completionHandlerForConvertData: (result: AnyObject!, error: NSError?) -> Void) {
        var parsedResult: AnyObject!
        do {
            parsedResult = try NSJSONSerialization.JSONObjectWithData(data, options: .AllowFragments)
        } catch {
            completionHandlerForConvertData(result: nil, error: NSError(domain: "convertDataWithCompletionHandler", code: 1, userInfo: [NSLocalizedDescriptionKey : "Could not parse the data as JSON: '\(data)'"]))
        }
        completionHandlerForConvertData(result: parsedResult, error: nil)
    }
}

