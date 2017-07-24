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
	fileprivate var photoRequestSize = 1			//limit for photo request thing
	
	fileprivate var photosPaged: Int!
	
	/*struct Photo {
		init(photoJSON: [String: Any]) {
			names = namesFrom(JSON: photo)
			afterCursor = ((photoJSON["paging"] as? [String:Any])?["cursors"] as? [String:String])?["after"]
		}
		var names: [String]
		var afterCursor: String?
	}
	*/
	
	//MARK: Initiates calls for photos
	
	/*
	
	getAllPhotos -> photoRequest -> getPhotosContinueFunction -(next cursor)> photoReququest -> getPhotosContinueFunction -(no next)> pagePhotos -(to each photo)> pagePhotoTags -> pagePHotoTagsContinueFunction -(next cursor)> pagePhotoTags -> pagePhotoTagsContinueFunction -(no next)> finishedPagingPhoto -(photo counter == photos.count)> didGetAllPhotos
	
	Initialize photos array and make initial photoRequest
	
	each photoRequest upon completion calls another getPhotosContinueFunction
	
	GetPhotosContinueFunction calls more photoRequests if there is a cursor, otherwise calls pagePhotos
	
	pagePhotos initializes photosPaged counter to zero and calls pagePhotoTags on each photo
	
	pagePhotoTags calls pagePhotoTagsContinueFunction upon completion
	
	pagePhotoTags continues paging if there is a next curser, or calls finishedPagingPhoto
	
	finishedPagingPhoto increments photosPaged, calls didGetAllPhotos when photosPaged = photos.count
	
		After all photos have been retrieved, initialize photosPaged counter to zero
		For each photo in photos, call getPhotoTags
			- upon completion, increment photosPaged. if photosPaged == photos.count, we are finished

	*/
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
	func getMyProfile(delegate: facebookHandlerDelegate){
		let connection = GraphRequestConnection()
		var nameRequest = GraphRequest(graphPath: "/me")
		nameRequest.parameters = ["fields": "id, name, email"]
		
		connection.add(nameRequest, batchEntryName: "UserName") { (httpResponse, result) in
			switch result{
			case .success(response: let response):
				delegate.didGetMyProfile(profile: response.dictionaryValue)
			case .failed(let error):
				print("name request error: \(error)")
				delegate.didGetMyProfile(profile: nil)
			}
		}
	}

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
					print("\nrecieved photos with offset \(photosRequest.parameters!["offset"]):")
					print("response: \(response)")
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
		print("Starting Photo Request:")
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
