//
//  EditDetailView.swift
//  FinanceApp
//
//  Created by Yueyang Ding on 2024-11-21.
//
import SwiftUI

struct ButtonCategory: Identifiable, Codable, Equatable {
    let id: UUID
    let name: String

    static func ==(lhs: ButtonCategory, rhs: ButtonCategory) -> Bool {
        lhs.id == rhs.id
    }
}

struct IdentifiableString: Identifiable {
    let id = UUID()
    let value: String
}

struct EditDetailView: View {
    @AppStorage("foodItems") private var savedFoodItems: Data = Data()
    @AppStorage("workItems") private var savedWorkItems: Data = Data()
    @AppStorage("noneItems") private var savedNoneItems: Data = Data()
    
    @State private var foodItems: [String] = []
    @State private var workItems: [String] = []
    @State private var noneItems: [String] = []
    
    @State private var showingFullScreen: ButtonCategory? = nil
    @State private var selectedItemDetail: IdentifiableString? = nil
    @State private var newItemText: String = ""
    @State private var isAddingNewItem: Bool = false
    @State private var isEditingItem: Bool = false
    @State private var selectedCategoryForNewItem: ButtonCategory? = nil
    @State private var currentCategory: ButtonCategory? = nil
    @State private var itemToEdit: (category: ButtonCategory, index: Int, text: String)?

    var body: some View {
        NavigationView {
            VStack {
                // Food Category
                SectionView(
                    title: ButtonCategory(id: UUID(), name: "Food"),
                    items: $foodItems,
                    otherLists: [$workItems, $noneItems],
                    showingFullScreen: $showingFullScreen,
                    onEditItem: startEditingItem,
                    onDeleteItem: deleteItem,
                    onSelectItem: selectItemDetail
                )
                
                // Work Category
                SectionView(
                    title: ButtonCategory(id: UUID(), name: "Work"),
                    items: $workItems,
                    otherLists: [$foodItems, $noneItems],
                    showingFullScreen: $showingFullScreen,
                    onEditItem: startEditingItem,
                    onDeleteItem: deleteItem,
                    onSelectItem: selectItemDetail
                )
                
                // None Category
                SectionView(
                    title: ButtonCategory(id: UUID(), name: "None"),
                    items: $noneItems,
                    otherLists: [$foodItems, $workItems],
                    showingFullScreen: $showingFullScreen,
                    onEditItem: startEditingItem,
                    onDeleteItem: deleteItem,
                    onSelectItem: selectItemDetail
                )
            }
            .padding()
            .navigationBarTitle("分类按钮列表", displayMode: .inline)
            .navigationBarItems(trailing: Button(action: {
                isAddingNewItem = true
            }) {
                Image(systemName: "plus")
            })
            .sheet(isPresented: $isAddingNewItem) {
                SelectCategoryView(
                    newItemText: $newItemText,
                    selectedCategory: $selectedCategoryForNewItem,
                    categories: [
                        ButtonCategory(id: UUID(), name: "Food"),
                        ButtonCategory(id: UUID(), name: "Work"),
                        ButtonCategory(id: UUID(), name: "None")
                    ],
                    onSave: addItem,
                    onCancel: {
                        isAddingNewItem = false
                    }
                )
            }
            .sheet(isPresented: $isEditingItem) {
                if let item = itemToEdit {
                    EditItemView(
                        itemText: item.text,
                        onSave: { newText in
                            updateItem(category: item.category, index: item.index, newValue: newText)
                        },
                        onCancel: {
                            isEditingItem = false
                        }
                    )
                }
            }
            .sheet(item: $selectedItemDetail) { detail in
                ItemDetailView(detailText: detail.value)
            }
            .onAppear(perform: loadData)
            .onDisappear(perform: saveData)
        }
    }
    
    // Functions to handle data operations
    func addItem() {
        if let category = selectedCategoryForNewItem {
            getItems(for: category.name).wrappedValue.append(newItemText)
        }
        newItemText = ""
        selectedCategoryForNewItem = nil
        isAddingNewItem = false
    }
    
