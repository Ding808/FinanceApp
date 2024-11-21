//
//  ContentView.swift
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
//Test message 

struct FinanceAppView: View {
    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .medium) // Initialize haptic feedback
    @State private var products: [Product] = [
        .init(title: "Annual", revenue: 0.1),
        .init(title: "Monthly", revenue: 0.2),
        .init(title: "Lifetime", revenue: 0.7)
    ]
    @State private var animateChart: Bool = false
    @State private var selectedProduct: Product?
    @State private var isDetailLocked: Bool = false
    @State private var touchLocation: CGPoint?

    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                VStack {
                    // App Title
                    Text("Finance App")
                        .font(.largeTitle)
                        .bold()
                        .padding(.top, geometry.size.height * 0.05)
                    
                    Spacer().frame(height: geometry.size.height * 0.05)
                    
                    // Graph System
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
                                    let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.width / 2)
                                    let touchAngle = angleFromPoint(center: center, point: touchLocation)
                                    let totalRevenue = products.map(\.revenue).reduce(0, +)
                                    var currentAngle: Double = 0
                                    
                                    for product in products {
                                        let productAngle = 360 * (product.revenue / totalRevenue)
                                        if touchAngle >= currentAngle && touchAngle <= currentAngle + productAngle {
                                            if selectedProduct?.id != product.id {
                                                feedbackGenerator.impactOccurred()
                                                selectedProduct = product
                                            }
                                            break
                                        }
                                        currentAngle += productAngle
                                    }
                                }
                                .onEnded { _ in
                                    if !isDetailLocked {
                                        selectedProduct = nil
                                    }
                                }
                        )
                    }
                    .frame(height: geometry.size.height * 0.5)
                    
                    Spacer().frame(height: geometry.size.height * 0.05)
                    
                    // Detail Button
                    Button(action: {
                        // Detail button action
                    }) {
                        Text("Details")
                            .font(.headline)
                            .padding(.vertical, 10)
                            .padding(.horizontal, 20)
                            .frame(width: geometry.size.width * 0.6)
                            .background(Color.blue)
                            .foregroundColor(.white)
                            .cornerRadius(8)
                    }
                    .padding(.bottom, geometry.size.height * 0.1)
                    
                    Spacer()
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
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
    }

    private func angleFromPoint(center: CGPoint, point: CGPoint) -> Double {
        let deltaX = point.x - center.x
        let deltaY = point.y - center.y
        let radians = atan2(deltaY, deltaX)
        var degrees = radians * 180 / .pi
        if degrees < 0 {
            degrees += 360
        }
        degrees += 90
        if degrees >= 360 {
            degrees -= 360
        }
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


