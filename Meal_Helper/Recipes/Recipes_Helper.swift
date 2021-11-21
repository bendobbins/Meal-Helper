//
//  Recipes_Helper.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/7/21.
//

import Foundation

// Get all information on each valid recipe from server and store data in lists of classes
class recipeRetriever: ObservableObject {
	@Published var loading: Bool = false
	@Published var breakfastlist = [Meals.Meal]()
	@Published var lunchlist = [Meals.Meal]()
	@Published var dinnerlist = [Meals.Meal]()
	
	init() {
		loading = false
		let url = URL(string: "http://127.0.0.1:5000/recipes")!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		URLSession.shared.dataTask(with: request) { data, response, error in
			DispatchQueue.main.async {
				self.loading = true
			}
			guard let data = data else {
				print("No response")
				return
			}
			let decoded = try? JSONDecoder().decode(Meals.self, from: data)
			DispatchQueue.main.async {
				self.breakfastlist = decoded?.breakfast ?? []
				self.lunchlist = decoded?.lunch ?? []
				self.dinnerlist = decoded?.dinner ?? []
			}
		}.resume()
	}
}

