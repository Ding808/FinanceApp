//
//  Blank.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
//
import SwiftUI
import Charts

struct Product: Identifiable {
    let id = UUID()
    let title: String
    var revenue: Double
}


struct FinanceAppView: View {
    @State private var products: [Product] = [
        .init(title: "Annual", revenue: 0.1),
        .init(title: "Monthly", revenue: 0.2),
        .init(title: "Lifetime", revenue: 0.6),
        .init(title: "Food", revenue: 0.1)
    ]
    @State private var animateChart: Bool = false
    @State private var selectedProduct: Product? // Centralized selected product
    @State private var lastSelectedProduct: Product?
    @State private var touchLocation: CGPoint?
    @State private var isDetailLocked: Bool = false
    @State private var selectedIndex: Int = 0

    var body: some View {
        NavigationView {
            VStack {
                Group {
                    if selectedIndex == 0 {
                        HomeView(
                            products: $products,
                            animateChart: $animateChart,
                            selectedProduct: $selectedProduct,
                            lastSelectedProduct: $lastSelectedProduct,
                            touchLocation: $touchLocation,
                            isDetailLocked: $isDetailLocked
                        )
                    } else if selectedIndex == 1 {
                        if let selectedProduct = selectedProduct {
                            DetailView(product: selectedProduct) // Pass the selected product explicitly
                        } else {
                            Text("No product selected")
                                .font(.headline)
                                .padding()
                        }
                    } else if selectedIndex == 2 {
                        AddView()
                    } else if selectedIndex == 3 {
                        EditDetailView()
                    } else if selectedIndex == 4 {
                        SettingView()
                    }
                }
                Spacer()
                CustomBottomNavigationBar(
                    selectedIndex: $selectedIndex,
                    titles: ["Home", "Detail", "Add", "Edit", "Setting"],
                    backgroundColor: Color(.systemGray6)
                )
                .padding(.bottom, 10)
            }
        }
    }
}



struct HomeView: View {
    @Binding var products: [Product]
    @Binding var animateChart: Bool
    @Binding var selectedProduct: Product?
    @Binding var lastSelectedProduct: Product?
    @Binding var touchLocation: CGPoint?
    @Binding var isDetailLocked: Bool

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium)

    var body: some View {
        VStack {
            Spacer()
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
                    setInitialDetailProduct()
                }
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { value in
                            guard !isDetailLocked else { return }
                            let touchLocation = value.location
                            self.touchLocation = touchLocation
                            let center = CGPoint(x: 150, y: 150)
                            let touchAngle = angleFromPoint(center: center, point: touchLocation)
                            handleTouch(touchAngle: touchAngle)
                        }
                        .onEnded { _ in
                            if !isDetailLocked {
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
                    productDetailPopup(selectedProduct: selectedProduct, touchLocation: touchLocation)
                }
            }
            .frame(width: 300, height: 300)
            .padding(.vertical)

            selectedProductSummary()

            Spacer()
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

    private func setInitialDetailProduct() {
        if let maxProduct = products.max(by: { $0.revenue < $1.revenue }) {
            lastSelectedProduct = maxProduct
            selectedProduct = maxProduct // Initialize detail to the largest element
        }
    }

    private func handleTouch(touchAngle: Double) {
        let center = CGPoint(x: 150, y: 150)
        let totalRevenue = products.map(\.revenue).reduce(0, +)
        var currentAngle: Double = 0

        for product in products {
            let productAngle = 360 * (product.revenue / totalRevenue)
            if touchAngle >= currentAngle && touchAngle <= currentAngle + productAngle {
                if selectedProduct?.id != product.id {
                    feedbackGenerator.impactOccurred()
                    selectedProduct = product
                    lastSelectedProduct = product
                }
                break
            }
            currentAngle += productAngle
        }
    }

    private func productDetailPopup(selectedProduct: Product, touchLocation: CGPoint) -> some View {
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

    private func selectedProductSummary() -> some View {
        if let lastSelectedProduct = lastSelectedProduct {
            return Text("Selected: \(lastSelectedProduct.title) - Revenue: \(String(format: "%.2f", lastSelectedProduct.revenue * 100))%")
                .font(.headline)
                .padding()
        } else {
            return Text("No product selected")
                .font(.subheadline)
                .foregroundColor(.gray)
                .padding()
        }
    }
}
