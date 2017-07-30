//
//  JCGraphObject.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

class JCGraph{
	
	var adjList: [String:[JCGraphNode]]!
	var nodes: [String: JCGraphNode]!
	var lines: [JCGraphLine]!
	var center: JCGraphNode?
	
	init(adjList: [String:[JCGraphNode]], nodes: [String: JCGraphNode], lines: [JCGraphLine]) {
		self.adjList = adjList
		self.nodes = nodes
		self.lines = lines
	}
	
}
