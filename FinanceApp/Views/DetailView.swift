//
//  DetailView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
//
//
import SwiftUI


struct DetailView: View {
    var product: Product?

    var body: some View {
        VStack {
            if let product = product {
                Text("Detail View")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                Text("Product Title: \(product.title)")
                    .font(.headline)
                    .padding()

                Text("Revenue: \(String(format: "%.2f", product.revenue))")
                    .font(.headline)
                    .padding()
            } else {
                Text("No product selected")
                    .font(.headline)
                    .padding()
            }
        }
        .navigationTitle("Details")
    }
}
