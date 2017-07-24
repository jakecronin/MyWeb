//
//  GraphMaker.swift
//  MyWeb
//
//  Created by Jake Cronin on 7/9/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation

protocol JCGraphMakerDelegate {
	func graphIsComplete(graph: [String:[(node: JCGraphNode, weight: Double)]], with nodes: [String:JCGraphNode])
}

class JCGraphMaker{
	
	//Formatting Variable
	let attractScale: Double = 0.0002
	let repulsScale: Double =  0.02
	
	let max: Double = 5
	let min: Double = -5
	////////////
	
	
	static let sharedInstance = JCGraphMaker()
	var delegate: JCGraphMakerDelegate?
	var graph: JCTreeGraph!
	
	func createGraphFrom(tree: JCGraphNode){
		graph = JCTreeGraph(with: tree)
		initializeCoordinates(for: tree)
		for _ in 0..<100{
			iterateAndUpdateTree()
		}
		//delegate?.graphIsComplete(graph: graph)
	}
	func createGraphFrom(adjList: [String:[String: Int]]){
		var graph = [String:[(node: JCGraphNode, weight: Double)]]()
		var nodes = [String:JCGraphNode]()
		for name in adjList.keys{				//make friendNode out of each name
			let weight = 0.08 + (0.003 * Double(adjList[name]!.count))	//weight represents number of people that connect to this node
			let newNode = JCGraphNode(name: name, weight: weight)
			newNode.max = max
			newNode.min = min
			nodes[name] = newNode
			graph[name] = [(JCGraphNode, Double)]()
		}
		for name in adjList.keys{
			for connection in adjList[name]!{
				graph[name]!.append((nodes[connection.key]!,Double(connection.value)))
			}
		}
		
		initializeCoordinates(for: nodes, with: nodes["Jake Cronin"])
		//for i in 0..<10{
		//for _ in 0..<100{
		//		applyPhysics(to: graph, with: nodes)
		//	}
		//	print("completed physics iteration \(i)")
			delegate?.graphIsComplete(graph: graph, with: nodes)
		//}
		//print("all physics iterations completed")
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
	func applyPhysics(to graph: [String:[(node: JCGraphNode, weight: Double)]], with nodes: [String:JCGraphNode]){
		for node in graph.keys{
			for connection in graph[node]!{
				applyEdgeForce(nodeA: nodes[node]!, nodeB: connection.node, weight: connection.weight)
			}
			for otherNode in nodes.values{
				applyNodeForce(nodeA: nodes[node]!, nodeB: otherNode)
			}
		}
		for node in nodes.values{
			node.updatePosition()
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
	fileprivate func initializeCoordinates(for tree: JCGraphNode){	//calculate positions of nodes
		//Initialize other nodes at random coordinates
		for node in graph.adjacents.keys{
			node.x = rand()
			node.y = rand()
			node.z = rand()
			
			node.dz = 0
			node.dy = 0
			node.dx = 0
			
			node.updatePosition()
		}
		
		tree.dx = 0
		tree.dy = 0
		tree.dz = 0
		
		tree.x = 0
		tree.y = 0
		tree.z = 0
		
		tree.radius = 1
		
		
	}
	fileprivate func rand() -> Double{
		return (drand48() - 0.5) * 10
	}
	fileprivate func iterateAndUpdateTree(){
		for node in graph.adjacents.keys{
			for rec in node.children{
				applyEdgeForce(nodeA: node, nodeB: rec, weight: 1)
			}
			for otherNode in graph.adjacents.keys{
				applyNodeForce(nodeA: node, nodeB: otherNode)
			}
		}
		for node in graph.adjacents.keys{
			node.updatePosition()
		}
		graph.center.centerNode()
	}
}
