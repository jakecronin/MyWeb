//
//  FacebookHandler.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/22/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import FBSDKCoreKit
import FacebookCore

protocol facebookHandlerDelegate {
	func didGetAllPhotos(photos: [String:[String]]?)
	func didGetMyProfile(profile: [String: Any]?)
	func didGetImage(id: String, image: UIImage?)
}
class FacebookHandler{

	
	//GETTING PHOTOS
	//	Get all photos is called which initiates the photo request
	//	after each local photo request, data is stored in global variable and getPhotosContinueFuction is called with next cursor
	//	getPhotosContinueFunction will call delegate for finished photos if it has no cursor, or it will call another photo reuqest
	
	var delegate: facebookHandlerDelegate?
	
	
	fileprivate var photosNames: [String:[String]]!	//sorted by photo id, list of names in each photo
	fileprivate var photosJSON: [[String: Any]]!
	
	fileprivate var photoOffsetIndex = 0			//tells photoRequest what offset to use
	fileprivate var photoRequestCompletionCount = 0	//tells photoRequestContinue how many requests have finished
	fileprivate var photoRequestsToMake = 1			//tells photoRequestContinue how many requests to wait for
	fileprivate var photoRequestSize = 100			//limit for photo request thing
	
	fileprivate var photosPaged: Int!
	
	
	func getAllPhotos(delegate: facebookHandlerDelegate){
		self.delegate = delegate
		photosJSON = [[String:Any]]()
		
		photoOffsetIndex = 0
		photoRequestCompletionCount = 0
		
		for i in 0..<photoRequestsToMake{
			photoRequest(afterCursor: nil) { (afterCursor) in
				self.getPhotosContinueFunction(afterCursor: afterCursor)
			}
		}
	}
	class func getMyProfile(delegate: facebookHandlerDelegate){
		print("getting  my profile")
		let connection = GraphRequestConnection()
		var nameRequest = GraphRequest(graphPath: "/me")
		nameRequest.parameters = ["fields": "id, name, email, picture"]
		
		connection.add(nameRequest, batchEntryName: "UserName") { (httpResponse, result) in
			switch result{
			case .success(response: let response):
				var profile = [String: Any]()
				profile["name"] = response.dictionaryValue?["name"] as? String
				profile["id"] = response.dictionaryValue?["id"] as? String
				profile["email"] = response.dictionaryValue?["email"] as? String
				if let urlString = ((response.dictionaryValue?["picture"] as? [String: Any])?["data"] as? [String: Any])?["url"] as? String{
					let url = URL(string: urlString)!
					getDataFromUrl(url: url) { (data, response, error)  in
						guard let data = data, error == nil else {
							print(error)
							delegate.didGetMyProfile(profile: profile)
							return
						}
						profile["picture"] = UIImage(data: data)
						delegate.didGetMyProfile(profile: profile)
					}
				}else{
					delegate.didGetMyProfile(profile: profile)
				}
			case .failed(let error):
				print("could not get profile: \(error)")
				delegate.didGetMyProfile(profile: nil)
			}
		}
		connection.start()
	}
	
	class func getPhotosFor(ids: [String], delegate: facebookHandlerDelegate){
		var connection = GraphRequestConnection()
		var batch = [GraphRequest]()
		for id in ids{
			var request = GraphRequest(graphPath: id)
			request.parameters = ["fields": "images"]
			connection.add(request, batchEntryName: nil, completion: { (httpResponse, result) in
				switch result{
				case .success(let response):
					//print(response)
					let images = response.dictionaryValue!["images"] as! [[String: Any]]
					let url = URL(string: images.first!["source"]! as! String)!
					downloadImage(id: id, url: url, completion: { (id, image) in
						delegate.didGetImage(id: id, image: image)
					})
				case .failed(let error):
					print(error)
				}
			})
		}
		connection.start()
	}
	class func getPhotoFor(id: String, completion: @escaping (_: UIImage?) -> Void){
		var connection = GraphRequestConnection()
		var request = GraphRequest(graphPath: id)
		request.parameters = ["fields": "images"]
		connection.add(request, completion: { (httpResponse, result) in
			switch result{
			case .success(let response):
				let images = response.dictionaryValue!["images"] as! [[String: Any]]
				let url = URL(string: images.first!["source"]! as! String)!
				downloadImage(id: id, url: url, completion: { (id, image) in
					completion(image)
				})
			case .failed(let error):
				print(error)
			}
		})
		connection.start()
	}
	private class func downloadImage(id: String, url: URL, completion: @escaping (_ id: String, _ image: UIImage?) -> Void){
		getDataFromUrl(url: url) { (data, response, error)  in
			guard let data = data, error == nil else {
				print(error)
				return
			}
			completion(id, UIImage(data: data))
		}
	}
	private class func getDataFromUrl(url: URL, completion: @escaping (_ data: Data?, _  response: URLResponse?, _ error: Error?) -> Void) {
		URLSession.shared.dataTask(with: url) {
			(data, response, error) in
			completion(data, response, error)
			}.resume()
	}

}

extension FacebookHandler{
	
