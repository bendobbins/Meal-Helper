//
//  Motherview.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/2/21.
//

import SwiftUI

// Configure viewRouter to lead to each page
struct Motherview: View {
	@StateObject var viewRouter: ViewRouter
    var body: some View {
		switch viewRouter.currentPage {
		case .page1:
			Register(viewRouter: viewRouter)
		case .page2:
			Login(viewRouter: viewRouter)
		case .page3:
			Quiz(viewRouter: viewRouter)
		case .page4:
			Personal_Info(viewRouter: viewRouter)
		case .page5:
			Recipes(viewRouter: viewRouter)
		case .page6:
			RegisterQuiz(viewRouter: viewRouter)
		case .page7:
			RecipeAdder(viewRouter: viewRouter)
		}
    }
}

struct Motherview_Previews: PreviewProvider {
    static var previews: some View {
        Motherview(viewRouter: ViewRouter())
    }
}
