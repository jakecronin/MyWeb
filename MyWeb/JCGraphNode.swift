//
//  GraphNode.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation


class JCGraphNode: NSObject{
	
	//coordinates
	
	var x: Double = 0
	var y: Double = 0
	var z: Double = 0
	
	var dx: Double = 0
	var dy: Double = 0
	var dz: Double = 0
	
	var weight: Double = 1
	
	var children = [JCGraphNode]()
	
	init(weight: Double) {
		self.weight = weight
	}
	
}
