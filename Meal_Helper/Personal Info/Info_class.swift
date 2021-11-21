//
//  Info_class.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/5/21.
//

import Foundation

// Format for receiving incoming personal information from server about user
class Information: Codable, Identifiable {
	var info: [Info] = [Info]()
	class Info: Codable, Identifiable {
		var id: String? = nil
		var value: String? = nil
	}
}
