//
//  ViewRouter.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/11/21.
//

import SwiftUI

// Determines default view when app opens (depending on session)
class ViewRouter: ObservableObject {
	@Published var currentPage: Page = .page5
}
