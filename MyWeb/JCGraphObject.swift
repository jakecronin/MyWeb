//
//  JCGraphObject.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

class JCGraphObject{
	
	var adjacents: [JCGraphNode: [JCGraphNode]]!
	
	init(with tree: JCGraphNode) {
		adjacents = [JCGraphNode: [JCGraphNode]]()
		recursAdd(node: tree)
	}
	
	fileprivate func recursAdd(node: JCGraphNode){
		adjacents[node] = node.children
		
		for child in node.children{
			if adjacents[child] == nil{
				recursAdd(node: child)
			}
		}
	}
	
}
