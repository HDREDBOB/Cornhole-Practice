import SwiftUI

struct BagTypesManagementView: View {
    @State private var bagTypes: [String] = []
    @State private var defaultBagType: String = "Default"
    @State private var throwingStyles: [String] = []
    @State private var defaultThrowingStyle: String = "Default"
    @State private var showingAddBagPopup = false
    @State private var showingAddStylePopup = false
    
    var body: some View {
        NavigationView {
            List {
                // Bags Section
                Section(header:
                    HStack {
                        Text("Bag Management")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button("Add New Bag") {
                            showingAddBagPopup = true
                        }
                        .font(.subheadline)
                    }
                ) {
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
                
                // Throwing Styles Section
                Section(header:
                    HStack {
                        Text("Throwing Styles")
                            .font(.title3)
                            .fontWeight(.bold)
                        Spacer()
                        Button("Add New Style") {
                            showingAddStylePopup = true
                        }
                        .font(.subheadline)
                    }
                ) {
                    ForEach(throwingStyles, id: \.self) { style in
                        HStack {
                            Text(style)
                            Spacer()
                            if style != "Default" {
                                Button {
                                    defaultThrowingStyle = style
                                    saveThrowingStyles()
                                } label: {
                                    Image(systemName: style == defaultThrowingStyle ? "star.fill" : "star")
                                        .foregroundColor(style == defaultThrowingStyle ? .yellow : .gray)
                                }
                            }
                        }
                    }
                    .onDelete { indexSet in
                        if !indexSet.contains(where: { throwingStyles[$0] == "Default" }) {
                            throwingStyles.remove(atOffsets: indexSet)
                            saveThrowingStyles()
                        }
                    }
                }
            }
                       .navigationTitle("Bags & Styles")
                       .onAppear(perform: loadData)
                       .sheet(isPresented: $showingAddBagPopup) {
                           AddBagView(bagTypes: $bagTypes, isPresented: $showingAddBagPopup)
                       }
                       .sheet(isPresented: $showingAddStylePopup) {
                           AddThrowingStyleView(throwingStyles: $throwingStyles, isPresented: $showingAddStylePopup)
                       }
                   }
               }
               
               private func loadData() {
                   loadBagTypes()
                   loadThrowingStyles()
               }
               
               private func loadBagTypes() {
                   var loaded = UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
                   if loaded.isEmpty || !loaded.contains("Default") {
                       loaded = ["Default"]
                   }
                   bagTypes = loaded
                   defaultBagType = UserDefaults.standard.string(forKey: "DefaultBagType") ?? "Default"
               }
               
               private func saveBagTypes() {
                   // If the current defaultBagType is not in the updated bagTypes list, reset it to "Default"
                   if !bagTypes.contains(defaultBagType) {
                       defaultBagType = "Default"
                   }
                   
                   UserDefaults.standard.set(bagTypes, forKey: "CornholeBagTypes")
                   UserDefaults.standard.set(defaultBagType, forKey: "DefaultBagType")
               }
    
    private func loadThrowingStyles() {
        var loaded = UserDefaults.standard.stringArray(forKey: "ThrowingStyles") ?? []
        if loaded.isEmpty || !loaded.contains("Default") {
            loaded = ["Default"]
        }
        throwingStyles = loaded
        defaultThrowingStyle = UserDefaults.standard.string(forKey: "DefaultThrowingStyle") ?? "Default"
    }
    
    private func saveThrowingStyles() {
        // If the current defaultThrowingStyle is not in the updated throwingStyles list, reset it to "Default"
        if !throwingStyles.contains(defaultThrowingStyle) {
            defaultThrowingStyle = "Default"
        }
        
        UserDefaults.standard.set(throwingStyles, forKey: "ThrowingStyles")
        UserDefaults.standard.set(defaultThrowingStyle, forKey: "DefaultThrowingStyle")
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

struct AddThrowingStyleView: View {
    @Binding var throwingStyles: [String]
    @Binding var isPresented: Bool
    @State private var newStyleName: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                TextField("Style Name", text: $newStyleName)
                
                Button("Add Style") {
                    let trimmedName = newStyleName.trimmingCharacters(in: .whitespaces)
                    if !trimmedName.isEmpty && !throwingStyles.contains(trimmedName) && trimmedName != "Default" {
                        throwingStyles.append(trimmedName)
                        UserDefaults.standard.set(throwingStyles, forKey: "ThrowingStyles")
                        isPresented = false
                    }
                }
                .disabled(newStyleName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .navigationTitle("Add New Throwing Style")
            .navigationBarItems(trailing: Button("Cancel") {
                isPresented = false
            })
        }
    }
}
