//
//  RecipeDetail.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/16/21.
//

import SwiftUI

// Placeholder image if URL invalid
@ViewBuilder
func placeholderImageDetail() -> some View {
	GeometryReader { geo in
		Image(systemName: "photo")
			.renderingMode(.template)
			.resizable()
			.aspectRatio(contentMode: .fit)
			.frame(width: geo.size.width, height: 200, alignment: .center)
			.foregroundColor(.gray)
	}
}


struct MealDetail: View {
	let meal: Meals.Meal
    var body: some View {
		// Display all information about recipe that was clicked on in recipe list
		ScrollView {
			VStack {
				// Display image
				GeometryReader { geo in
					AsyncImage(url: URL(string: meal.Image ?? "")) {
						image in image
							.resizable()
							.clipShape(Circle())
							.scaledToFit()
							.overlay(Circle().stroke(Color.black, lineWidth: 1))
							.frame(width: geo.size.width, height: 200)
					} placeholder: {
						placeholderImageDetail()
					}
				}.frame(height: 200, alignment: .center)
				// Display general values
				HStack {
					Text("Prep time: ")
						.fontWeight(.bold)
					Text(meal.Prep ?? "Error")
					Spacer()
					Text("Cook time: ")
						.fontWeight(.bold)
					Text(meal.Cook ?? "Error")
				}.padding()
				HStack {
					Text("Servings: ")
						.fontWeight(.bold)
					Text(meal.Servings ?? "Error")
					Spacer()
					Text("Calories: ")
						.fontWeight(.bold)
					Text(meal.Calories ?? "Error")
				}.padding(.leading).padding(.trailing).padding(.bottom)
				// Display ingredients and instructions
				HStack {
					VStack(alignment: .leading) {
						Text("Ingredients")
							.fontWeight(.bold)
							.padding(.bottom)
						ForEach(meal.Ingredients ?? [], id: \.self) {
								ingredient in
							Text("• \(ingredient)")
								.padding(.bottom, 1)
						}
					}.padding(.leading).padding(.trailing).padding(.bottom)
					Spacer()
				}
				HStack {
					VStack(alignment: .leading) {
						Text("Directions")
							.fontWeight(.bold)
							.padding(.bottom)
							.padding(.top)
						Text(meal.Directions ?? "Error finding directions")
					}.padding(.leading).padding(.trailing).padding(.bottom)
					Spacer()
				}
				// Display restrictions
				HStack {
					VStack(alignment: .center) {
						Text("Restrictions")
							.fontWeight(.bold)
							.padding(.bottom)
							.padding(.top)
						HStack {
							Text("Low Carb:     ")
								.fontWeight(.semibold)
							Text(meal.Low_Carb ?? "Error")
						}.padding(.bottom, 3)
						HStack {
							Text("Vegetarian:     ")
								.fontWeight(.semibold)
							Text(meal.Vegetarian ?? "Error")
						}.padding(.bottom, 3)
						HStack {
							Text("Vegan:     ")
								.fontWeight(.semibold)
							Text(meal.Vegan ?? "Error")
						}.padding(.bottom, 3)
						HStack {
							Text("Gluten Free:     ")
								.fontWeight(.semibold)
							Text(meal.Gluten_Free ?? "Error")
						}.padding(.bottom, 3)
						HStack {
							Text("Dairy Free:     ")
								.fontWeight(.semibold)
							Text(meal.Dairy_Free ?? "Error")
						}.padding(.bottom, 3)
						HStack {
							Text("Nut Free:     ")
								.fontWeight(.semibold)
							Text(meal.Nut_Free ?? "Error")
						}
					}.padding(.leading).padding(.trailing).padding(.bottom)
				}
				Spacer()
			}.navigationTitle(meal.Name ?? "Recipe").navigationBarTitleDisplayMode(.inline)
		}
    }
}

