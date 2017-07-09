//
//  GraphMaker.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

protocol JCGraphMakerDelegate {
	func graphIsComplete(graph: JCGraphObject)
}

class JCGraphMaker{
	
	static let sharedInstance = JCGraphMaker()
	
	var delegate: JCGraphMakerDelegate?
	
	var graph: JCGraphObject!
	
	func createGraphFrom(tree: JCGraphNode){
		graph = JCGraphObject(with: tree)
	}
	
	
	
	
	
}
