
import Foundation
import UIKit
import RealmSwift

class User: Object {
    
    @objc dynamic var id: Int = 0
    @objc dynamic var fullname: String = ""
    @objc dynamic var username: String = ""
    @objc dynamic var profileText: String? = ""
    @objc dynamic var profileImage: Data? = nil

    var followUserList = List<Int>()
    
    override static func primaryKey() -> String? {
        return "id"
    }
    
}
