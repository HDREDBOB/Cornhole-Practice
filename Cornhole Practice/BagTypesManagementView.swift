import SwiftUI

struct BagTypesManagementView: View {
    @State private var newBagName: String = ""
    @State private var bagTypes: [String] = []
    
    private func loadBagTypes() {
        bagTypes = UserDefaults.standard.stringArray(forKey: "CornholeBagTypes") ?? []
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
                    Text(bagType)
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
        newBagName = ""
    }
    
    private func deleteBagType(at offsets: IndexSet) {
        bagTypes.remove(atOffsets: offsets)
        saveBagTypes()
    }
}
