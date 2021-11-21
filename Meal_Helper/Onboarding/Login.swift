//
//  Login.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/2/21.
//

import SwiftUI
import UIKit

// Create encodable class to send login values to server
class loginValues: ObservableObject, Encodable {
	enum CodingKeys: String, CodingKey {
		case username, password
	}
	
	@Published var username: String = ""
	@Published var password: String = ""
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(username, forKey: .username)
		try container.encode(password, forKey: .password)
	}
}

struct Login: View {
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var login = loginValues()
	@State var invalidUser: Bool = false
	@State var invalidPass: Bool = false
	// Don't allow form submission if these conditions are not met
	var valid: Bool {
		if login.username.isEmpty || login.password.isEmpty {
			return false
		}
		return true
	}
    var body: some View {
		// Display login text, image, form, button, register button
		VStack {
			Welcomeback()
			LoginImage()
			Logintext()
			UsernameField(username: $login.username)
			PasswordField(password: $login.password)
			// Display error messages if invalid info submitted
			if invalidUser {
				Text("That username does not exist")
					.offset(y: -10)
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
			
			if invalidPass {
				Text("Invald password")
					.offset(y: -10)
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
			
			Button(action: {invalidUser = false
					invalidPass = false
					self.callLogin()}, label: {
				LoginButtonContent()
					.padding()
			}).disabled(!valid)
			Text("Don't have an account?")
				.padding(.top)
				.padding(.bottom, 1)
			Button(action: {viewRouter.currentPage = .page1}, label: {
				Text("Register")
			})
		}
		.padding()
    }
	// Function for submitting login data to the server
	func callLogin() {
		guard let encoded = try? JSONEncoder().encode(login)
		else {
			print("Unable to encode login")
			return
		}
		
		let url = URL(string: "http://127.0.0.1:5000/login")!
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
			let loggedIn = decoded?["logged_in"] as? Int
			let user = decoded?["user"] as? Int
			// Display error messages if invalid input, else move on
			if user == 0 {
				invalidUser = true
			}
			else if loggedIn == 0 && user == 1 {
				invalidPass = true
			}
			else if loggedIn == 1 && user == 1 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page5
				}
			}
		}.resume()
	}
}

struct Login_Previews: PreviewProvider {
    static var previews: some View {
        Login(viewRouter: ViewRouter())
    }
}

// Structs for composing main view
struct Welcomeback: View {
	var body: some View {
		Text("Welcome back to Meal Helper!")
			.font(.largeTitle)
			.fontWeight(.bold)
			.padding(.bottom, 5)
			.multilineTextAlignment(.center)
	}
}

struct Logintext: View {
	var body: some View {
		Text("Login")
			.font(.title)
			.fontWeight(.semibold)
			.padding(.bottom, 10)
	}
}

struct LoginButtonContent: View {
	var body: some View {
		Text("Login")
			.font(.headline)
			.foregroundColor(.white)
			.padding()
			.frame(width: 220, height: 60)
			.background(Color.green)
			.cornerRadius(15.0)
	}
}

struct LoginImage: View {
	var body: some View {
		Image("AppPic")
			.resizable()
			.aspectRatio(contentMode: .fill)
			.clipShape(Circle())
			.frame(width: 100, height: 100, alignment: .center)
			.padding()
	}
}
