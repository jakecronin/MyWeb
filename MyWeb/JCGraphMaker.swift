//
//  GraphMaker.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

protocol JCGraphMakerDelegate {
	func graphIsComplete(graph: JCGraph)
}

class JCGraphMaker{
	
	//Formatting Variable
	let attractScale: Double = 0.0004
	let repulsScale: Double =  0.02
	
	let max: Double = 10
	let min: Double = -10
	////////////
	
	static let sharedInstance = JCGraphMaker()
	var delegate: JCGraphMakerDelegate?
	
	
	func createGraphFrom(connections: [String:[String: [String]?]]){
		//recieve list with [name-> [name of connection ->[id of photos]]
		var adjList = [String:[JCGraphNode]]()	//relating person name to neighboring nodes
		var nodes = [String:JCGraphNode]()		//relating person name to a node
		var lines = [JCGraphLine]()
		var center: JCGraphNode?
		
		
		for friend in connections{	//make friendNode out of each name
			let weight = 0.08 + (0.003 * Double(friend.value.count))	//weight represents number of people that connect to this node
			let newNode = JCGraphNode(name: friend.key, weight: weight)
			newNode.max = max
			newNode.min = min
			nodes[friend.key] = newNode
			adjList[friend.key] = [JCGraphNode]()
		}
		
		for node in nodes{	//for each friend's connection dictionary
			for connection in connections[node.key]!{	//for each connection dictionary to photo id array
				let nodeB = nodes[connection.key]!
				adjList[node.key]!.append(nodeB)
				let ids = connection.value
				if adjList[nodeB.name!]!.count == 0{	//didn't visit B node yet, reverse line was not already added
					lines.append(JCGraphLine(nodeA: node.value, nodeB: nodeB, ids: ids))
				}else{
				}
			}
		}
		var graph = JCGraph(adjList: adjList, nodes: nodes, lines: lines)
		if let name = myProfile?["name"] as? String{
			graph.center = graph.nodes[name]
		}
		initializeCoordinates(for: nodes, with: graph.center)
		
		delegate?.graphIsComplete(graph: graph)
	}
	fileprivate func initializeCoordinates(for nodes: [String:JCGraphNode], with center: JCGraphNode?){
		for node in nodes.values{
			node.x = rand()
			node.y = rand()
			node.z = rand()
			
			node.dz = 0
			node.dy = 0
			node.dx = 0
			
			node.updatePosition()
			node.radius = node.weight
		}
		if center != nil{
			center!.x = 0
			center!.y = 0
			center!.z = 0
			center!.updatePosition()
		}
	}
	func applyPhysics(to graph: JCGraph){
		for line in graph.lines{
			applyEdgeForce(nodeA: line.nodeA, nodeB: line.nodeB, weight: line.weight)
		}
		for nodeA in graph.nodes{
			for nodeB in graph.nodes{
				applyNodeForce(nodeA: nodeA.value, nodeB: nodeB.value)
			}
		}
		for node in graph.nodes{
			node.value.updatePosition()
			if node.value == graph.center{
				node.value.centerNode()
			}
		}
	}
	
	func applyEdgeForce(nodeA: JCGraphNode, nodeB: JCGraphNode, weight: Double){
		//pull edges together
		//longer edges have stronger pull, luke rubber band
		
		//calculate components of separation between nodes
		
		let dx = nodeA.x - nodeB.x
		let dy = nodeA.y - nodeB.y
		let dz = nodeA.z - nodeB.z
		
		let forceAttract = (dx * dx) + (dy * dy) + (dz * dz)	//separation distance squared
		var separationDistance = sqrt(forceAttract)
		if separationDistance <= 0{
			return
		}else if separationDistance < 0.000000001{
			separationDistance = 0.000000001
		}
		
		var scaledForce = forceAttract * attractScale * (weight * 10)
		if scaledForce > separationDistance{
			scaledForce = separationDistance
		}
		
		nodeA.dx = nodeA.dx - scaledForce * (dx / separationDistance)
		nodeA.dy = nodeA.dy - scaledForce * (dy / separationDistance)
		nodeA.dz = nodeA.dz - scaledForce * (dz / separationDistance)
		
		nodeB.dx = nodeB.dx + scaledForce * (dx / separationDistance)
		nodeB.dy = nodeB.dy + scaledForce * (dy / separationDistance)
		nodeB.dz = nodeB.dz + scaledForce * (dz / separationDistance)
		
	}
	func applyNodeForce(nodeA: JCGraphNode, nodeB: JCGraphNode){
		
		let dx = nodeA.x - nodeB.x
		let dy = nodeA.y - nodeB.y
		let dz = nodeA.z - nodeB.z
		
		var separationDistance = sqrt((dx*dx) + (dy*dy) + (dz*dz))	//length of distance
		
		//print("repulsive force: \(repulsScale) / \(separationDistance) = \(repulsiveForce)")
		if separationDistance == 0{
			separationDistance = 0.000000001
		}
		
		var repulsiveForce = repulsScale / separationDistance
		if repulsiveForce.isNaN{
			repulsiveForce = 0
		}
		if repulsiveForce.isInfinite{
			repulsiveForce = Double.greatestFiniteMagnitude
		}
		if repulsiveForce > 10{
			repulsiveForce = 10
		}

		nodeA.dx = nodeA.dx + repulsiveForce * (dx / separationDistance) //cos(xyAngle)
		nodeA.dy = nodeA.dy + repulsiveForce * (dy / separationDistance)//sin(xyAngle)
		nodeA.dz = nodeA.dz + repulsiveForce * (dz / separationDistance)//cos(yzAngle)
		
		nodeB.dx = nodeB.dx - repulsiveForce * (dx / separationDistance)
		nodeB.dy = nodeB.dy - repulsiveForce * (dy / separationDistance)
		nodeB.dz = nodeB.dz - repulsiveForce * (dz / separationDistance)
		
	}

	//FIXME: Note, these tree functions are now deprecated
	fileprivate func rand() -> Double{
		return (drand48() - 0.5) * 10
	}


}







