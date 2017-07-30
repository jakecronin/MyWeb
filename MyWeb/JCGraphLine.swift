//
//  JCGraphLine.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/29/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import SceneKit

class JCGraphLine: SCNNode{
	
	var nodeA: JCGraphNode!
	var nodeB: JCGraphNode!
	
	var weight: Double!
	
	var ids: [String]?
	
	init(nodeA: JCGraphNode, nodeB: JCGraphNode, ids: [String]?) {
		super.init()
		self.nodeA = nodeA
		self.nodeB = nodeB
		self.ids = ids
		self.weight = Double(ids!.count)
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
	
	
	
	
	
	
	
	
	
	
	
	
}
