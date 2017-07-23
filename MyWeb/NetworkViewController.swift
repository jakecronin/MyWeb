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
		let facebookHandler = FacebookHandler()
		facebookHandler.getAllPhotos(delegate: self)	//graph greated in didGetAllPhotosDelegate
		//get coordinates for nodes in graph (JCGraphMaker)
		//draw graph
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

	
	//FIXME: MakeFriendObjectsFrom is deprecated, delete when you want
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
	
}
extension NetworkViewController: facebookHandlerDelegate{
	func didGetMyProfile(profile: [String : Any]?) {
		//
	}
	func didGetAllPhotos(photos: [String : [String]]?) {
		print("got all photos: \(photos)")
		guard photos != nil else{
			return
		}
		var graph = [String:[String: Int]]()
		for photo in photos!.values{
			for name in photo{
				if graph[name] == nil{
					graph[name] = [String: Int]()
				}
				/*Go through all other tagged
				people in photo and insert them or increment their counter*/
				for tagged in photo{
					guard tagged != name else{
						continue
					}
					if graph[name]![tagged] == nil{
						graph[name]![tagged] = 1
					}else{
						graph[name]![tagged] = graph[name]![tagged]! + 1
					}
				}
			}
		}
		print("\n\nall the names \(graph.keys.count): \(graph)")
		JCGraphMaker.sharedInstance.delegate = self
		JCGraphMaker.sharedInstance.createGraphFrom(adjList: graph)
	}
}
extension NetworkViewController{
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
	func drawLine(from: JCGraphNode, to: JCGraphNode, weight: Double){
		let indices: [Int32] = [0, 1]
		let source = SCNGeometrySource(vertices: [from.position, to.position], count: 2)
		let element = SCNGeometryElement(indices: indices, primitiveType: .line)
		let lineNode = SCNNode(geometry: SCNGeometry(sources: [source], elements: [element]))
		lineNode.geometry?.firstMaterial?.diffuse.contents = lineColor
		sceneView.scene!.rootNode.addChildNode(lineNode)
		lineArray.append(lineNode)
	}
	
	func drawLinesForGraph(graph: [String:[(node: JCGraphNode, weight: Double)]]){
		
	}
	func drawNodesForGraph(graph: [String:[(node: JCGraphNode, weight: Double)]]){
		
	}
	
	//FIXME: Deprecated for tree, aka noncyclical graph
	func drawLinesForTree(graph: JCTreeGraph){
		for node in lineArray{
			node.removeFromParentNode()
		}
		for node in graph.adjacents.keys{
			for child in node.children{
				drawLine(from: node, to: child, weight: 0)
			}
		}
	}
	func drawNodesForTree(graph: JCTreeGraph){
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
	func graphIsComplete(graph: [String:[(node: JCGraphNode, weight: Double)]], withNodes: [String:JCGraphNode]){
		print("graph is complete, going to draw it")
		drawLinesForGraph(graph: graph)
		drawNodesForGraph(graph: graph)
	}
}

