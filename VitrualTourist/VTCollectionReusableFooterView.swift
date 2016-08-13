//
//  VTCollectionReusableFooterView.swift
//  VitrualTourist
//
//  Created by Jun.Yuan on 16/8/11.
//  Copyright © 2016年 Jun.Yuan. All rights reserved.
//

import UIKit

class VTCollectionReusableFooterView: UICollectionReusableView {
    
    @IBOutlet weak var newAlbumButton: UIButton!
    
    override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        newAlbumButton.layer.borderWidth = 1.0
        newAlbumButton.layer.borderColor = UIColor.grayColor().CGColor
        newAlbumButton.layer.cornerRadius = 4.0
    }
}
