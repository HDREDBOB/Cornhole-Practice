import SwiftUI

struct BagTypesManagementView: View {
    @State private var bagTypes: [String] = []
    @State private var defaultBagType: String = "Default"
    @State private var newBagName: String = ""
    @State private var showingAddBagPopup = false
    
    var body: some View {
        NavigationView {
            VStack {
                // Header
                Text("Bag Management")
                    .font(.headline)
                    .padding()
                
                // Add Button
                Button("Add New Bag") {
                    showingAddBagPopup = true
                }
                .padding()
                
                // List of Bags
                List {
                    ForEach(bagTypes, id: \.self) { bagType in
                        HStack {
                            Text(bagType)
                            Spacer()
                            if bagType != "Default" {
                                Button {
                                    defaultBagType = bagType
                                    saveBagTypes()
                                } label: {
                                    Image(systemName: bagType == defaultBagType ? "star.fill" : "star")
                                        .foregroundColor(bagType == defaultBagType ? .yellow : .gray)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if !indexSet.contains(where: { bagTypes[$0] == "Default" }) {
                            bagTypes.remove(atOffsets: indexSet)
                            saveBagTypes()
                        }
                    }
                }
            }
            .onAppear(perform: loadBagTypes)
            .sheet(isPresented: $showingAddBagPopup) {
                AddBagView(bagTypes: $bagTypes, isPresented: $showingAddBagPopup)
            }
        }
    }
    
    private func loadBagTypes() {
        print("Loading bag types...")
        var loaded = UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
        if loaded.isEmpty || !loaded.contains("Default") {
            loaded = ["Default"]
        }
        bagTypes = loaded
        defaultBagType = UserDefaults.standard.string(forKey: "DefaultBagType") ?? "Default"
        print("Loaded bag types: \(bagTypes)")
    }
    
    private func saveBagTypes() {
        print("Saving bag types: \(bagTypes)")
        UserDefaults.standard.set(bagTypes, forKey: "CornholeBagTypes")
        UserDefaults.standard.set(defaultBagType, forKey: "DefaultBagType")
    }
}

struct AddBagView: View {
    @Binding var bagTypes: [String]
    @Binding var isPresented: Bool
    @State private var newBagName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Bag Name", text: $newBagName)
                
                Button("Add Bag") {
                    let trimmedName = newBagName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty && !bagTypes.contains(trimmedName) && trimmedName != "Default" {
                        bagTypes.append(trimmedName)
                        UserDefaults.standard.set(bagTypes, forKey: "CornholeBagTypes")
                        isPresented = false
                    }
                }
                .disabled(newBagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Add New Bag")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
