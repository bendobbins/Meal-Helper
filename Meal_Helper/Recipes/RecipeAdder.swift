//
//  RecipeAdder.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/11/21.
//

import SwiftUI

// Create encodable class so that data from form can be submitted to server
class Recipe: ObservableObject, Encodable {
	static let type = ["Breakfast", "Lunch", "Dinner"]
	// All variables to be submitted
	@Published var name = ""
	@Published var typeSel = 0
	@Published var imageURL = ""
	@Published var prep = 0
	@Published var cook = 0
	@Published var servings = 0
	@Published var calories = ""
	@Published var ingredients = ""
	@Published var directions = ""
	@Published var low_carb = false
	@Published var vegetarian = false
	@Published var vegan = false
	@Published var gluten_free = false
	@Published var dairy_free = false
	@Published var nut_free = false
	
	enum CodingKeys: CodingKey {
		case name, typeSel, imageURL, prep, cook, servings, calories, ingredients, directions, low_carb, vegetarian, vegan, gluten_free, dairy_free, nut_free
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(name, forKey: .name)
		try container.encode(typeSel, forKey: .typeSel)
		try container.encode(imageURL, forKey: .imageURL)
		try container.encode(prep, forKey: .prep)
		try container.encode(cook, forKey: .cook)
		try container.encode(servings, forKey: .servings)
		try container.encode(calories, forKey: .calories)
		try container.encode(ingredients, forKey: .ingredients)
		try container.encode(directions, forKey: .directions)
		try container.encode(low_carb, forKey: .low_carb)
		try container.encode(vegetarian, forKey: .vegetarian)
		try container.encode(vegan, forKey: .vegan)
		try container.encode(gluten_free, forKey: .gluten_free)
		try container.encode(dairy_free, forKey: .dairy_free)
		try container.encode(nut_free, forKey: .nut_free)
	}
}

struct RecipeAdder: View {
	@ObservedObject var recipe = Recipe()
	@State private var placeholder = ""
	@State var invalidCalories = false
	@State var invalidIngredients = false
	@StateObject var viewRouter: ViewRouter
	// Don't allow submission of form unless these conditions are met
	var valid: Bool {
		if recipe.name.isEmpty || (recipe.prep == 0 && recipe.cook == 0) || recipe.ingredients.isEmpty || recipe.directions.isEmpty || recipe.servings == 0 || recipe.calories.isEmpty {
			return false
		}
		return true
	}
	var body: some View {
		NavigationView {
			VStack{
				// Create ways for user to manipulate variables to be submitted (Add their recipe)
				Form {
					Section(header: Text("General Information"), footer: Text("To get image URL from google image on iPhone/iPad, tap and hold image, then select \"Copy image\". This may not always work")) {
						TextField("* Name of Meal", text: $recipe.name)
						Picker("* Meal Type", selection: $recipe.typeSel) {
							ForEach(0..<Recipe.type.count) {
								Text(Recipe.type[$0])
							}
						}
						TextField("Image for Meal (URL)", text: $recipe.imageURL)
						Stepper(value: $recipe.prep, in: 0...120) {
							Text("Prep time:  \(recipe.prep) mins")
						}
						Stepper(value: $recipe.cook, in: 0...600) {
							Text("Cook time:  \(recipe.cook) mins")
						}
						Stepper(value: $recipe.servings, in: 0...30) {
							Text("* Servings:  \(recipe.servings)")
						}
						TextField("* Calories (Whole number)", text:$recipe.calories)
					}
					Section(header: Text("Ingredients and Directions")) {
						List {
							ZStack {
								TextEditor(text: $recipe.ingredients)
								if recipe.ingredients.isEmpty {
									TextField("* Ingredients (Comma-separated list)", text: $placeholder)
										.disabled(true)
										.offset(x: 4, y: -2)
								}
							}
							.shadow(radius: 1)
							ZStack {
								TextEditor(text: $recipe.directions)
								if recipe.directions.isEmpty {
									TextField("* Directions (Paragraph)", text: $placeholder)
										.disabled(true)
										.offset(x: 4, y: -2)
								}
							}
							.shadow(radius: 1)
						}
					}
					Section(header: Text("Restrictions"), footer: Text("We define a low carb meal as having less than 20g of carbohydrates")) {
						Toggle(isOn: $recipe.low_carb.animation(), label: {
							Text("Low in Carbohydrates")
						})
						Toggle(isOn: $recipe.vegetarian.animation(), label: {
							Text("Vegetarian")
						})
						Toggle(isOn: $recipe.vegan.animation(), label: {
							Text("Vegan")
						})
						Toggle(isOn: $recipe.gluten_free.animation(), label: {
							Text("Gluten Free")
						})
						Toggle(isOn: $recipe.dairy_free.animation(), label: {
							Text("Dairy Free")
						})
						Toggle(isOn: $recipe.nut_free.animation(), label: {
							Text("Nut Free")
						})
					}
					// Display alerts if invalid submission type for certain forms
					.alert("Your calories input must be a whole number", isPresented: $invalidCalories) {
						Button("OK", role: .cancel) {}
					}
					
					.alert("You must submit more than one ingredient (Remember, input ingredients as a comma-separated list)", isPresented: $invalidIngredients) {
						Button("OK", role: .cancel) {}
					}
					
					Section(footer: Text("Fill in all parts marked with a star and at least one time field to continue")) {
						Button(action: {invalidCalories = false
							invalidIngredients = false
							self.submitRecipe()}, label: {Text("Submit")}).disabled(!valid)
					}
				}
				// Create toolbar for easy navigation
			}.navigationTitle("Add a Recipe")
				.onAppear(perform: {checkSession()})
				.toolbar {
					ToolbarItem(placement: .navigationBarLeading) {
						Button(action: {viewRouter.currentPage = .page5}, label: {Label("Recipes", systemImage: "list.bullet")})
					}
				}
		}
	}
	// Function for connecting to server and submitting recipe data
	func submitRecipe() {
		guard let encoded = try? JSONEncoder().encode(recipe)
		else {
			print("Could not encode recipe")
			return
		}
		
		let url = URL(string: "http://127.0.0.1:5000/AddRecipe")!
		var request = URLRequest(url: url)
		request.setValue("application/json", forHTTPHeaderField: "Content-Type")
		request.httpMethod = "POST"
		request.httpBody = encoded
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data else {
				print("No response")
				return
			}
			let decoded = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
			let calories = decoded?["calories"] as? Int
			let ingredients = decoded?["ingredients"] as? Int
			let submitted = decoded?["submitted"] as? Int
			// Displays alert or moves on depending on whether input is all valid
			if calories == 1 {
				invalidCalories = true
			}
			else if ingredients == 1 {
				invalidIngredients = true
			}
			else if submitted == 1 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page5
				}
			}
		}.resume()
	}
	// Checks session for user, returns to log in page if no session
	func checkSession() {
		let url = URL(string: "http://127.0.0.1:5000/AddRecipe")!
		var request = URLRequest(url: url)
		request.httpMethod = "GET"
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data else {
				print("No response")
				return
			}
			let decoded = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
			let session = decoded?["session"] as? Int
			if session == 0 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page2
				}
			}
		}.resume()
	}
}

struct RecipeAdder_Previews: PreviewProvider {
	static var previews: some View {
		RecipeAdder(viewRouter: ViewRouter())
	}
}