	fileprivate func photoRequest( afterCursor: String?, and completion: @escaping ( _ afterCursor: String?) -> Void){
		let connection = GraphRequestConnection()
		var photosRequest = GraphRequest(graphPath: "me/photos")

		//if let cursor = afterCursor{
		//	photosRequest.parameters = ["fields": "limit=1,after=\(cursor),name,tags.limit(1){name}"]
		//}else{
		//	photosRequest.parameters = ["fields": "limit=1,name,tags.limit(1){name}"]
		//}
		
		photosRequest.parameters = ["fields": "name, tags.limit(30){name}",
									"offset":"\(photoOffsetIndex)",
									"limit": "\(photoRequestSize)"]
		photoOffsetIndex = photoOffsetIndex + photoRequestSize
		
		connection.add(photosRequest) { (httpResponse, result) in
			switch result {
			case .success(let response):
				if let newPhotos = response.dictionaryValue?["data"] as? [[String: Any]]{
					//print("\nrecieved photos with offset \(photosRequest.parameters!["offset"]):")
					//print("response: \(response)")
					for photo in newPhotos{
						self.photosJSON.append(photo)
					}
				}else{
					print("ERROR: Graph Request Succeeded, but could not format photos: \(response)")
				}
				let after = ((response.dictionaryValue?["paging"] as? [String:Any])?["cursors"] as? [String: String])?["after"]
				completion(after)
			case .failed(let error):
				print("photo graph request failed: \(error)")
				completion(nil)
			}
		}
		connection.start()
	}
	fileprivate func getPhotosContinueFunction(afterCursor: String?){
		photoRequestCompletionCount = photoRequestCompletionCount + 1
		if photoRequestCompletionCount >= photoRequestsToMake{
			self.pagePhotos(photos: self.photosJSON)
		}
	}
	fileprivate func pagePhotos(photos: [[String: Any]]){
		photosPaged = 0
		photosNames = [String:[String]]()
		
		for photo in photos{
			let id = photo["id"] as! String
			photosNames[id] = names(from: photo)
			//pagePhotoTags(afterCursor: nil, id: id, completion: { (next, id) in
			//	self.pagePhotoTagsContinueFunction(afterCursor: next, id: id)
			//})
		}
		print("got \(photosNames.count) photos")
		delegate?.didGetAllPhotos(photos: photosNames)
	}
	
	//FIXME: No Paging is done for photo tags, just use request of limit 100 tags in initial request
	fileprivate func pagePhotoTags(afterCursor: String?, id: String, completion: @escaping (_ next: String?, _ id: String) -> Void){
		let connection = GraphRequestConnection()
		var tagsRequest = GraphRequest(graphPath: "\(id)")
		tagsRequest.parameters = ["limit": "100"]
		if let cursor = afterCursor{
			tagsRequest.parameters!["fields"] = "tags.after(\(cursor)){name}"
		}else{
			tagsRequest.parameters!["fields"] = "tags"
		}
		
		connection.add(tagsRequest) { (httpResponse, result) in
			switch result {
			case .success(let response):
				if let newTags = (response.dictionaryValue?["tags"] as? [String: Any])?["data"] as? [[String:Any]] {
					//print("\n\nrecieved new tags:")
					//print(newTags)
					for tag in newTags{
						if let name = self.name(from: tag){
							self.photosNames[id]!.append(name)
						}
					}
				}else{
					print("ERROR: Graph Request Succeeded, but could not format tags: \(response)")
				}
				completion(((response.dictionaryValue?["paging"] as? [String:Any])?["cursors"] as? [String:String])?["after"], id)
			case .failed(let error):
				print("Graph Request Failed: \(error)")
				completion(nil, id)
			}
			
		}
		print("Starting Photo tags Request:")
		connection.start()
	}
	fileprivate func pagePhotoTagsContinueFunction(afterCursor: String?, id: String){
		//print("in photo tags continue function")
		if afterCursor == nil{
			photosPaged = photosPaged + 1
			print("increment photos paged: \(photosPaged) out of \(photosJSON.count)")
		}else{
			pagePhotoTags(afterCursor: afterCursor!, id: id, completion: { (next, id) in
				self.pagePhotoTagsContinueFunction(afterCursor: next, id: id)
			})
		}
		if photosPaged >= photosJSON.count{
			print("\n\ndid get all photos\n\n")
			delegate?.didGetAllPhotos(photos: photosNames)
		}
	}

	
	
	
	fileprivate func afterCursor(from object: [String: Any]?) -> String?{
		return ((object?["paging"] as? [String: Any])?["cursors"] as? [String: String])?["after"]
	}
	fileprivate func photoID(of photo: [String: Any]?) -> String?{
		return photo?["id"] as? String
	}
	fileprivate func names(from photo: [String: Any]?) -> [String]?{
		var toReturn = [String]()
		if let tags = tags(from: photo){
			for tag in tags{
				if let name = name(from: tag){
					toReturn.append(name)
				}
			}
		}
		return toReturn
	}
	fileprivate func tags(from photo: [String: Any]?) -> [[String:Any]]?{
		return (photo?["tags"] as? [String: Any])?["data"] as? [[String: Any]]
	}
	fileprivate func name(from tag: [String: Any]?) -> String?{
		return tag?["name"] as? String
	}
	
}
