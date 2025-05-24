import Foundation

public struct AppUser: Equatable {
    public let uid: String
    public let email: String?
    
    public init(uid: String, email: String?) {
        self.uid = uid
        self.email = email
    }
    
    public static func == (lhs: AppUser, rhs: AppUser) -> Bool {
        // Only compare UIDs since that's what makes a user unique
        lhs.uid == rhs.uid
    }
}
