//
//  Personal_Info_Helper.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/5/21.
//

import Foundation

// Retrieve personal information data from server to be displayed in Personal_Info
class infoRetriever: ObservableObject {
	@Published var loading: Bool = false
	@Published var infoList = [Information.Info]()
	
	init() {
		loading = false
		let url = URL(string: "http://127.0.0.1:5000/personal")!
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
			let decoded = try? JSONDecoder().decode(Information.self, from: data)
			DispatchQueue.main.async {
				self.infoList = decoded?.info ?? []
			}
		}.resume()
	}
}
