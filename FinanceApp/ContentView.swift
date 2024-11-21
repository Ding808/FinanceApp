//
//  ContentView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
import SwiftUI
import Charts

struct Product: Identifiable {
    let id = UUID()
    let title: String
    var revenue: Double
}
//Test message 

struct FinanceAppView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)
    @State private var products: [Product] = [
        .init(title: "Annual", revenue: 0.1),
        .init(title: "Monthly", revenue: 0.2),
        .init(title: "Lifetime", revenue: 0.7)
    ]
    @State private var animateChart: Bool = false
    @State private var selectedProduct: Product?
    @State private var lastSelectedProduct: Product? // Store the last selected product for "Details"
    @State private var touchLocation: CGPoint?
    @State private var isDetailLocked: Bool = false
    @State private var navigateToDetail: Bool = false
    @State private var navigateToEdit: Bool = false

    var body: some View {
        NavigationView {
            VStack {
                Text("Finance App")
                    .font(.largeTitle)
                    .bold()
                    .padding()

                ZStack {
                    Chart(products) { product in
                        SectorMark(
                            angle: .value(
                                Text(verbatim: product.title),
                                animateChart ? product.revenue : 0
                            ),
                            innerRadius: .ratio(0.6),
                            angularInset: 2
                        )
                        .cornerRadius(6)
                        .foregroundStyle(
                            by: .value(
                                Text(verbatim: product.title),
                                product.title
                            )
                        )
                    }
                    .rotationEffect(.degrees(animateChart ? 0 : -180))
                    .onAppear {
                        refreshChartAnimation()
                    }
                    .gesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { value in
                                guard !isDetailLocked else { return }
                                let touchLocation = value.location
                                self.touchLocation = touchLocation
                                let center = CGPoint(x: 150, y: 150) // Adjust center based on chart's size
                                let touchAngle = angleFromPoint(center: center, point: touchLocation)
                                let totalRevenue = products.map(\.revenue).reduce(0, +)
                                var currentAngle: Double = 0

                                for product in products {
                                    let productAngle = 360 * (product.revenue / totalRevenue)
                                    if touchAngle >= currentAngle && touchAngle <= currentAngle + productAngle {
                                        if selectedProduct?.id != product.id {
                                            feedbackGenerator.impactOccurred()
                                            selectedProduct = product
                                            lastSelectedProduct = product // Update last selected product
                                        }
                                        break
                                    }
                                    currentAngle += productAngle
                                }
                            }
                            .onEnded { _ in
                                if !isDetailLocked {
                                    selectedProduct = nil
                                    touchLocation = nil
                                }
                            }
                    )
                    .simultaneousGesture(
                        TapGesture(count: 2)
                            .onEnded {
                                isDetailLocked.toggle()
                            }
                    )

                    if let selectedProduct = selectedProduct, let touchLocation = touchLocation {
                        VStack {
                            Text(selectedProduct.title)
                                .font(.headline)
                                .padding(4)
                            Text("Revenue: \(selectedProduct.revenue * 100, specifier: "%.1f")%")
                                .font(.subheadline)
                                .padding(4)
                        }
                        .background(Color(.systemBackground).opacity(0.9))
                        .cornerRadius(8)
                        .shadow(radius: 5)
                        .position(x: touchLocation.x, y: touchLocation.y - 50)
                        .animation(.easeInOut, value: touchLocation)
                    }
                }
                .frame(width: 300, height: 300)

                if let selectedProduct = lastSelectedProduct {
                    Text("Selected: \(selectedProduct.title) - Revenue: \(String(format: "%.2f", selectedProduct.revenue * 100))%")
                        .font(.headline)
                        .padding()
                } else {
                    Text("No product selected")
                        .font(.subheadline)
                        .foregroundColor(.gray)
                        .padding()
                }

                // Detail Button
                Button(action: {
                    if lastSelectedProduct != nil {
                        navigateToDetail = true
                    }
                }) {
                    Text("Details")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(lastSelectedProduct == nil ? Color.gray : Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .disabled(lastSelectedProduct == nil)
                .padding(.horizontal)

                // Edit Detail Button
                Button(action: {
                    navigateToEdit = true
                }) {
                    Text("Edit Details")
                        .font(.headline)
                        .padding(.vertical, 10)
                        .padding(.horizontal, 20)
                        .frame(maxWidth: .infinity)
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .padding(.horizontal)
                .padding(.top, 10)

                Spacer()

                // NavigationLink for DetailView
                NavigationLink(
                    destination: DetailView(product: lastSelectedProduct),
                    isActive: $navigateToDetail
                ) {
                    EmptyView()
                }

                // NavigationLink for EditDetailView
                NavigationLink(
                    destination: EditDetailView(),
                    isActive: $navigateToEdit
                ) {
                    EmptyView()
                }
            }
            .padding()
            .navigationBarItems(
                trailing: Button(action: {
                    refreshChartAnimation()
                }) {
                    Image(systemName: "arrow.clockwise")
                        .imageScale(.large)
                }
            )
        }
    }

    private func angleFromPoint(center: CGPoint, point: CGPoint) -> Double {
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        let radians = atan2(deltaY, deltaX)
        var degrees = radians * 180 / .pi
        if degrees < 0 { degrees += 360 }
        degrees += 90
        if degrees >= 360 { degrees -= 360 }
        return degrees
    }

    private func refreshChartAnimation() {
        animateChart = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            withAnimation(.easeInOut(duration: 1.5)) {
                animateChart = true
            }
        }
    }
}

struct FinanceAppView_Previews: PreviewProvider {
    static var previews: some View {
        FinanceAppView()
    }
}
