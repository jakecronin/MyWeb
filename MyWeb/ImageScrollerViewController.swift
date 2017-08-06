//
//  ImageScrollerViewController.swift
//  MyWeb
//
//  Created by Jake Cronin on 8/5/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import UIKit



class ImageScrollerViewController: UIViewController{
	
	@IBOutlet weak var collectionView: UICollectionView!
	var images: [UIImage]!
	
	override func viewDidLoad() {
		print("view controller loaded with this many images: \(images.count)")
	}
	
}
extension ImageScrollerViewController: UICollectionViewDelegate{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		self.dismiss(animated: true, completion: nil)
	}
}
extension ImageScrollerViewController: UICollectionViewDataSource{
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
		cell.imageView.image =  UIImage()
		cell.imageView.image = images?[indexPath.row]
		return cell
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard images != nil else{
			return 0
		}
		return images!.count
	}
	func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
		return self.view.frame.size
	}
}








