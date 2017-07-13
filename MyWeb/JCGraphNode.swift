//
//  GraphNode.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import SceneKit


class JCGraphNode: SCNNode{
	
	//coordinates
	
	var x: Double = 0
	var y: Double = 0
	var z: Double = 0
	
	var dx: Double = 0
	var dy: Double = 0
	var dz: Double = 0
	
	var radius: Double = 0.3
	
	var weight: Double = 1
	
	var children = [JCGraphNode]()
	
	init(weight: Double) {
		super.init()
		self.weight = weight
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	func updatePosition(){
		x = x + dx
		y = y + dy
		z = z + dz
		
		dx = 0
		dy = 0
		dz = 0
		
		self.position = SCNVector3Make(Float(x), Float(y), Float(z))
	}
	func centerNode(){
		x = 0
		y = 0
		z = 0
	}
	
}
