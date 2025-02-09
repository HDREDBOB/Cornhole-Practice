import SwiftUI

struct BagTypesManagementView: View {
    @State private var newBagName: String = ""
    @State private var bagTypes: [String] = []
    @State private var defaultBagType: String? = nil
    
    private func loadBagTypes() {
        bagTypes = UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
        defaultBagType = UserDefaults.standard.string(forKey: "DefaultBagType")
        
        // If only one bag type exists, automatically set it as default
        if bagTypes.count == 1 {
            defaultBagType = bagTypes[0]
            UserDefaults.standard.set(defaultBagType, forKey: "DefaultBagType")
        }
    }
    
    private func saveBagTypes() {
        UserDefaults.standard.set(bagTypes, forKey: "CornholeBagTypes")
    }
    
    var body: some View {
        VStack {
            // Add New Bag Type
            HStack {
                TextField("Enter Bag Type Name", text: $newBagName)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                
                Button(action: addBagType) {
                    Image(systemName: "plus.circle.fill")
                        .foregroundColor(.blue)
                }
                .disabled(newBagName.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            
            // List of Existing Bag Types
            List {
                ForEach(bagTypes, id: \.self) { bagType in
                    HStack {
                        Text(bagType)
                        Spacer()
                        
                        // Default bag type selection
                        if bagTypes.count > 1 {
                            Button(action: {
                                setDefaultBagType(bagType)
                            }) {
                                Image(systemName: bagType == defaultBagType ? "star.fill" : "star")
                                    .foregroundColor(bagType == defaultBagType ? .yellow : .gray)
                            }
                        }
                    }
                }
                .onDelete(perform: deleteBagType)
            }
        }
        .navigationTitle("Bag Types")
        .onAppear(perform: loadBagTypes)
    }
    
    private func addBagType() {
        let trimmedName = newBagName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty, !bagTypes.contains(trimmedName) else {
            return
        }
        
        bagTypes.append(trimmedName)
        saveBagTypes()
        
        // If this is the first bag type, set it as default
        if bagTypes.count == 1 {
            setDefaultBagType(trimmedName)
        }
        
        newBagName = ""
    }
    
    private func deleteBagType(at offsets: IndexSet) {
        // Remove the bag type
        let removedBagTypes = offsets.map { bagTypes[$0] }
        bagTypes.remove(atOffsets: offsets)
        saveBagTypes()
        
        // If the deleted bag was the default, handle default selection
        if removedBagTypes.contains(defaultBagType ?? "") {
            if bagTypes.count == 1 {
                // If only one bag remains, set it as default
                setDefaultBagType(bagTypes[0])
            } else if !bagTypes.isEmpty {
                // If multiple bags remain, clear the default
                clearDefaultBagType()
            }
        }
    }
    
    private func setDefaultBagType(_ bagType: String) {
        defaultBagType = bagType
        UserDefaults.standard.set(bagType, forKey: "DefaultBagType")
    }
    
    private func clearDefaultBagType() {
        defaultBagType = nil
        UserDefaults.standard.removeObject(forKey: "DefaultBagType")
    }
}
