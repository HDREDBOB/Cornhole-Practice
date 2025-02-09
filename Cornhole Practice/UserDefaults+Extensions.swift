import Foundation

extension UserDefaults {
    static let lastSelectedBagTypeKey = "lastSelectedBagType"
    static let defaultBagTypeKey = "defaultBagType"
    
    var lastSelectedBagType: String? {
        get { string(forKey: Self.lastSelectedBagTypeKey) }
        set { set(newValue, forKey: Self.lastSelectedBagTypeKey) }
    }
    
    var defaultBagType: String? {
        get { string(forKey: Self.defaultBagTypeKey) }
        set { set(newValue, forKey: Self.defaultBagTypeKey) }
    }
}

