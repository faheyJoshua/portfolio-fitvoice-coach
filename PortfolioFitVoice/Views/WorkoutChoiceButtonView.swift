//
//  WorkoutChoiceButtonView.swift
//  PortfolioFitVoice
//
//  Created by Joshua Fahey on 6/3/25.
//

import SwiftUI

struct WorkoutChoiceButtonView: View {
    
    let title: String
    
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundColor(.white)
            .padding()
            .background(Color.blue)
            .cornerRadius(10)
    }
}

#Preview {
    WorkoutChoiceButtonView(title: "Option 1")
}
