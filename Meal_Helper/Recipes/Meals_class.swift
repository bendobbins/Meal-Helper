//
//  Meals_class.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/7/21.
//

import Foundation

// Format for data to be received from the server about all recipes that will be displayed to the user
class Meals: Codable, Identifiable {
	var breakfast: [Meal] = [Meal]()
	var lunch: [Meal] = [Meal]()
	var dinner: [Meal] = [Meal]()
	class Meal: Codable, Identifiable {
		var Name: String? = nil
		var Restrictions: [String]? = nil
		var Ingredients: [String]? = nil
		var Directions: String? = nil
		var Prep: String? = nil
		var Cook: String? = nil
		var Servings: String? = nil
		var Calories: String? = nil
		var Low_Carb: String? = nil
		var Vegetarian: String? = nil
		var Vegan: String? = nil
		var Gluten_Free: String? = nil
		var Dairy_Free: String? = nil
		var Nut_Free: String? = nil
		var Image: String? = nil
		var id: Int? = nil
	}
}
