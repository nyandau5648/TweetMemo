
import Foundation
import UIKit
import RealmSwift

class Tweet: Object {
    
    @objc dynamic var tweetId: Int = 0
    @objc dynamic var userId: Int = 0
    @objc dynamic var caption: String = ""
    @objc dynamic var timestamp: Date = Date()
    @objc dynamic var likes: Int = 0
    @objc dynamic var didLike = false
    @objc dynamic var profileImage: Data? = nil
    
    let replyTweet = List<ReplyTweet>()
    
    var imageURLs = List<CellImageURL>()
    
    override static func primaryKey() -> String? {
        return "tweetId"
    }
    
}

class ReplyTweet: Object {
    
    @objc dynamic var replyTweetId: Int = 0
    @objc dynamic var userId: Int = 0
    @objc dynamic var replyCaption: String = ""
    @objc dynamic var replyTimeStamp: Date = Date()
    @objc dynamic var likes: Int = 0
    @objc dynamic var didLike = false
    
    let replyTweets = LinkingObjects(fromType: Tweet.self, property: "replyTweet")
    
    let imageURLs = List<CellImageURL>()
    
    override static func primaryKey() -> String? {
        return "replyTweetId"
    }
    
}

class CellImageURL: Object {
    @objc dynamic var imageURL: String = ""
}

protocol TimeStampRepository {
    func getTimeStamp(from: Date) -> String
}
