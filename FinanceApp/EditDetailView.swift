//
//  EditDetailView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
//

import SwiftUI


struct ButtonCategory: Identifiable {
    let id = UUID() // 唯一标识符
    let name: String // 类别名称
}

struct EditDetailView: View {
    @State private var foodItems: [String] = ["按钮 1", "按钮 2"]
    @State private var workItems: [String] = ["按钮 3", "按钮 4", "按钮 5"]
    @State private var noneItems: [String] = []
    @State private var showingFullScreen: ButtonCategory? = nil // 当前展示的全屏类别
    
    var body: some View {
        NavigationView {
            VStack {
                // Food 类别
                SectionView(
                    title: ButtonCategory(name: "Food"),
                    items: $foodItems,
                    otherLists: [$workItems, $noneItems],
                    showingFullScreen: $showingFullScreen
                )
                
                // Work 类别
                SectionView(
                    title: ButtonCategory(name: "Work"),
                    items: $workItems,
                    otherLists: [$foodItems, $noneItems],
                    showingFullScreen: $showingFullScreen
                )
                
                // None 类别
                SectionView(
                    title: ButtonCategory(name: "None"),
                    items: $noneItems,
                    otherLists: [$foodItems, $workItems],
                    showingFullScreen: $showingFullScreen
                )
            }
            .padding()
            .navigationBarTitle("分类按钮列表", displayMode: .inline)
        }
        .fullScreenCover(item: $showingFullScreen) { category in
            // 显示全屏视图
            FullScreenCategoryView(
                title: category.name,
                items: getItems(for: category.name),
                onBack: { showingFullScreen = nil }
            )
        }
    }
    
    // 获取指定类别的绑定数组
    func getItems(for category: String) -> Binding<[String]> {
        switch category {
        case "Food": return $foodItems
        case "Work": return $workItems
        default: return $noneItems
        }
    }
}

struct SectionView: View {
    let title: ButtonCategory
    @Binding var items: [String]
    var otherLists: [Binding<[String]>]
    @Binding var showingFullScreen: ButtonCategory?
    
    var body: some View {
        VStack(alignment: .leading) {
            // 类别标题，支持点击进入全屏
            Text(title.name)
                .font(.headline)
                .padding(.top)
                .onTapGesture {
                    showingFullScreen = title
                }
            
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                        .onDrag {
                            let data = "\(item)"
                            return NSItemProvider(object: data as NSString)
                        }
                }
                .onMove(perform: moveItem)
                .onDrop(of: [.text], delegate: CustomDropDelegate(currentList: $items, otherLists: otherLists))
            }
            .listStyle(PlainListStyle())
        }
    }
    
    // 移动内部列表顺序
    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

struct CustomDropDelegate: DropDelegate {
    @Binding var currentList: [String]
    var otherLists: [Binding<[String]>]
    
    func validateDrop(info: DropInfo) -> Bool {
        info.hasItemsConforming(to: [.text])
    }
    
    func performDrop(info: DropInfo) -> Bool {
        guard let itemProvider = info.itemProviders(for: [.text]).first else { return false }
        
        itemProvider.loadItem(forTypeIdentifier: "public.text", options: nil) { (data, _) in
            guard let data = data as? String else { return }
            
            DispatchQueue.main.async {
                // 从所有其他类别中移除该按钮
                for list in otherLists {
                    if let index = list.wrappedValue.firstIndex(of: data) {
                        list.wrappedValue.remove(at: index)
                        break
                    }
                }
                
                // 将按钮添加到当前类别
                if !self.currentList.contains(data) {
                    self.currentList.append(data)
                }
            }
        }
        return true
    }
}

struct FullScreenCategoryView: View {
    let title: String
    @Binding var items: [String]
    let onBack: () -> Void
    
    var body: some View {
        NavigationView {
            List {
                ForEach(items, id: \.self) { item in
                    Text(item)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                .onMove(perform: moveItem)
            }
            .navigationBarTitle(title, displayMode: .inline)
            .navigationBarItems(leading: Button("返回") {
                onBack()
            })
        }
    }
    
    func moveItem(from source: IndexSet, to destination: Int) {
        items.move(fromOffsets: source, toOffset: destination)
    }
}

struct CategorizedDraggableButtons_Previews: PreviewProvider {
    static var previews: some View {
        EditDetailView()
    }
}
