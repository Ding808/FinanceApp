//
//  CustomBottomNavigationBar.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-12-03.
//
import SwiftUI

struct CustomBottomNavigationBar: View {
    @Binding var selectedIndex: Int
    let titles: [String]
    let backgroundColor: Color

    var body: some View {
        ZStack {
            HStack(spacing: 20) {
                ForEach(0..<titles.count, id: \.self) { index in
                    Button(action: {
                        withAnimation(.easeInOut) {
                            selectedIndex = index
                        }
                    }) {
                        VStack(spacing: 4) {
                            Image(systemName: index == 0 ? "house.fill" :
                                  index == 1 ? "chart.bar.fill" :
                                  index == 2 ? "plus.circle.fill" :
                                  index == 3 ? "pencil" :
                                  "gearshape.fill")
                                .font(.system(size: 20))
                                .foregroundColor(selectedIndex == index ? .blue : .gray)
                            Text(titles[index])
                                .font(.caption)
                                .foregroundColor(selectedIndex == index ? .blue : .gray)
                        }
                    }
                    .simultaneousGesture(
                        LongPressGesture(minimumDuration: 1.0)
                            .onEnded { _ in
                                print("\(titles[index]) icon long-pressed!")
                            }
                    )
                }
            }
            .padding(.vertical, 10) // 减少高度
            .padding(.horizontal, 20)
            .background(
                RoundedRectangle(cornerRadius: 20) // 圆角边框
                    .fill(backgroundColor)
                    .shadow(color: .gray.opacity(0.4), radius: 5, x: 0, y: 2)
            )
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 20) // 延长宽度
        }
    }
}
