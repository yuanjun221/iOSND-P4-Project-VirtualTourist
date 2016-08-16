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
    
    var dragged: Bool = false
    
    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.setSelected(true, animated: false)
        super.touchesBegan(touches, withEvent: event)
    }
    
    override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
        
        self.setSelected(false, animated: false)
        super.touchesEnded(touches, withEvent: event)
    }
}
