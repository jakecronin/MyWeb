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


class NetworkViewController: UIViewController{
	
	var myName = "Jake Cronin"
	var friends = [FriendNode]()
	
	var unselectedColor = UIColor.green
	var selectedColor = UIColor.blue
	var cameraOrigin = SCNVector3Make(0, 0, 20)
	
	@IBOutlet weak var sceneView: SCNView!
	var cameraNode = SCNNode()
	var lineArray = [SCNNode]()

	
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
		print("going to graph maker to design graph")
		JCGraphMaker.sharedInstance.delegate = self
		JCGraphMaker.sharedInstance.createGraphFrom(tree: me)
	}
	
	
	//MARK: Draw Functions
	
	func drawNode(node: JCGraphNode){
		node.geometry = SCNSphere(radius: CGFloat(node.radius))
		node.position = SCNVector3Make(Float(node.x), Float(node.y), Float(node.z))
		node.geometry?.firstMaterial?.diffuse.contents = unselectedColor
		sceneView.scene!.rootNode.addChildNode(node)
		print("added node: (\(node.x), \(node.y), \(node.z))")
	}
	
	func drawText(_ coords: (Float, Float)?, text: String, radius: Float){
		if coords == nil{
			print("no coordinates found for node. Not drawing")
			return
		}
		//var size = CGSize(width: CGFloat(radius * 0.7), height: CGFloat(radius * 0.7))
		//var nsString = NSString(string: text)
		//nsString.boundingRectWithSize(size, options: NSStringDrawingOptions, attributes: nil, context: nil)
		let myWord = SCNText(string: text, extrusionDepth: 0.1)
		myWord.containerFrame = CGRect(x: CGFloat(coords!.0), y: CGFloat(coords!.1), width: CGFloat(radius * 0.7), height: CGFloat(radius * 0.7))
		let wordNode = SCNNode(geometry: myWord)
		let position = SCNVector3Make(coords!.0, coords!.1, 0)
		wordNode.position = position
		sceneView.scene!.rootNode.addChildNode(wordNode)
	}
	func drawLine(from: JCGraphNode, to: JCGraphNode){
		let indices: [Int32] = [0, 1]
		let source = SCNGeometrySource(vertices: [from.position, to.position], count: 2)
		let element = SCNGeometryElement(indices: indices, primitiveType: .line)
		let lineNode = SCNNode(geometry: SCNGeometry(sources: [source], elements: [element]))
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

