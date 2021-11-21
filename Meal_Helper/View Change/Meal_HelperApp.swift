//
//  Meal_HelperApp.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 10/28/21.
//

import SwiftUI


// Controls main view
@main
struct Meal_HelperApp: App {
	@StateObject var viewRouter = ViewRouter()
    var body: some Scene {
        WindowGroup {
            Motherview(viewRouter: viewRouter)
        }
    }
}
