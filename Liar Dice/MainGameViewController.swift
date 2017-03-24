//
//  MainGameViewController.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/22/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import UIKit
import MultipeerConnectivity
import MBProgressHUD
import AVFoundation
import CoreMotion

enum Player {
	case one
	case two
	
	var color: UIColor {
		switch self {
		case .one: return #colorLiteral(red: 0.3010171547, green: 0.9053976071, blue: 0.9507030845, alpha: 1)
		case .two: return #colorLiteral(red: 0.9541491866, green: 0.1599813779, blue: 0.2722243721, alpha: 1)
		}
	}
}

class MainGameViewController: UIViewController {
	
	@IBOutlet weak var die1Label: UILabel!
	@IBOutlet weak var die2Label: UILabel!
	
	var myRoll: DiceCombination?
	var otherPlayerRoll: DiceCombination?
	
	var rollChanged: Bool = false
	
	var player: Player!
	
	var otherPlayerPeerID: MCPeerID!
	
	var shouldStopVibrations: Bool = false
	
	var hud: MBProgressHUD?
	
	let motionManager = CMMotionManager()
	let motionQueue = OperationQueue()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		peerManager.delegate = self
		
		view.backgroundColor = player.color
		
		startOtherPlayerRollVibrations()
		
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		motionManager.stopAccelerometerUpdates()
		stopOtherPlayerRollVibrations()
		
		UIApplication.shared.isIdleTimerDisabled = false
	}
	
	override func viewWillAppear(_ animated: Bool) {
		startMotionMonitor()
		startOtherPlayerRollVibrations()
		
		UIApplication.shared.isIdleTimerDisabled = true
	}
	
	var deviceIsFaceDown: Bool = false
	var otherDeviceIsFaceDown: Bool = false
	
	func startMotionMonitor() {
		motionManager.startAccelerometerUpdates(to: motionQueue) { data, error in
			guard let data = data else {
				return
			}
			
			let isUpsideDown = data.acceleration.z > 0.0
			
			if self.deviceIsFaceDown != isUpsideDown {
				self.deviceIsFaceDown = isUpsideDown
				
				DispatchQueue.main.async {
					self.deviceFlipped()
				}
			}
			
		}
	}
	
	func deviceFlipped() {
		try? peerManager.session.send(["otherDeviceUpsideDown": deviceIsFaceDown], toPeers: otherPlayerPeerID)
		
		updateDiceLabels()
		
	}
	
	func otherDeviceFlipped() {
		
		updateDiceLabels()
		
	}
	
	func updateDiceLabels() {
		
		if let myRoll = self.myRoll {
			if !deviceIsFaceDown && !otherDeviceIsFaceDown && otherPlayerRoll != nil {
				self.die1Label.text = myRoll.die1.dieSymbol
				self.die2Label.text = myRoll.die2.dieSymbol
			} else {
				self.die1Label.text = "?"
				self.die2Label.text = "?"
			}
		} else {
			self.die1Label.text = ""
			self.die2Label.text = ""
		}
		
	}
	
	override func motionBegan(_ motion: UIEventSubtype, with event: UIEvent?) {
		if motion == .motionShake {
			roll()
		}
	}
	
	func roll() {
		
		if deviceIsFaceDown {
			
			myRoll = DiceCombination()
			
			updateDiceLabels()
			
			let message = ["roll": myRoll!.arrayValue]
			
			try? peerManager.session.send(message, toPeers: otherPlayerPeerID)
			
			let soundURL = Bundle.main.url(forResource: "roll", withExtension: "m4a")!
			var rollSoundID: SystemSoundID = 0
			AudioServicesCreateSystemSoundID(soundURL as CFURL, &rollSoundID)
			AudioServicesAddSystemSoundCompletion(rollSoundID, nil, nil, { (soundId, clientData) -> Void in
				AudioServicesDisposeSystemSoundID(soundId)
			}, nil)
			AudioServicesPlaySystemSound(rollSoundID)
			
		}
	}
	
	let vibrationsQueue = DispatchQueue(label: "vibrate")
	
	func startOtherPlayerRollVibrations() {
		vibrationsQueue.async {
			
			while true {
				if self.shouldStopVibrations {
					return
				}
				
				guard let otherPlayerRoll = self.otherPlayerRoll else {
					continue
				}
				
				inner: for _ in 0 ..< otherPlayerRoll.faceValue {
					
					if self.shouldStopVibrations {
						return
					}
					
					if self.rollChanged {
						self.rollChanged = false
						break inner
					}
					
					AudioServicesPlayAlertSound(SystemSoundID(kSystemSoundID_Vibrate))
					Thread.sleep(forTimeInterval: 0.8)
					
				}
				
				if self.shouldStopVibrations {
					return
				}
				
				Thread.sleep(forTimeInterval: 2)
			}
		}
		
	}
	
	func stopOtherPlayerRollVibrations() {
		
		shouldStopVibrations = true
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		navigationController?.interactivePopGestureRecognizer?.isEnabled = false
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		navigationController?.interactivePopGestureRecognizer?.isEnabled = true
	}
	
}

extension MainGameViewController: MCManagerDelegate {
	
	func foundPeer(_ peer: MCPeerID) {
		
	}
	
	func lostPeer(_ peer: MCPeerID, at index: Int?) {
		
	}
	
	func invitationReceived(from peer: MCPeerID, invitationHandler: @escaping ((Bool, MCSession?) -> Void)) {
		invitationHandler(false, nil)
	}
	
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		
		switch state {
		case .notConnected:
			performSegue(withIdentifier: "disconnected", sender: peerID)
		default:
			break
		}
		
	}
	
	func didReceiveMessage(_ message: [String : Any]) {
		print("Received message:", message)
		
		if let message = message as? [String: [Int]],
			let roll = message["roll"],
			let diceCombination = DiceCombination(roll) {
			
			otherPlayerRoll = diceCombination
			
			rollChanged = true
		}
		
		if let otherDeviceIsUpsideDown = message["otherDeviceUpsideDown"] as? Bool {
			self.otherDeviceIsFaceDown = otherDeviceIsUpsideDown
			DispatchQueue.main.async {
				self.otherDeviceFlipped()
			}
		}
	}
	
}
