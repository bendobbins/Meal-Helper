//
//  Info_row.swift
//  Meal_Helper
//
//  Created by Ben Dobbins on 11/5/21.
//

import Foundation
import SwiftUI

// Compose view for each row in Personal_Info list
struct Info_row: View {
	var value: Information.Info? = nil
    var body: some View {
		HStack {
			Text(value?.id ?? "N/A")
				.fontWeight(.bold)
			Spacer()
			Text(value?.value ?? "N/A")
		}
    }
}

struct Info_row_Previews: PreviewProvider {
    static var previews: some View {
        Info_row()
    }
}
