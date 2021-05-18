
import UIKit
import RealmSwift

struct SigninUser {
    let id: Int
    var fullname: String
    var username: String
    var profileText: String?
    var profileImage: Data?
    var followUserList: [Int]
}

class CurrentUser {
    static let shared: CurrentUser = .init()
    private init() {}
//    private(set) var user: SigninUser? = nil
    var user: SigninUser? = nil
    func setUser(_ user: User) {
        self.user = .init(
            id: user.id,
            fullname: user.fullname,
            username: user.username,
            profileText: user.profileText,
            profileImage: user.profileImage,
            followUserList: user.followUserList.map { $0 }
        )
    }
    func signout() {
        self.user = nil
    }
}

