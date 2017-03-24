//
//  DiceRoll.swift
//  Liar Dice
//
//  Created by Josh Birnholz on 3/22/17.
//  Copyright © 2017 Joshua Birnholz. All rights reserved.
//

import Foundation

func randomInt(within range: Range<Int>) -> Int {
	return Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound
}

func randomInt(within range: ClosedRange<Int>) -> Int {
	return Int(arc4random_uniform(UInt32(range.upperBound - range.lowerBound))) + range.lowerBound + 1
}

enum DieRoll: Int {
	case one = 1
	case two = 2
	case three = 3
	case four = 4
	case five = 5
	case six = 6
	
	static var random: DieRoll {
		return DieRoll(rawValue: randomInt(within: 0...6))!
	}
	
	var dieSymbol: String {
		switch self {
		case .one: return "⚀"
		case .two: return "⚁"
		case .three: return "⚂"
		case .four: return "⚃"
		case .five: return "⚄"
		case .six: return "⚅"
		}
	}
}

struct DiceCombination {
	
	var die1: DieRoll
	var die2: DieRoll
	
	init() {
		die1 = .random
		die2 = .random
	}
	
	init?(_ array: [Int]) {
		guard array.count <= 2 else {
			return nil
		}
		
		guard
			let die1 = DieRoll(rawValue: array[0]),
			let die2 = DieRoll(rawValue: array[1])
			else {
				return nil
		}
		
		self.die1 = die1
		self.die2 = die2
	}
	
	init(_ die1: DieRoll, _ die2: DieRoll) {
		self.die1 = die1
		self.die2 = die2
	}
	
	var total: Int {
		
		if die1.rawValue == die2.rawValue {
			switch die1.rawValue {
			case 1: return 99
			case 2: return 8
			case 3: return 12
			case 4: return 16
			case 5: return 20
			case 6: return 24
			default: break
			}
		}
		
		return die1.rawValue + die2.rawValue
		
	}
	
	var faceValue: Int {
		return die1.rawValue + die2.rawValue
	}
	
	var arrayValue: [Int] {
		return [die1.rawValue, die2.rawValue]
	}
	
}