    func startEditingItem(category: ButtonCategory, itemIndex: Int) {
        let itemText = getItems(for: category.name).wrappedValue[itemIndex]
        itemToEdit = (category, itemIndex, itemText)
        isEditingItem = true
    }
    
    func updateItem(category: ButtonCategory, index: Int, newValue: String) {
        getItems(for: category.name).wrappedValue[index] = newValue
        isEditingItem = false
    }
    
    func deleteItem(category: ButtonCategory, itemIndex: Int) {
        getItems(for: category.name).wrappedValue.remove(at: itemIndex)
    }
    
    func selectItemDetail(item: String) {
        selectedItemDetail = IdentifiableString(value: item)
    }
    
    func getItems(for category: String) -> Binding<[String]> {
        switch category {
        case "Food": return $foodItems
        case "Work": return $workItems
        default: return $noneItems
        }
    }
    
    func saveData() {
        saveList(foodItems, to: &savedFoodItems)
        saveList(workItems, to: &savedWorkItems)
        saveList(noneItems, to: &savedNoneItems)
    }
    
    func loadData() {
        foodItems = loadList(from: savedFoodItems) ?? []
        workItems = loadList(from: savedWorkItems) ?? []
        noneItems = loadList(from: savedNoneItems) ?? []
    }
    
    private func saveList(_ list: [String], to storage: inout Data) {
        if let data = try? JSONEncoder().encode(list) {
            storage = data
        }
    }
    
    private func loadList(from storage: Data) -> [String]? {
        if let decoded = try? JSONDecoder().decode([String].self, from: storage) {
            return decoded
        }
        return nil
    }
}

struct SectionView: View {
    let title: ButtonCategory
    @Binding var items: [String]
    var otherLists: [Binding<[String]>]
    @Binding var showingFullScreen: ButtonCategory?
    var onEditItem: (ButtonCategory, Int) -> Void
    var onDeleteItem: (ButtonCategory, Int) -> Void
    var onSelectItem: (String) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            Text(title.name)
                .font(.headline)
                .padding(.top)
            
            List {
                ForEach(items.indices, id: \.self) { index in
                    Text(items[index])
                        .onTapGesture {
                            onSelectItem(items[index])
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                            Button("Edit") {
                                onEditItem(title, index)
                            }
                            .tint(.blue)
                            Button("Delete") {
                                onDeleteItem(title, index)
                            }
                            .tint(.red)
                        }
                }
            }
            .listStyle(PlainListStyle())
        }
    }
}

struct SelectCategoryView: View {
    @Binding var newItemText: String
    @Binding var selectedCategory: ButtonCategory?
    let categories: [ButtonCategory]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Enter new item", text: $newItemText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Text("Select Category")
                    .font(.headline)
                    .padding(.top)
                
                List(categories) { category in
                    Text(category.name)
                        .onTapGesture {
                            selectedCategory = category
                        }
                        .foregroundColor(selectedCategory == category ? .blue : .black)
                }
                
                HStack {
                    Button("Cancel", action: onCancel)
                    Button("Save", action: onSave)
                        .disabled(selectedCategory == nil || newItemText.isEmpty)
                }
                .padding()
            }
            .navigationBarTitle("Add Item", displayMode: .inline)
        }
    }
}

struct EditItemView: View {
    @State var itemText: String
    let onSave: (String) -> Void
    let onCancel: () -> Void
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Edit item", text: $itemText)
                    .padding()
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                HStack {
                    Button("Cancel", action: onCancel)
                    Button("Save", action: { onSave(itemText) })
                }
                .padding()
            }
            .navigationBarTitle("Edit Item", displayMode: .inline)
        }
    }
}

struct ItemDetailView: View {
    let detailText: String
    
    var body: some View {
        VStack {
            Text("Detail View")
                .font(.largeTitle)
                .padding()
            Text(detailText)
                .padding()
        }
    }
}
