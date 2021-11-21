//
//  Register.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 10/28/21.
//

import Combine
import SwiftUI
import UIKit

// For light/dark mode
let lightGreyColor = Color(red: 239.0/255.0, green: 243.0/255.0, blue: 244.0/255.0, opacity: 1.0)
let darkGreyColor = Color(red: 31.0/255.0, green: 34.0/255.0, blue: 31.0/255.0, opacity: 1.0)

// Create encodable class so that register values can be submitted to server
class registerValues: ObservableObject, Encodable {
	enum CodingKeys: String, CodingKey {
		case username, password, confirm
	}
	
	@Published var username: String = ""
	@Published var password: String = ""
	@Published var confirm: String = ""
	
	func encode(to encoder: Encoder) throws {
		var container = encoder.container(keyedBy: CodingKeys.self)
		try container.encode(username, forKey: .username)
		try container.encode(password, forKey: .password)
		try container.encode(confirm, forKey: .confirm)
	}
}

struct Register: View {
	@StateObject var viewRouter: ViewRouter
	@ObservedObject var register = registerValues()
	@State var usernameTaken: Bool = false
	@State var nonconfirmed: Bool = false
	// Don't allow form submission if these conditions not met
	var valid: Bool {
		if register.username.isEmpty || register.password.isEmpty || register.confirm.isEmpty {
			return false
		}
		return true
	}
    var body: some View {
		// Display registration text, form, button, login button
		VStack{
			Welcometext()
			Signup()
			UsernameField(username: $register.username)
			PasswordField(password: $register.password)
			ConfirmField(confirm: $register.confirm)
			// Display error messages if user inputs invalid information
			if usernameTaken {
				Text("That username is taken. Please try a different one.")
					.offset(y: -10)
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
			
			if nonconfirmed {
				Text("Password must match confirmation.")
					.offset(y: -10)
					.foregroundColor(.red)
					.multilineTextAlignment(.center)
			}
			
			Button(action: {nonconfirmed = false
					if register.password != register.confirm {nonconfirmed = true}
					else {self.callRegister()}
					usernameTaken = false
			})
			{
				RegisterButtonContent()
					.padding()
			}.disabled(!valid)
			Text("Already have an account?")
				.padding(.bottom, 1)
				.padding(.top)
			Button(action: {DispatchQueue.main.async {
				viewRouter.currentPage = .page2
			}}, label: {
				Text("Sign in")
			})
		}
		.padding()
    }
	// For submitting registration information
	func callRegister() {
		guard let encoded = try? JSONEncoder().encode(register)
		else {
			print("Unable to encode registry")
			return
		}
		
		let url = URL(string: "http://127.0.0.1:5000/register")!
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
			let registered = decoded?["registered"] as? Int
			if registered == 0 {
				usernameTaken = true
			}
			else if registered == 1 {
				DispatchQueue.main.async {
					viewRouter.currentPage = .page6
				}
			}
		}.resume()
	}
}

struct Register_Previews: PreviewProvider {
    static var previews: some View {
		Register(viewRouter: ViewRouter())
			.previewDevice("iPhone 12")
    }
}

// Classes for designing view
struct Welcometext: View {
	var body: some View {
		Text("Welcome to Meal Helper!")
			.font(.largeTitle)
			.fontWeight(.bold)
			.padding(.bottom, 20)
			.multilineTextAlignment(.center)
	}
}

struct Signup: View {
	var body: some View {
		Text("Sign up below to start finding the right meals for you!")
			.font(.title2)
			.fontWeight(.semibold)
			.padding(.bottom, 20)
			.multilineTextAlignment(.center)
	}
}

struct RegisterButtonContent: View {
	var body: some View {
		Text("Register")
			.font(.headline)
			.foregroundColor(.white)
			.padding()
			.frame(width: 220, height: 60)
			.background(Color.green)
			.cornerRadius(15.0)
	}
}

struct UsernameField: View {
	@Binding var username: String
	@Environment(\.colorScheme) var colorScheme
	var body: some View {
		TextField("Username", text: $username)
			.padding()
			.background(colorScheme == .dark ? darkGreyColor : lightGreyColor)
			.cornerRadius(5.0)
			.padding(.bottom, 20)
	}
}

struct PasswordField: View {
	@Binding var password: String
	@Environment(\.colorScheme) var colorScheme
	var body: some View {
		SecureField("Password", text: $password)
			.padding()
			.background(colorScheme == .dark ? darkGreyColor : lightGreyColor)
			.cornerRadius(5.0)
			.padding(.bottom, 20)
	}
}

struct ConfirmField: View {
	@Binding var confirm: String
	@Environment(\.colorScheme) var colorScheme
	var body: some View {
		SecureField("Confirm Password", text: $confirm)
			.padding()
			.background(colorScheme == .dark ? darkGreyColor : lightGreyColor)
			.cornerRadius(5.0)
			.padding(.bottom, 20)
	}
}
