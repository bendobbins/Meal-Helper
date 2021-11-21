//
//  Recipes_row.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/7/21.
//

import SwiftUI

// Placeholder image
@ViewBuilder
func placeholderImage() -> some View {
	Image(systemName: "photo")
		.renderingMode(.template)
		.resizable()
		.aspectRatio(contentMode: .fit)
		.frame(width: 40, height: 40)
		.foregroundColor(.gray)
}

// Display for each recipe that will be shown in the navigation list on the recipes page
// Each struct displays information for its certain meal type
struct Meal_row: View {
	let colors: [String: Color] = ["v": .init(red: 2, green: 122, blue: 0), "V": .green, "G": .orange, "D": .blue, "N": .yellow]
	var meal: Meals.Meal? = nil
    var body: some View {
		HStack {
			AsyncImage(url: URL(string: meal?.Image ?? "")) { image in
				image
					.resizable()
					.clipShape(Circle())
					.frame(width: 40, height: 40)
					.overlay(Circle().stroke(Color.gray, lineWidth: 2))
			} placeholder: {
				placeholderImage()
			}
			Text(meal?.Name ?? "")
			Spacer()
			ForEach(meal?.Restrictions ?? [], id: \.self) {
				Restriction in
				Text(Restriction)
					.font(.caption)
					.fontWeight(.black)
					.padding(5)
					.background(colors[Restriction])
					.foregroundColor(.white)
					.clipShape(Circle())
			}
		}
	}
}

struct Recipes_row_Previews: PreviewProvider {
    static var previews: some View {
        Meal_row()
    }
}
