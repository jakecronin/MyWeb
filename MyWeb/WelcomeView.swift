//
//  WelcomeView.swift
//  MyWeb
//
//  Created by Jake Cronin on 8/11/17.
//  Copyright © 2017 Jake Cronin. All rights reserved.
//

import Foundation
import UIKit

class WelcomeView: UIViewController{
	
	
	//MARK: UILabels
	@IBOutlet weak var welcomeLabel: UILabel!
	@IBOutlet weak var purposeLabel: UILabel!
	@IBOutlet weak var noneLabel: UILabel!
	@IBOutlet weak var introLabel: UILabel!
	@IBOutlet weak var descriptionLabel: UILabel!
	@IBOutlet weak var dotsLabel: UILabel!
	@IBOutlet weak var linesLabel: UILabel!
	@IBOutlet weak var tapToContinueLabel: UILabel!
	
	var animate = true
	var taps = 1
	var labels: [UILabel]!
	var timer = Timer()
	
	override func viewDidLoad() {
		labels = [welcomeLabel, purposeLabel, noneLabel, introLabel, descriptionLabel, dotsLabel, linesLabel, tapToContinueLabel]
		if animate{
			print("setting up for animate")
			let tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(WelcomeView.tapRegistered))
			self.view.addGestureRecognizer(tapRecognizer)
			taps = 0
			updateLabels()
			runTimer()
		}else{
			for label in labels{
				label.alpha = 1
			}
		}
	}
	
	
	func tapRegistered(){
		taps = taps + 1
		//Reset Timer
		if taps > labels.count{
			performSegue(withIdentifier: "segueNetworkViz", sender: self)
		}else{
			updateLabels()
			runTimer()
		}
	}
	func updateLabels(){
		if animate{
			UIView.animate(withDuration: 0.3, animations: {
				for (index, label) in self.labels.enumerated(){
					if index <= self.taps{
						label.alpha = 1
					}else{
						label.alpha = 0
					}
				}
			})
			
		}
	}
	func timerTicked(){
		guard taps < labels.count else{
			return
		}
		taps = taps + 1
		updateLabels()
	}
	
	func runTimer() {
		timer.invalidate()
		timer = Timer.scheduledTimer(timeInterval: 2, target: self,   selector: (#selector(WelcomeView.timerTicked)), userInfo: nil, repeats: true)
	}
	
}
