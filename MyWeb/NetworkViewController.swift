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
	
	var myName: String?
	
	var unselectedColor = UIColor.green
	var selectedColor = UIColor.blue
	var lineUnselectedColor = UIColor.gray
	var lineSelectedColor = UIColor.orange
	var cameraOrigin = SCNVector3Make(0, 0, 20)
	
	var showNameLabels = false
	
	@IBOutlet weak var sceneView: SCNView!
	@IBOutlet weak var collectionView: UICollectionView!
	
	@IBOutlet weak var profileView: UIView!
	@IBOutlet weak var profPic: UIImageView!
	@IBOutlet weak var nameLabel: UILabel!

	@IBOutlet weak var twoView: UIView!
	@IBOutlet weak var leftPic: UIImageView!
	@IBOutlet weak var rightPic: UIImageView!
	@IBOutlet weak var leftName: UILabel!
	@IBOutlet weak var rightName: UILabel!

	
	var cameraNode = SCNNode()
	var selectedNode: SCNNode?
	
	var namesByPhoto: [String:[String]]?			//photo id -> names of tagged people
	var photosByName: [String:[String]]?			//name -> photo ids
	var connections: [String:[String: [String]]]? //Jake -> [Friend:[photo ID of photos with Jake and Friend]]
	var friendsGraph: JCGraph?
	
	var images: [UIImage]?{
		didSet{
			imagesUpdated()
		}
	}
	var imageIDHash = [String: UIImage]()	//all downlaoded images by ID
	var userProfPicHash = [String: String]()	//User name and ID of picture to be used as their profile pic (least tags)
	var myProfile = [String:Any]()	//first string is the profile ID. next dictionary contains name, email, picture, etc


	override func viewDidLoad() {
		print("network view controller loaded")
		leftPic.layer.cornerRadius = 10
		rightPic.layer.cornerRadius = 10
		leftPic.clipsToBounds = true
		sceneSetup()
		FacebookHandler.getMyProfile(delegate: self)
		let facebookHandler = FacebookHandler()
		facebookHandler.getAllPhotos(delegate: self)	//graph greated in didGetAllPhotosDelegate
	}
	override func viewWillAppear(_ animated: Bool) {
		refreshPressed(sender: nil)
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
			nodeTapped(node: hitResults[0].node)
		}
	}
	func nodeTapped(node: SCNNode){
		//Node was already selected
		if node == selectedNode{	//already was selectedNode
			selectedNode = nil
			nodeUnselected(node: node)
		}else{	//new node selected
			if selectedNode != nil{
				nodeUnselected(node: selectedNode!)
			}
			selectedNode = node
			nodeSelected(node: node)
		}
	}
	func nodeSelected(node: SCNNode){
		if let n = node as? JCGraphNode{
			//get image for this person
			UIView.animate(withDuration: 0.2, animations: {
				n.geometry?.firstMaterial?.diffuse.contents = self.selectedColor
				self.profileView.alpha = 1
				self.nameLabel.text = n.name
				self.getProfPic(for: n.name, completion: { (image) in
					self.profPic.image = image
				})
				
			})
			n.selected = true
		}else if let n = node.parent?.parent?.parent as? JCGraphLine{
			UIView.animate(withDuration: 0.2, animations: {
				self.twoView.alpha = 1
				node.geometry?.firstMaterial?.diffuse.contents = self.lineSelectedColor
				node.parent?.geometry?.firstMaterial?.diffuse.contents = self.lineSelectedColor
				node.parent?.parent?.geometry?.firstMaterial?.diffuse.contents = self.lineSelectedColor
				self.leftName.text = n.nodeA.name
				self.rightName.text = n.nodeB.name
				self.getProfPic(for: n.nodeA.name, completion: { (image) in
					self.leftPic.image = image?.rounded(radius: 5)
				})
				self.getProfPic(for: n.nodeB.name, completion: { (image) in
					self.rightPic.image = image?.rounded(radius: 5)
				})
			})
			print("ids: \(n.ids)")
			FacebookHandler.getPhotosFor(ids: n.ids!, delegate: self)
		}
	}
	func nodeUnselected(node: SCNNode){
		if let n = node as? JCGraphNode{
			n.selected = false
			self.profPic.image = nil
			UIView.animate(withDuration: 0.2, animations: {
				n.geometry?.firstMaterial?.diffuse.contents = self.unselectedColor
				self.profileView.alpha = 0
			})
		}else if let n = node.parent?.parent?.parent as? JCGraphLine{
			images = nil
			self.leftPic.image = nil
			self.rightPic.image = nil
			UIView.animate(withDuration: 0.2, animations: {
				self.twoView.alpha = 0
				node.geometry?.firstMaterial?.diffuse.contents = self.lineUnselectedColor
				node.parent?.geometry?.firstMaterial?.diffuse.contents = self.lineUnselectedColor
				node.parent?.parent?.geometry?.firstMaterial?.diffuse.contents = self.lineUnselectedColor
			})
		}
	}
	
	func getProfPic(for user: String?, completion: @escaping (UIImage?) -> Void){
		print("staring to get prof pic for \(user)")
		guard user != nil else{
			completion(nil)
			return
		}
		var picID = userProfPicHash[user!]
		if picID == nil{	//Calculate whicdh pic has least people tagged
			print("have not yet grabbed id for this user's prof pic")
			guard (photosByName?[user!] != nil && namesByPhoto != nil) else{
				print("either photosbyname or namesbyphoto is nil")
				completion(nil)
				return
			}
			picID = photosByName![user!]!.first
			var min = namesByPhoto![picID!]!.count
			for photo in photosByName![user!]!{
				if namesByPhoto![photo]!.count < min{
					picID = photo
					min = namesByPhoto![photo]!.count
					print("found the prof pic id for \(user)")
				}
			}
		}
		guard picID != nil else{
			print("can't get prof pic for user")
			completion(nil)
			return
		}
		getPic(with: picID!, completion: completion)
	}
	func getPic(with id: String, completion: @escaping (_: UIImage?) -> Void){
		print("getting the actualy pic")
		if let image = imageIDHash[id]{
			print("got image. it was already in the image hash")
			completion(image)
		}else{
			print("image not already hashed, going to download it")
			FacebookHandler.getPhotoFor(id: id, completion: { (image) in
				
				if image != nil{
					print("successfully loaded a photo")
					self.imageIDHash[id] = image
				}else{
				print("image did NOT load succesfully")
				}
				completion(image)
			})
		}
	}
	
	@IBAction func refreshPressed(sender: AnyObject?){
		guard friendsGraph != nil else{
			return
		}
		self.clearGraph()
		for i in 0..<100{
			JCGraphMaker.sharedInstance.applyPhysics(to: friendsGraph!)
		}
		if (myName != nil){
			friendsGraph?.nodes[myName!]!.centerNode()
		}
		self.drawNodes(nodes: friendsGraph!.nodes)
		self.drawLines(lines: friendsGraph!.lines)

	}
	func imagesUpdated(){
		print("images updated")
		DispatchQueue.main.async {
			guard self.images != nil else{
				self.collectionView.isHidden = true
				return
			}
			self.collectionView.reloadData()
			self.collectionView.isHidden = false
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "segueImageView"{
			let controller = segue.destination as! ImageScrollerViewController
			controller.images = images
		}else if segue.identifier == "segueSettings"{
			let controller = segue.destination as! SettingsViewController
			controller.networkVizController = self
		}
	}
	
	@IBAction func profileViewTapped(sender: AnyObject){
		guard selectedNode != nil else{
			return
		}
		nodeUnselected(node: selectedNode!)
	}
	@IBAction func twoViewTapped(sender: AnyObject){
		guard selectedNode != nil else{
			return
		}
		nodeUnselected(node: selectedNode!)
	}

 
}
extension NetworkViewController: UICollectionViewDelegate{
	func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
		print("selected an item on collection view")
		if let cell = collectionView.cellForItem(at: indexPath) as? ImageCell{
			performSegue(withIdentifier: "segueImageView", sender: images)
		}
	}
}
extension NetworkViewController: UICollectionViewDataSource{
	func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "imageCell", for: indexPath) as! ImageCell
		cell.imageView.image = images![indexPath.row]
		return cell
	}
	func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		guard images != nil else{
			return 0
		}
		return images!.count
	}
}
extension NetworkViewController: UICollectionViewDelegateFlowLayout{
	
}
extension NetworkViewController: facebookHandlerDelegate{
	func didGetMyProfile(profile: [String : Any]?) {
		myProfile = profile!
		if let myName = profile?["name"] as? String{
			userProfPicHash[myName] = myName //there is no ID for main user's prof pic, so ID is just your name
			imageIDHash[myName] = profile?["picture"] as? UIImage
		}
	}
	func didGetAllPhotos(photos: [String : [String]]?) {
		//print("got all photos: \(photos)")
		guard photos != nil else{
			return
		}
		//Build adjacency list out of photos by names of tagged users. Intersection is list of id's
		var graph = [String:[String: [String]]]() //Jake -> [Friend:[photo ID of photos with Jake and Friend]]
		photosByName = [String:[String]]()			//name -> photo ids
		for photo in photos!{
			for name in photo.value{
				if graph[name] == nil{
					graph[name] = [String: [String]]()
				}
				/*Go through all other tagged
				people in photo and insert them or increment their counter*/
				for tagged in photo.value{
					guard tagged != name else{
						continue
					}
					if graph[name]![tagged] == nil{			//build graph
						graph[name]![tagged] = [String]()
					}
					graph[name]![tagged]!.append(photo.key)
					
					if photosByName![name] == nil{			//build photosByName
						photosByName![name] = [String]()
					}
					photosByName![name]!.append(photo.key)
				}
			}
		}
		print("Got \(graph.keys.count) names")
		self.connections = graph
		self.namesByPhoto = photos
		JCGraphMaker.sharedInstance.delegate = self
		JCGraphMaker.sharedInstance.createGraphFrom(connections: graph)
	}
	func didGetImage(id: String, image: UIImage?){
		guard image != nil else{
			print("image nil in didGetImages")
			return
		}
		if images == nil{
			images = [image!]
		}else{
			images!.append(image!)
			imageIDHash[id] = image
		}
	}
}
extension NetworkViewController{
	//MARK: Draw Functions
	func drawNode(node: JCGraphNode){
		node.geometry = SCNSphere(radius: CGFloat(node.radius))
		node.position = SCNVector3Make(Float(node.x), Float(node.y), Float(node.z))
		node.geometry?.firstMaterial?.diffuse.contents = unselectedColor
		//node.constraints = [SCNLookAtConstraint(target: cameraNode)]
		sceneView.scene!.rootNode.addChildNode(node)

	}
	func drawText(on node: JCGraphNode, text: String){
		let myWord = SCNText(string: text, extrusionDepth: CGFloat(node.radius/50))
		myWord.font = UIFont.systemFont(ofSize: CGFloat(node.radius))
		let wordNode = SCNNode(geometry: myWord)
		node.addChildNode(wordNode)
		wordNode.position = SCNVector3Make(Float(-1*node.radius*4), -1 + Float(node.radius), 0)

	}
	func drawCylinder(with line: JCGraphLine) -> SCNNode{
		
		let positionStart = line.nodeA.position
		let positionEnd = line.nodeB.position
		
		let radius = CGFloat(0.01 + (line.weight * 0.005))
		let height = CGFloat(GLKVector3Distance(SCNVector3ToGLKVector3(positionStart), SCNVector3ToGLKVector3(positionEnd)))
		
		let startNode = SCNNode()
		let endNode = SCNNode()
		startNode.position = positionStart
		endNode.position = positionEnd
		
		let zAxisNode = SCNNode()
		zAxisNode.eulerAngles.x = Float(CGFloat(M_PI_2))
		
		let cylinderGeometry = SCNCylinder(radius: radius, height: height)
		cylinderGeometry.firstMaterial?.diffuse.contents = lineUnselectedColor
		let cylinder = SCNNode(geometry: cylinderGeometry)
		
		cylinder.position.y = Float(-height/2)
		zAxisNode.addChildNode(cylinder)
		
		var returnNode = line
		for node in returnNode.childNodes{
			node.removeFromParentNode()
		}
		
		if (positionStart.x > 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0){
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}else if (positionStart.x < 0.0 && positionStart.y < 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y < 0.0 && positionEnd.z > 0.0){
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}else if (positionStart.x < 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x < 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0){
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}else if (positionStart.x > 0.0 && positionStart.y > 0.0 && positionStart.z < 0.0 && positionEnd.x > 0.0 && positionEnd.y > 0.0 && positionEnd.z > 0.0){
			endNode.addChildNode(zAxisNode)
			endNode.constraints = [ SCNLookAtConstraint(target: startNode) ]
			returnNode.addChildNode(endNode)
			
		}else{
			startNode.addChildNode(zAxisNode)
			startNode.constraints = [ SCNLookAtConstraint(target: endNode) ]
			returnNode.addChildNode(startNode)
		}
		sceneView.scene!.rootNode.addChildNode(returnNode)
		//print("drew line at position \(cylinder.position)")
		return returnNode
	}
	
	func drawLines(lines: [JCGraphLine]){
		for line in lines{
			drawCylinder(with: line)
		}
	}
	func drawNodes(nodes: [String:JCGraphNode]){
		for node in nodes.values{
			drawNode(node: node)
			if (showNameLabels){
				drawText(on: node, text: node.name!)
			}
		}
	}
	func clearGraph(){
		for node in sceneView.scene!.rootNode.childNodes{
			node.removeFromParentNode()
		}
	}
}
extension NetworkViewController: JCGraphMakerDelegate{
	func graphIsComplete(graph: JCGraph){
		self.clearGraph()
		for i in 0..<100{
			JCGraphMaker.sharedInstance.applyPhysics(to: graph)
		}
		self.drawNodes(nodes: graph.nodes)
		self.drawLines(lines: graph.lines)
		self.friendsGraph = graph
		print("finished drawing, nodes: \(sceneView.scene!.rootNode.childNodes.count)")
	}
}







