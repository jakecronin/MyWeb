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
import SceneKit
import FBSDKCoreKit


class NetworkViewController: UIViewController{
	
	var myName = "Jake Cronin"
	var names = [String: Int]()
	var friends = [FriendNode]()
	
	var unselectedColor = UIColor.green
	var selectedColor = UIColor.blue
	var lineColor = UIColor.gray
	var cameraOrigin = SCNVector3Make(0, 0, 20)
	
	@IBOutlet weak var sceneView: SCNView!
	var cameraNode = SCNNode()
	var lineArray = [SCNNode]()		//so I can remove them later
	var nodeArray = [SCNNode]()		//so I can remove them later

	
	override func viewDidLoad() {
		print("network view controller loaded")
		sceneSetup()
		getFriendsAndName()
	}
	func sceneSetup(){
		let scene = SCNScene()
		
		cameraNode.camera = SCNCamera()
		cameraNode.camera!.zFar = 1000
		cameraNode.position = cameraOrigin
		scene.rootNode.addChildNode(cameraNode)
		
		sceneView.showsStatistics = true
		sceneView.backgroundColor = UIColor.black
		
		sceneView.scene = scene
	}
	
	
	func getFriendsAndName(){
		names = [String: Int]()
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
					print(response)
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
		
		if let next = (result["paging"] as? [String: Any])?["next"] as? String{
			nextPhotosRequest(next: next)
		}else{
			print("\n\n\ngot all the names!!!: \n \(names)")
			makeFriendObjectsFrom(namesDictionary: names)
		}
	}
	func nextPhotosRequest(next: String){
		var nextParameters = FBSDKUtility.dictionary(withQueryString: next) as! [String: Any]
		nextParameters["fields"] = "tags"
		
		let connection = GraphRequestConnection()
		let photosRequest = GraphRequest(graphPath: "me/photos", parameters: nextParameters as! [String : Any], accessToken: AccessToken.current, httpMethod: .GET, apiVersion: .defaultVersion)
		//nameRequeset.parameters = ["fields": "id, name, email"]
		connection.add(photosRequest) { (httpResponse, result) in
			switch result {
			case .success(let response):
				if let dict = response.dictionaryValue{
					print("grpah request succeeded, going to handle post response")
					print(response)
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
		print("going to graph maker to design graph")
		JCGraphMaker.sharedInstance.delegate = self
		JCGraphMaker.sharedInstance.createGraphFrom(tree: me)
	}
	
	
	//MARK: Draw Functions
	
	func drawNode(node: JCGraphNode){
		for node in nodeArray{
			node.removeFromParentNode()
		}
		node.geometry = SCNSphere(radius: CGFloat(node.radius))
		node.position = SCNVector3Make(Float(node.x), Float(node.y), Float(node.z))
		node.geometry?.firstMaterial?.diffuse.contents = unselectedColor
		sceneView.scene!.rootNode.addChildNode(node)
		//nodeArray.append(node)
	}
	
	func drawText(on node: JCGraphNode, text: String){
		let myWord = SCNText(string: text, extrusionDepth: 0.03)
		myWord.font = UIFont.systemFont(ofSize: 0.2)
		let wordNode = SCNNode(geometry: myWord)
		var position = node.position
		position.x = position.x - 1
		position.y = position.y - 1 + Float(node.radius)
		wordNode.position = position
		sceneView.scene!.rootNode.addChildNode(wordNode)
	}
	func drawLine(from: JCGraphNode, to: JCGraphNode){
		let indices: [Int32] = [0, 1]
		let source = SCNGeometrySource(vertices: [from.position, to.position], count: 2)
		let element = SCNGeometryElement(indices: indices, primitiveType: .line)
		let lineNode = SCNNode(geometry: SCNGeometry(sources: [source], elements: [element]))
		lineNode.geometry?.firstMaterial?.diffuse.contents = lineColor
		sceneView.scene!.rootNode.addChildNode(lineNode)
		lineArray.append(lineNode)
	}
	func drawLinesForGraph(graph: JCGraphObject){
		for node in lineArray{
			node.removeFromParentNode()
		}
		for node in graph.adjacents.keys{
			for child in node.children{
				drawLine(from: node, to: child)
			}
		}
	}
	func drawNodesForGraph(graph: JCGraphObject){
		for node in graph.adjacents.keys{
			drawNode(node: node)
			if let friend = node as? FriendNode{
				guard let name = friend.friendName else{
					print("no name")
					continue
				}
				drawText(on: node, text: name)
			}
		}
	}
}

extension NetworkViewController: JCGraphMakerDelegate{
	func graphIsComplete(graph: JCGraphObject){
		print("graph is complete. going to draw it")
		drawLinesForGraph(graph: graph)
		drawNodesForGraph(graph: graph)
	}
}

