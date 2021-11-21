//
//  Quiz.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/2/21.
//

import SwiftUI

// Create encodable class so that all quiz entries can be submitted to server
class Options: ObservableObject, Encodable {
	static let weightGoal = ["Lose weight", "Gain weight", "Remain at current weight"]
	static let sex = ["Male", "Female", "Other"]
	@Published var sexSel = 0
	@Published var weightGoalSel = 0
	@Published var poundsGoal = 0
	@Published var weight = ""
	@Published var height = ""
	@Published var glutenFree = false
	@Published var vegetarian = false
	@Published var vegan = false
	@Published var lactose = false
	@Published var nuts = false
	
	enum CodingKeys: CodingKey {
		case weightGoalSel, poundsGoal, weight, height, glutenFree, vegetarian, vegan, lactose, sexSel, nuts
	}
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(weightGoalSel, forKey: .weightGoalSel)
		try container.encode(poundsGoal, forKey: .poundsGoal)
		try container.encode(weight, forKey: .weight)
		try container.encode(height, forKey: .height)
		try container.encode(glutenFree, forKey: .glutenFree)
		try container.encode(vegetarian, forKey: .vegetarian)
		try container.encode(vegan, forKey: .vegan)
		try container.encode(lactose, forKey: .lactose)
		try container.encode(sexSel, forKey: .sexSel)
		try container.encode(nuts, forKey: .nuts)
	}
}

struct Quiz: View {
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var options = Options()
	@State var invalidHeightOrWeight = false
	// Form submission disabled until these conditions met
	var valid: Bool {
		if options.weight.isEmpty || options.height.isEmpty {
			return false
		}
		return true
	}
	var body: some View {
		NavigationView {
			VStack {
				// Sections for user to input data (corresponds with variables from class above
				Form {
					Section(header: Text("Personal Information"), footer: Text("Height and weight must be filled in as integers")) {
						Picker("Sex", selection: $options.sexSel) {
							ForEach(0..<Options.sex.count) {
								Text(Options.sex[$0])
							}
						}
						TextField("Your height (inches)", text: $options.height)
						TextField("Your current weight (lbs)", text: $options.weight)
					}
					// Display alert if invalid entry
					.alert("You must input height and weight as whole numbers", isPresented: $invalidHeightOrWeight) {
						Button("OK", role: .cancel) {}
					}
					Section(header: Text("Goals")) {
						Picker("Weight goal", selection: $options.weightGoalSel) {
							ForEach(0..<Options.weightGoal.count) {
								Text(Options.weightGoal[$0])
							}
						}
						Stepper(value: $options.poundsGoal, in: 0...200) {
							Text("Pounds to lose/gain:  \(options.poundsGoal)")
						}
					}
					Section(header: Text("Special Preferences")) {
						Toggle(isOn: $options.vegetarian.animation(), label: {
							Text("Vegetarian")
						})
						Toggle(isOn: $options.vegan.animation(), label: {
							Text("Vegan")
						})
						Toggle(isOn: $options.glutenFree.animation(), label: {
							Text("Gluten Free")
						})
						Toggle(isOn: $options.lactose.animation(), label: {
							Text("Lactose Intolerant")
						})
						Toggle(isOn: $options.nuts.animation(), label: {
							Text("Nut Allergy")
						})
					}
					Section(footer: Text("Must enter height and weight to continue")) {
						Button(action: {self.submitQuiz()}, label: {
							Text("Done")
						}).disabled(!valid)
					}
					// Toolbar for navigation
				}.navigationBarTitle("Personal Information")
					.toolbar {
						ToolbarItem(placement: .navigationBarLeading) {
							Button(action: {viewRouter.currentPage = .page4}, label: {Label("Personal Info", systemImage: "person.circle")})
						}
					}
				// When page appears, check user session
			}.onAppear(perform: {checkSession()})
		}
	}
	// Function for submitting all quiz data to the server
	func submitQuiz() {
		guard let encoded = try? JSONEncoder().encode(options)
		else {
			print("Could not encode options")
			return
		}
		
		let url = URL(string: "http://127.0.0.1:5000/quiz")!
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
			let received = decoded?["received"] as? Int
			let heightOrWeight = decoded?["height/weight"] as? Int
			// Display alert or move on depending on validity of input from user
			if heightOrWeight == 1 {
				invalidHeightOrWeight = true
			}
			else if received == 1 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page4
				}
			}
		}.resume()
	}
	// Check user's session on page appear
	func checkSession() {
		let url = URL(string: "http://127.0.0.1:5000/quiz")!
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

// Same view as above quiz, but doesn't have a navigation bar so that user can't access personal information before they fill in their quiz on registry
struct RegisterQuiz: View {
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var options = Options()
	@State var invalidHeightOrWeight = false
	var valid: Bool {
		if options.weight.isEmpty || options.height.isEmpty {
			return false
		}
		return true
	}
	var body: some View {
		NavigationView {
			VStack {
				Form {
					Section(header: Text("Personal Information"), footer: Text("Height and weight must be filled in as integers")) {
						Picker("Sex", selection: $options.sexSel) {
							ForEach(0..<Options.sex.count) {
								Text(Options.sex[$0])
							}
						}
						TextField("Your height (inches)", text: $options.height)
						TextField("Your current weight (lbs)", text: $options.weight)
					}
					.alert("You must input height and weight as whole numbers", isPresented: $invalidHeightOrWeight) {
						Button("OK", role: .cancel) {}
					}
					Section(header: Text("Goals")) {
						Picker("Weight goal", selection: $options.weightGoalSel) {
							ForEach(0..<Options.weightGoal.count) {
								Text(Options.weightGoal[$0])
							}
						}
						Stepper(value: $options.poundsGoal, in: 0...200) {
							Text("Pounds to lose/gain:  \(options.poundsGoal)")
						}
					}
					Section(header: Text("Special Preferences")) {
						Toggle(isOn: $options.vegetarian.animation(), label: {
							Text("Vegetarian")
						})
						Toggle(isOn: $options.vegan.animation(), label: {
							Text("Vegan")
						})
						Toggle(isOn: $options.glutenFree.animation(), label: {
							Text("Gluten Free")
						})
						Toggle(isOn: $options.lactose.animation(), label: {
							Text("Lactose Intolerant")
						})
						Toggle(isOn: $options.nuts.animation(), label: {
							Text("Nut Allergy")
						})
					}
					Section(footer: Text("Must enter height and weight to continue")) {
						Button(action: {self.submitQuiz()}, label: {
							Text("Done")
						}).disabled(!valid)
					}
				}.navigationBarTitle("Personal Information")
			}.onAppear(perform: {checkSession()})
		}
	}
	func submitQuiz() {
		guard let encoded = try? JSONEncoder().encode(options)
		else {
			print("Could not encode options")
			return
		}
		
		let url = URL(string: "http://127.0.0.1:5000/quiz")!
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
			let received = decoded?["received"] as? Int
			let heightOrWeight = decoded?["height/weight"] as? Int
			if heightOrWeight == 1 {
				invalidHeightOrWeight = true
			}
			else if received == 1 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page4
				}
			}
		}.resume()
	}
	func checkSession() {
		let url = URL(string: "http://127.0.0.1:5000/quiz")!
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


struct Quiz_Previews: PreviewProvider {
	static var previews: some View {
		Quiz(viewRouter: ViewRouter())
	}
}
