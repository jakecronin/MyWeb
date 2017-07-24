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
import OpenGLES


class NetworkViewController: UIViewController{
	
	var myName = "Jake Cronin"
	var names = [String: Int]()
	var friends = [JCGraphNode]()
	
	var unselectedColor = UIColor.green
	var selectedColor = UIColor.blue
	var lineColor = UIColor.gray
	var cameraOrigin = SCNVector3Make(0, 0, 20)
	
	@IBOutlet weak var sceneView: SCNView!
	@IBOutlet weak var collectionView: UICollectionView!
	
	
	var cameraNode = SCNNode()
	var selectedNode: JCGraphNode?
	
	var friendsGraph: [String:[(node: JCGraphNode, weight: Double)]]?
	var nodes: [String:JCGraphNode]?


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
		
		let tapRecognizer = UITapGestureRecognizer(target: self, action:  #selector(NetworkViewController.tapRecognizer(_:)))
		tapRecognizer.numberOfTapsRequired = 1
		sceneView.addGestureRecognizer(tapRecognizer)
		tapRecognizer.cancelsTouchesInView = false
		
		sceneView.scene = scene
	}
	func tapRecognizer(_ sender: UITapGestureRecognizer){
		let location = sender.location(in: sceneView)
		let hitResults = sceneView.hitTest(location, options: nil)
		if hitResults.count > 0{
			let result = hitResults[0]
			//if let node = result.node.
			guard let node = result.node as? JCGraphNode else{
				print("hit node, but it returned nil")
				return
			}
			nodeSelected(node: node)
		}
	}
	func nodeSelected(node: JCGraphNode){
		if node.selected{	//already was selectedNode
			selectedNode = nil
			nodeUnselected(node: node)
		}else{	//node tapped
			if selectedNode != nil{
				nodeUnselected(node: selectedNode!)
			}
			selectedNode = node
			node.selected = true
			node.geometry?.firstMaterial?.diffuse.contents = selectedColor
		}
	}
	func nodeUnselected(node: JCGraphNode){
		node.selected = false
		node.geometry?.firstMaterial?.diffuse.contents = unselectedColor
	}
	@IBAction func iteratePressed(sender: AnyObject){
		guard friendsGraph != nil && nodes != nil else{
			return
		}
		self.clearGraph()
		for i in 0..<100{
			JCGraphMaker.sharedInstance.applyPhysics(to: friendsGraph!, with: nodes!)
			nodes![myName]!.centerNode()
		}
		for (i, value) in nodes!{
			print("coodrinates point \(i): \(value.position)")
		}
		self.drawLinesForGraph(graph: friendsGraph!, with: nodes!)
		self.drawNodes(nodes: nodes!)
	}
}
extension NetworkViewController: UICollectionViewDelegate{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		//
	}
}
extension NetworkViewController: UICollectionViewDataSource{
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		return UICollectionViewCell()
	}
	func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
		//
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return 1
	}
}
extension NetworkViewController: UICollectionViewDelegateFlowLayout{
	
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
		node.geometry = SCNSphere(radius: CGFloat(node.radius))
		node.position = SCNVector3Make(Float(node.x), Float(node.y), Float(node.z))
		node.geometry?.firstMaterial?.diffuse.contents = unselectedColor
		sceneView.scene!.rootNode.addChildNode(node)
		//nodeArray.append(node)
	}
	func drawText(on node: JCGraphNode, text: String){
		let myWord = SCNText(string: text, extrusionDepth: CGFloat(node.radius/50))
		myWord.font = UIFont.systemFont(ofSize: CGFloat(node.radius/10))
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
	}
	func drawCylinders(from: JCGraphNode, to: JCGraphNode, weight: Double){
		let radius = CGFloat(0.01 + (weight * 0.005))
		let cylinder = makeCylinder(positionStart: from.position, positionEnd: to.position, radius: radius, color: UIColor.white.cgColor)
		sceneView.scene!.rootNode.addChildNode(cylinder)
	}
	func makeCylinder(positionStart: SCNVector3, positionEnd: SCNVector3, radius: CGFloat , color: CGColor) -> SCNNode{
		let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(positionStart), SCNVector3ToGLKVector3(positionEnd)))
		let startNode = SCNNode()
		let endNode = SCNNode()
		
		startNode.position = positionStart
		endNode.position = positionEnd
		
		let zAxisNode = SCNNode()
		zAxisNode.eulerAngles.x = Float(CGFloat(M_PI_2))
		
		let cylinderGeometry = SCNCylinder(radius: radius, height: height)
		cylinderGeometry.firstMaterial?.diffuse.contents = color
		let cylinder = SCNNode(geometry: cylinderGeometry)
		
		cylinder.position.y = Float(-height/2)
		zAxisNode.addChildNode(cylinder)
		
		let returnNode = SCNNode()
		
		if (positionStart.x > 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
		{
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}
		else if (positionStart.x < 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0)
		{
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}
		else if (positionStart.x < 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
		{
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}
		else if (positionStart.x > 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0)
		{
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}
		else
		{
			startNode.addChildNode(zAxisNode)
			startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
			returnNode.addChildNode(startNode)
		}
		
		return returnNode
	}
	
	func drawLinesForGraph(graph: [String:[(node: JCGraphNode, weight: Double)]], with nodes: [String:JCGraphNode]){
		for name in nodes.keys{
			for connection in graph[name]!{
				//drawLine(from: nodes[name]!, to: connection.node, weight: connection.weight)
				drawCylinders(from: nodes[name]!, to: connection.node, weight: connection.weight)
			}
		}
	}
	func drawNodes(nodes: [String:JCGraphNode]){
		for node in nodes.values{
			drawNode(node: node)
			drawText(on: node, text: node.name!)
		}
	}
	func clearGraph(){
		for node in sceneView.scene!.rootNode.childNodes{
			node.removeFromParentNode()
		}
	}
}
extension NetworkViewController: JCGraphMakerDelegate{
	func graphIsComplete(graph: [String:[(node: JCGraphNode, weight: Double)]], with nodes: [String:JCGraphNode]){
		self.clearGraph()
		print("graph is complete, going to draw it")
		self.drawLinesForGraph(graph: graph, with: nodes)
		self.drawNodes(nodes: nodes)
		self.nodes = nodes
		self.friendsGraph = graph
		print("finished drawing, nodes: \(sceneView.scene!.rootNode.childNodes.count)")
	}
}
