//
//  Personal_Info.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/5/21.
//

import SwiftUI

struct Personal_Info: View {
	@State private var selection: String? = nil
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var info = infoRetriever()
    var body: some View {
		NavigationView {
			// If no personal data, display no data
			if info.loading {
				if info.infoList.isEmpty {
					Text("Error, please reload app")
				}
				else {
					// Display list of personal data for the user
					List(info.infoList) {value in
						Info_row(value: value)
					}.navigationBarTitle("Personal Information")
					// Toolbar for easy navigation and logging out
					.toolbar {
						ToolbarItem (placement: .navigationBarTrailing) {
							Button(action: {viewRouter.currentPage = .page3}, label: {Text("Update")})
						}
						ToolbarItem(placement: .navigationBarLeading) {
							Button(action: {viewRouter.currentPage = .page5}, label: {
								Label("Recipes", systemImage: "list.bullet")
							})
						}
						ToolbarItem(placement: .navigationBarTrailing) {
							Button(action: {self.LogOut()}, label: {Text("Log Out")})
						}
					}
				}
			}
			else {
				ProgressView()
			}
			// Check session when content appears
		}.onAppear(perform: {checkSession()})
	}
	// Function for checking user session
	func checkSession() {
		let encoded = try? JSONEncoder().encode("session")
		let url = URL(string: "http://127.0.0.1:5000/personal")!
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
			// Return user to login page if not in session
			if session == 0 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page2
				}
			}
		}.resume()
	}
	// Function for logging user out
	func LogOut() {
		let url = URL(string: "http://127.0.0.1:5000/logout")!
		let request = URLRequest(url: url)
		URLSession.shared.dataTask(with: request) { data, response, error in
			guard data != nil else {
				print("No response")
				return
			}
			checkSession()
		}.resume()
	}
}

struct Personal_Info_Previews: PreviewProvider {
    static var previews: some View {
        Personal_Info(viewRouter: ViewRouter())
    }
}

