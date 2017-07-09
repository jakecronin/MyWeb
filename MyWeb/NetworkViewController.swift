//
//  NetworkViewController.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/8/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import UIKit
import FacebookCore


class NetworkViewController: UIViewController{
	
	var myName = "Jake Cronin"
	var friends = [FriendNode]()
	
	override func viewDidLoad() {
		print("network view controller loaded")
		
		getFriendsAndName()
	}

	//me -> photos -> photo -> tagged
	
	
	func getFriendsAndName(){
		let connection = GraphRequestConnection()
	
		
		//GET Name
		var nameRequest = GraphRequest(graphPath: "/me")
		nameRequest.parameters = ["fields": "id, name, email"]
		
		connection.add(nameRequest, batchEntryName: "UserName") { (httpResponse, result) in
			switch result{
			case .success(response: let response):
				print("response succeeded for name: \(response)")
			case .failed(let error):
				print("name request error: \(error)")
			}
		}
		
	
		//Get Friends from Photo Tags
		var photosRequest = GraphRequest(graphPath: "me/photos")
		photosRequest.parameters = ["fields": "tags"]
		connection.add(photosRequest, batchParameters: ["depends_on": "UserName"]) { (httpResponse, result) in
			switch result {
			case .success(let response):
				if let dict = response.dictionaryValue{
					print("grpah request succeeded, going to handle post response")
					//print(response)
					self.getNamesFromPhotosResponse(result: dict)
				}else{
					print("ERROR: Graph Request Succeeded, but could not make dictionary.: \(response)")
				}
			case .failed(let error):
				print("Graph Request Failed: \(error)")
			}
		}
		connection.start()
	}
	
	func getNamesFromPhotosResponse(result: Dictionary<String, Any>){
		print("handling post response")
		
		var names = [String: Int]()
		
		guard let photos = result["data"] as? [Dictionary<String, Any>] else{
			print("unable to make photos array")
			return
		}
		
		for photo in photos{
			
			guard let tags = photo["tags"] as? Dictionary<String, Any> else{
				print("unable to get tags from photo")
				return
			}
			guard let tagArray = tags["data"] as? [Dictionary<String, Any>] else{
				print("unable to make tag array ")
				return
			}
			for tag in tagArray{
				guard let name = tag["name"] as? String else{
					print("unable to get name in tag")
					return
				}
				if names[name] == nil{
					names[name] = 1
				}else{
					names[name] = names[name]! + 1
				}
			}
		}
		print("\n\n\ngot all the names!!!: \n \(names)")
		makeFriendObjectsFrom(namesDictionary: names)
	}
	
	func makeFriendObjectsFrom(namesDictionary: Dictionary<String, Int>){
	
		friends = [FriendNode]()
		let me = FriendNode(name: myName, weight: Double(namesDictionary[myName]!))
		friends.append(me)
		
		for friend in namesDictionary.keys{
			guard friend != myName else{
				continue
			}
			let newFriend = FriendNode(name: friend, weight: Double(namesDictionary[friend]!))
			newFriend.children.append(me)
			me.children.append(newFriend)
			friends.append(newFriend)
		}
		JCGraphMaker.sharedInstance.delegate = self
		JCGraphMaker.sharedInstance.createGraphFrom(tree: me)
	}
}

extension NetworkViewController: JCGraphMakerDelegate{
	func graphIsComplete(graph: JCGraphObject){
		print("got graph")
	}
}


//Draws 'Drawable' Objects, contain certain variables, aka coordinates
//Draws graphs, must be an adjacency list of drawable objects



/*
	Steps: 

	1. Loads in data from facebook (friends for now)
	2. Put friends into FriendNode objects
	3. Build a JCGraph Object
	4. Send JCGraph Object to GraphMaker -> spaces out the nodes
	5. Draw the finished graph





	
	Create Drawable objects with friends
		-Friend, Coordinates,

	Friends inserted into Graph object
	
	Send graph to GraphMaker (takes adjacency list)

	GraphMaker spaces out the objects and sends them back


	Friends are inserted into an adjacency list (array of lists, just 1 long at first for me)
	Firends array: [Me, Jimmy, Scott, John, Caleb]
	[

	]



*/
