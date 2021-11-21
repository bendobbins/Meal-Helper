//
//  Recipes.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/7/21.
//
//  Search bar courtesy of https://www.appcoda.com/swiftui-search-bar/

import SwiftUI


struct Recipes: View {
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var recipes = recipeRetriever()
	@State var breakfast = true
	@State var lunch = false
	@State var dinner = false
	@State var searchtext: String = ""
    var body: some View {
		NavigationView {
			VStack {
				// Create lists of recipes for each meal type, where the list rows are composed of structs from Recipes_Row and the Navigation links lead to structs from Recipe_Detail
				// Also configure search bar to work with lists
				SearchBar(text: $searchtext)
				if breakfast {
					List(recipes.breakfastlist.filter({ searchtext.isEmpty ? true: $0.Name?.contains(searchtext) as! Bool })) {bfast in
						NavigationLink(destination: MealDetail(meal: bfast)) {
							Meal_row(meal: bfast)
						}
					}.navigationBarTitle("Breakfast")
				}
				else if lunch {
					List(recipes.lunchlist.filter({ searchtext.isEmpty ? true:
						$0.Name?.contains(searchtext) as! Bool })) {lunch in
							NavigationLink(destination: MealDetail(meal: lunch)) {
							Meal_row(meal: lunch)
							}
					}.navigationBarTitle("Lunch")
				}
				else {
					List(recipes.dinnerlist.filter({ searchtext.isEmpty ? true:
						$0.Name?.contains(searchtext) as! Bool })) {dinner in
							NavigationLink(destination: MealDetail(meal: dinner)) {
								Meal_row(meal: dinner)
							}
					}.navigationBarTitle("Dinner")
				}
			}
			// Toolbar for easy navigation, also to display recipes for certain meal type
			.toolbar {
				ToolbarItem (placement: .navigationBarLeading) {
					Menu {
						Button(action: {breakfast = true
							lunch = false
							dinner = false
						}, label: {
							Text("Breakfast")
						})
						Button(action: {lunch = true
							breakfast = false
							dinner = false
						}, label: {
							Text("Lunch")
						})
						Button(action: {dinner = true
							lunch = false
							breakfast = false
						}, label: {
							Text("Dinner")
						})
					} label: {
						Text("Meal")
					}
				}
				ToolbarItem {
					Button(action: {viewRouter.currentPage = .page4}, label: {
						Label("Personal Info", systemImage: "person.circle")
					})
				}
				ToolbarItem(placement: .navigationBarTrailing) {
					Button(action: {viewRouter.currentPage = .page7}, label: {Label("Add Recipe", systemImage: "plus")})
				}
			}
		}.onAppear(perform: {checkSession()})
	}
	// Function for checking user session
	func checkSession() {
		let encoded = try? JSONEncoder().encode("session")
		let url = URL(string: "http://127.0.0.1:5000/recipes")!
		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.httpBody = encoded
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard let data = data else {
				print("No response")
				return
			}
			let decoded = try? JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
			let session = decoded?["session"] as? Int
			if session == 0 {
				// Reroute to login page if no session
				DispatchQueue.main.async {
					viewRouter.currentPage = .page2
				}
			}
		}.resume()
	}
}

struct Recipes_Previews: PreviewProvider {
    static var previews: some View {
        Recipes(viewRouter: ViewRouter())
    }
}

// Create search bar to use with list
struct SearchBar: View {
	@Binding var text: String
	
	@State private var isEditing = false
	var body: some View {
		HStack {
			TextField("Search", text: $text)
				.padding(7)
				.padding(.horizontal, 25)
				.background(Color(.systemGray6))
				.cornerRadius(8)
				.overlay(
					HStack {
						Image(systemName: "magnifyingglass")
							.foregroundColor(.gray)
							.frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
							.padding(.leading, 8)
						
						if isEditing {
							Button(action: {
								self.text = ""
							}) {
								Image(systemName: "multiply.circle.fill")
									.foregroundColor(.gray)
									.padding(.trailing, 8)
							}
						}
					})
				.padding(.horizontal, 10)
				.onTapGesture {
					self.isEditing = true
				}
	
			if isEditing {
				Button(action: {
					self.isEditing = false
					self.text = ""
					UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
				}) {
					Text("Cancel")
				}
				.padding(.trailing, 10)
				.transition(.move(edge: .trailing))
				.animation(.default)
			}
		}
	}
}
