//
//  VTConstants.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/5.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//


extension VTClient {
    
    // MARK: - API Constants
    struct Constants {
        static let ApiScheme = "https"
        static let ApiHost = "api.flickr.com"
        static let ApiPath = "/services/rest/"
    }
    
    // MARK: - Methods
    struct Methods {
        static let SearchPhotos = "flickr.photos.search"
    }
    
    // MARK: - Parameter Keys
    struct ParameterKeys {
        static let Method = "method"
        static let ApiKey = "api_key"
        static let Latitude = "lat"
        static let Longitude = "lon"
        static let Format = "format"
        static let NoJSONCallback = "nojsoncallback"
        static let PerPage = "per_page"
        static let Page = "page"
        static let Extras = "extras"
    }
    
    // MARK: - Parameter Values
    struct ParameterValues {
        static let APIKey = "a1d9060fadfc472915739a600a6589c5"
        static let Json = "json"
        static let DisableJSONCallback = "1" /* 1 means "yes" */
        static let MediumURL = "url_m"
        static let PerPage = 8
    }
    
    // MARK: - Response Keys
    struct ResponseKeys {
        static let Status = "stat"
        static let Photos = "photos"
        static let Photo = "photo"
        static let Title = "title"
        static let Owner = "owner"
        static let MediumURL = "url_m"
        static let Farm = "farm"
        static let Server = "server"
        static let ID = "id"
        static let Secret = "secret"
        static let Pages = "pages"
        static let Total = "total"
    }
}