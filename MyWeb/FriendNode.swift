//
//  FriendNode.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

class FriendNode: JCGraphNode{
	
	var friendName: String!
	
	override init(name: String, weight: Double) {
		super.init(weight: weight)
		friendName = name
	}
	
	required init?(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}
	
}
