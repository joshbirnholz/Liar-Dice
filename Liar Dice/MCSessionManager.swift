//
//  MCSessionManager.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/20/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import UIKit
import MultipeerConnectivity

protocol MCManagerDelegate: class {
	func foundPeer(_ peer: MCPeerID)
	func lostPeer(_ peer: MCPeerID, at index: Int?)
	func invitationReceived(from peer: MCPeerID, invitationHandler: @escaping ((Bool, MCSession?) -> Void))
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState)
	func didReceiveMessage(_ message: [String: Any])

}

class MCSessionManager: NSObject {
	
	weak var delegate: MCManagerDelegate?
	
	var session: MCSession
	var peer: MCPeerID
	var browser: MCNearbyServiceBrowser
	var advertiser: MCNearbyServiceAdvertiser
	
	var foundPeers: [MCPeerID] = []
	
	override init() {
		let serviceType = "JBLiarDice"
		
		peer = MCPeerID(displayName: UIDevice.current.name)
		session = MCSession(peer: peer, securityIdentity: nil, encryptionPreference: .none)
		browser = MCNearbyServiceBrowser(peer: peer, serviceType: serviceType)
		advertiser = MCNearbyServiceAdvertiser(peer: peer, discoveryInfo: nil, serviceType: serviceType)
		
		super.init()
		
		session.delegate = self
		browser.delegate = self
		advertiser.delegate = self
	}
	
}

extension MCSessionManager: MCSessionDelegate {
	
	func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
		// TODO
		
		if let dictionary = NSKeyedUnarchiver.unarchiveObject(with: data) as? [String: Any] {
			delegate?.didReceiveMessage(dictionary)
		}
		
		print("Received unknown data from peer")
	}
	
	func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
		print("Started receiving resource \(resourceName) from \(peerID.displayName)")
	}
	
	func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL, withError error: Error?) {
		print("Finished receiving resource \(resourceName) from \(peerID.displayName)")
	}
	
	func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
		print("Received inputStream \(streamName) from \(peerID.displayName)")
	}
	
	func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
		
		delegate?.session(session, peer: peerID, didChange: state)
		
		switch state {
		case .connected:
			print("Connected to session \(session)")
		case .connecting:
			print("Connecting to session \(session)")
		case .notConnected:
			print("Did not connect to session \(session)")
		}
	}
	
	func session(_ session: MCSession, didReceiveCertificate certificate: [Any]?, fromPeer peerID: MCPeerID, certificateHandler: @escaping (Bool) -> Void) {
		print("Received certificate from \(peerID.displayName):")
		
		// The peer should be allowed to join
		certificateHandler(true)
	}
	
}

extension MCSessionManager: MCNearbyServiceBrowserDelegate {
	
	func browser(_ browser: MCNearbyServiceBrowser, didNotStartBrowsingForPeers error: Error) {
		print(#function)
		// MARK: TODO
		print("Broswer did not start browsing for peers:", error.localizedDescription)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, foundPeer peerID: MCPeerID, withDiscoveryInfo info: [String : String]?) {
		print(#function)
		
		foundPeers.append(peerID)
		
		delegate?.foundPeer(peerID)
	}
	
	func browser(_ browser: MCNearbyServiceBrowser, lostPeer peerID: MCPeerID) {
		print(#function)
		
		if let index = foundPeers.index(of: peerID) {
			foundPeers.remove(at: index)
			delegate?.lostPeer(peerID, at: index)
		} else {
			delegate?.lostPeer(peerID, at: nil)
		}
		
		
	}
	
}

extension MCSessionManager: MCNearbyServiceAdvertiserDelegate {
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didNotStartAdvertisingPeer error: Error) {
		print(#function)
		
		// MARK: TODO
		print("Advertiser did not start advertising peer:", error.localizedDescription)
	}
	
	func advertiser(_ advertiser: MCNearbyServiceAdvertiser, didReceiveInvitationFromPeer peerID: MCPeerID, withContext context: Data?, invitationHandler: @escaping (Bool, MCSession?) -> Void) {
		print(#function)
		
		delegate?.invitationReceived(from: peerID, invitationHandler: invitationHandler)
	}
	
}

extension MCSession {
	
	func send(_ message: [String: Any], toPeers peers: MCPeerID..., with mode: MCSessionSendDataMode = .reliable) throws {
		
		let data = NSKeyedArchiver.archivedData(withRootObject: message)
		
		try send(data, toPeers: peers, with: mode)
		
	}
	
}
