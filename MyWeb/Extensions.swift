//
//  Extensions.swift
//  MyWeb
//
//  Created by Jake Cronin on 8/5/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import UIKit

extension UIImage{
	func rounded(radius: CGFloat) -> UIImage?{
		var imageView: UIImageView = UIImageView(image: self)
		var layer: CALayer = CALayer()
		layer = imageView.layer
		
		layer.masksToBounds = true
		layer.cornerRadius = CGFloat(radius)
		//UIGraphicsBeginImageContext(imageView.bounds.size)
		UIGraphicsBeginImageContextWithOptions(imageView.bounds.size, false, UIScreen.main.scale)
		layer.render(in: UIGraphicsGetCurrentContext()!)
		var roundedImage = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		
		return roundedImage
	}
}
