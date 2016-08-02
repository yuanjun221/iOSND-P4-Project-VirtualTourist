//
//  VTMKPinAnnotationView.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/2.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit
import MapKit

class VTMKPinAnnotationView: MKPinAnnotationView {
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        self.setSelected(true, animated: false)
        super.touchesBegan(touches, withEvent: event)
    }
    

}
