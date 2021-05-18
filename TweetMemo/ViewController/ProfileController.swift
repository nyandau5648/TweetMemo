
import UIKit
import RealmSwift

private let realm = try! Realm()
private let userObject = Array(realm.objects(User.self))
private let tweetObject = Array(realm.objects(Tweet.self))

enum ProfileFilterOptions: Int, CaseIterable {
    
    case tweets
    case replies
    case likes
    
    var description: String {
        switch self {
        case .tweets: return "ツイート"
        case .replies: return "返信"
        case .likes: return "いいね"
        }
    }
    
}

class ProfileController: UICollectionViewController, TimeStampRepository {
    
    // MARK: - Properties
    
    let currentUser = CurrentUser.shared
    let users = realm.objects(User.self)
    private let userId: Int
    
    private let reuseIdentifier = "TweetCell"
    private let headerIdentifier = "ProfileHeader"
    
    private var tweets: [Tweet] = [Tweet]() {
        didSet { collectionView.reloadData() }
    }
    private var replyTweet = [ReplyTweet]()

    private var likedTweets = [Tweet]()
    private var replyLikedTweet = [ReplyTweet]()
    
    private var selectedFilter: ProfileFilterOptions = .tweets {
        didSet { collectionView.reloadData() }
    }
    
    private var selectedImageView = UIImageView()
    
    private var pageViewController: UIPageViewController {
        return self.children[0] as! UIPageViewController
    }
    
    private var currentViewController: PhotoZoomViewController {
        return self.pageViewController.viewControllers![0] as! PhotoZoomViewController
    }
    
    public var currentLeftSafeAreaInset  : CGFloat = 0.0
    public var currentRightSafeAreaInset : CGFloat = 0.0
    
    // MARK: - Lifecycle
    
    init(userId: Int) {
        self.userId = userId
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureCollectionView()
        tweets = Array(realm.objects(Tweet.self))
            .filter {
                currentUser.user!.followUserList.firstIndex(of: $0.userId) != nil || $0.userId == userId
            }
            .sorted(by: { $0.timestamp > $1.timestamp })
        likedTweets = tweets.filter { $0.didLike }
        
        replyTweet = Array(realm.objects(ReplyTweet.self))
            .filter {
                currentUser.user!.followUserList.firstIndex(of: $0.userId) != nil || $0.userId == userId
            }
            .sorted(by: { $0.replyTimeStamp > $1.replyTimeStamp })
        replyLikedTweet = replyTweet.filter { $0.didLike }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
    private func checkIfUserIsFollowed(){
        collectionView.reloadData()
    }
    
    // MARK: - UI
    
    private func configureCollectionView(){
        collectionView.backgroundColor = UIColor(named: "Mode")
        collectionView.contentInsetAdjustmentBehavior = .never
        collectionView.register(TweetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(ProfileHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headerIdentifier)
    }
    
    // MARK: - Helper
    
    private func calcSize(width: CGFloat, text: String) -> CGSize {
        let measurementLabel = UILabel()
        measurementLabel.text = text
        measurementLabel.numberOfLines = 0
        measurementLabel.lineBreakMode = .byWordWrapping
        measurementLabel.translatesAutoresizingMaskIntoConstraints = false
        measurementLabel.widthAnchor.constraint(equalToConstant: width).isActive = true
        return measurementLabel.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize)
    }
    
    private func getTitle(for index: Int) -> NSMutableAttributedString {
        let tweetIndex = tweets[index]
        let userFirstIndex = users.first(where: { $0.id == tweetIndex.userId})
        let title = NSMutableAttributedString(string: userFirstIndex!.fullname, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        title.append(NSAttributedString(string: " @\(userFirstIndex!.username)", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        title.append(NSAttributedString(string: "・\(getTimeStamp(from: tweetIndex.timestamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return title
    }
    
    private func getReplyTitle(for index: Int) -> NSMutableAttributedString {
        let replyTweetIndex = replyTweet[index]
        let userFirstIndex = users.first(where: { $0.id == replyTweetIndex.userId})
        let title = NSMutableAttributedString(string: userFirstIndex!.fullname, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        title.append(NSAttributedString(string: " @\(userFirstIndex!.username)", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        title.append(NSAttributedString(string: "・\(getTimeStamp(from: replyTweetIndex.replyTimeStamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return title
    }
    
    private func getLikedTitle(for index: Int) -> NSMutableAttributedString {
        let tweetIndex = likedTweets[index]
        let userFirstIndex = users.first(where: { $0.id == tweetIndex.userId})
        let title = NSMutableAttributedString(string: userFirstIndex!.fullname, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        title.append(NSAttributedString(string: " @\(userFirstIndex!.username)", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        title.append(NSAttributedString(string: "・\(getTimeStamp(from: tweetIndex.timestamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return title
    }
    
    private func getReplyLikedTitle(for index: Int) -> NSMutableAttributedString {
        let replyTweetIndex = replyLikedTweet[index]
        let userFirstIndex = users.first(where: { $0.id == replyTweetIndex.userId})
        let title = NSMutableAttributedString(string: userFirstIndex!.fullname, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        title.append(NSAttributedString(string: " @\(userFirstIndex!.username)", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        title.append(NSAttributedString(string: "・\(getTimeStamp(from: replyTweetIndex.replyTimeStamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return title
    }
    
    private func getFrameFromImageView(for selectedImage: UIImageView) -> CGRect {
        return selectedImageView.frame
    }
    
    // MARK: - Documents
    
    private func getDocumentsURL() -> NSURL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        return documentsURL
    }
    
    private func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL!.path
    }
    
    // MARK: - Repository
    
    internal func getTimeStamp(from: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: from)
    }
    
}

// MARK: - UICollectionViewDataSource

extension ProfileController {
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        switch self.selectedFilter {
        case .tweets:
            return tweets.count
        case .replies:
            return replyTweet.count
        case .likes:
            return likedTweets.count + replyLikedTweet.count
        }
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TweetCell
        cell.delegate = self
        switch self.selectedFilter {
        case .tweets:
            let tweetIndex = tweets[indexPath.row]
            let userFirstIndex = users.first(where: { $0.id == tweetIndex.userId})
            cell.tweets = tweetIndex
            cell.captionLabel.text = tweetIndex.caption
            cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
            cell.infoLabel.attributedText = getTitle(for: indexPath.row)
            if tweetIndex.didLike == false {
                cell.likeButton.tintColor = .lightGray
                cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
            } else {
                cell.likeButton.tintColor = .red
                cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
            }
            cell.imageURLs = tweetIndex.imageURLs
            cell.configure()
        case .replies:
            let replyTweetIndex = replyTweet[indexPath.row]
            let userFirstIndex = users.first(where: { $0.id == replyTweetIndex.userId})
            cell.replyTweets = replyTweetIndex
            cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
            let count = replyTweet.count
            if indexPath.row < count {
                cell.captionLabel.text = replyTweetIndex.replyCaption
                cell.infoLabel.attributedText = getReplyTitle(for: indexPath.row)
            }
            if replyTweetIndex.didLike == false {
                cell.likeButton.tintColor = .lightGray
                cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
            } else {
                cell.likeButton.tintColor = .red
                cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
            }
            cell.imageURLs = replyTweetIndex.imageURLs
            cell.configure()
        case .likes:
            let resultTweetLikeCount = likedTweets.count
            if indexPath.row < resultTweetLikeCount {
                let resultTweetLikeIndex = likedTweets[indexPath.row]
                let userFirstIndex = users.first(where: { $0.id == resultTweetLikeIndex.userId})
                    cell.tweets = resultTweetLikeIndex
                    cell.captionLabel.text = resultTweetLikeIndex.caption
                    cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
                    cell.infoLabel.attributedText = getLikedTitle(for: indexPath.row)
                    cell.likeButton.tintColor = .red
                    cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                    cell.imageURLs = resultTweetLikeIndex.imageURLs
                    cell.configure()
                
            } else {
                let minusTweet = indexPath.row - resultTweetLikeCount
                let resultReplyLikeIndex = replyLikedTweet[minusTweet]
                let userFirstIndex = users.first(where: { $0.id == resultReplyLikeIndex.userId})
                    cell.replyTweets = resultReplyLikeIndex
                    cell.captionLabel.text = resultReplyLikeIndex.replyCaption
                    cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
                    cell.infoLabel.attributedText = getReplyLikedTitle(for: minusTweet)
                    cell.likeButton.tintColor = .red
                    cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                    cell.imageURLs = resultReplyLikeIndex.imageURLs
                    cell.configure()
            }
            
        }
        return cell
    }
    
    
}

// MARK: - UICollectionViewDelegate

extension ProfileController {
    
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headerIdentifier, for: indexPath) as! ProfileHeader
        header.delegate = self
        let userFirstIndex = users.first(where: { $0.id == userId})
        header.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
        header.fullnameLabel.text = userFirstIndex!.fullname
        header.usernameLabel.text = "@" + userFirstIndex!.username
        header.profileLabel.text = userFirstIndex!.profileText
        if currentUser.user!.id != userId {
            header.editProfileFollowButton.isEnabled = false
            header.editProfileFollowButton.alpha = 0.6
        }
        return header
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension ProfileController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let userIndex = users.firstIndex(where: { $0.id == userId })
        let height = calcSize(width: view.frame.width, text: users[userIndex!].profileText!).height
        return CGSize(width: view.frame.width, height: height + 280)
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        switch selectedFilter {
        case .tweets:
            let height = calcSize(width: view.frame.width, text: tweets[indexPath.row].caption).height
            let imageContainerHeight: CGFloat = tweets[indexPath.row].imageURLs.isEmpty ? 0 : 160
            return CGSize(width: view.frame.width, height: height + 100 + imageContainerHeight)
        case .replies:
            let height = calcSize(width: view.frame.width, text: replyTweet[indexPath.row].replyCaption).height
            let imageContainerHeight: CGFloat = replyTweet[indexPath.row].imageURLs.isEmpty ? 0 : 160
            return CGSize(width: view.frame.width, height: height + 100 + imageContainerHeight)
        case .likes:
            let count = likedTweets.count
            if indexPath.row < count {
                let height = calcSize(width: view.frame.width, text: likedTweets[indexPath.row].caption).height
                let imageContainerHeight: CGFloat = likedTweets[indexPath.row].imageURLs.isEmpty ? 0 : 160
                return CGSize(width: view.frame.width, height: height + 100 + imageContainerHeight)
            } else {
                let minusTweet = indexPath.row - count
                let height = calcSize(width: view.frame.width, text: replyLikedTweet[minusTweet].replyCaption).height
                let imageContainerHeight: CGFloat = replyLikedTweet[minusTweet].imageURLs.isEmpty ? 0 : 160
                return CGSize(width: view.frame.width, height: height + 100 + imageContainerHeight)
            }
        }
    }
    
}

// MARK: - ProfileHeaderDelegate

extension ProfileController: ProfileHeaderDelegate {
    
    func didSelect(filter: ProfileFilterOptions) {
        self.selectedFilter = filter
        collectionView.reloadData()
    }
    
    func handleEditProfileFollow(_ header: ProfileHeader) {
        let controller = EditProfileController()
        controller.delegate = self as? EditProfileControllerDelegate
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
        return
    }
    
    func handleDismissal() {
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.popViewController(animated: true)
    }
    
}

// MARK: - TweetCellDelegate

extension ProfileController: TweetCellDelegate {
    
    func handleProfileImageTapped(_ cell: TweetCell) {
        let controller = EditProfileController()
        controller.delegate = self as? EditProfileControllerDelegate
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func handleReplyTapped(_ cell: TweetCell) {
        let tweet = cell.tweets
        let controller = UploadTweetController(config: .reply(tweet))
        switch selectedFilter {
        case .tweets:
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case .replies:
            let nav = UINavigationController(rootViewController: controller)
            nav.modalPresentationStyle = .fullScreen
            present(nav, animated: true, completion: nil)
        case .likes:
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
        }
    }
    
    func handleRetweetTapped(_ cell: TweetCell) {
        switch selectedFilter {
        case .tweets:
            let indexPath = self.collectionView.indexPath(for: cell)
            let tweetIndex = tweets[indexPath!.row]
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
            let formatString = formatter.string(from: Date())
            try! realm.write {
                tweetIndex.timestamp = formatter.date(from: formatString)!
            }
            self.tweets = tweets.sorted(by: { $0.timestamp > $1.timestamp })
            collectionView.reloadData()
        case .replies:
            let indexPath = self.collectionView.indexPath(for: cell)
            let replyTweetIndex = replyTweet[indexPath!.row]
            let formatter: DateFormatter = DateFormatter()
            formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
            let formatString = formatter.string(from: Date())
            try! realm.write {
                replyTweetIndex.replyTimeStamp = formatter.date(from: formatString)!
            }
            self.replyTweet = replyTweet.sorted(by: { $0.replyTimeStamp > $1.replyTimeStamp })
            collectionView.reloadData()
        case .likes:
            let indexPath = self.collectionView.indexPath(for: cell)
            let resultTweetLikeCount = likedTweets.count
            if indexPath!.row < resultTweetLikeCount {
                let resultTweetLikeIndex = likedTweets[indexPath!.row]
                let formatter: DateFormatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
                let formatString = formatter.string(from: Date())
                try! realm.write {
                    resultTweetLikeIndex.timestamp = formatter.date(from: formatString)!
                }
                self.likedTweets = likedTweets.sorted(by: { $0.timestamp > $1.timestamp })
                collectionView.reloadData()
            } else {
                let minusTweet = indexPath!.row - resultTweetLikeCount
                let resultReplyTweetLikeIndex = replyLikedTweet[minusTweet]
                let formatter: DateFormatter = DateFormatter()
                formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
                let formatString = formatter.string(from: Date())
                try! realm.write {
                    resultReplyTweetLikeIndex.replyTimeStamp = formatter.date(from: formatString)!
                }
                self.replyLikedTweet = replyLikedTweet.sorted(by: { $0.replyTimeStamp > $1.replyTimeStamp })
                collectionView.reloadData()
            }
        }
    }
    
    func handleLikeTapped(_ cell: TweetCell) {
        switch selectedFilter {
        case .tweets:
            let indexPath = self.collectionView.indexPath(for: cell)
            let tweetIndex = tweets[indexPath!.row]
            try! realm.write {
                tweetIndex.didLike.toggle()
                if tweetIndex.didLike == false {
                    cell.likeButton.tintColor = .lightGray
                    cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                    tweetIndex.likes -= 1
                    realm.add(tweetIndex, update: .all)
                } else {
                    cell.likeButton.tintColor = .red
                    cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                    tweetIndex.likes += 1
                    realm.add(tweetIndex, update: .all)
                }
            }
        case .replies:
            let indexPath = self.collectionView.indexPath(for: cell)
            let replyTweetIndex = replyTweet[indexPath!.row]
            try! realm.write {
                replyTweetIndex.didLike.toggle()
                if replyTweetIndex.didLike == false {
                    cell.likeButton.tintColor = .lightGray
                    cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                    replyTweetIndex.likes -= 1
                    realm.add(replyTweetIndex, update: .all)
                } else {
                    cell.likeButton.tintColor = .red
                    cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                    replyTweetIndex.likes += 1
                    realm.add(replyTweetIndex, update: .all)
                }
            }
        case .likes:
        let indexPath = self.collectionView.indexPath(for: cell)
        let count = likedTweets.count
            if indexPath!.row < count {
                let likedTweetIndex = likedTweets[indexPath!.row]
                try! realm.write {
                    likedTweetIndex.didLike.toggle()
                    if likedTweetIndex.didLike == false {
                        cell.likeButton.tintColor = .lightGray
                        cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                        likedTweetIndex.likes -= 1
                        realm.add(likedTweetIndex, update: .all)
                    } else {
                        cell.likeButton.tintColor = .red
                        cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                        likedTweetIndex.likes += 1
                        realm.add(likedTweetIndex, update: .all)
                    }
                }
            } else {
                let minusTweet = indexPath!.row - count
                let replyLikedTweetIndex = replyLikedTweet[minusTweet]
                try! realm.write {
                    replyLikedTweetIndex.didLike.toggle()
                    if replyLikedTweetIndex.didLike == false {
                        cell.likeButton.tintColor = .lightGray
                        cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                        replyLikedTweetIndex.likes -= 1
                        realm.add(replyLikedTweetIndex, update: .all)
                    } else {
                        cell.likeButton.tintColor = .red
                        cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                        replyLikedTweetIndex.likes += 1
                        realm.add(replyLikedTweetIndex, update: .all)
                    }
                }
            }
        }
    }
    
    func handleShareTapped(_ cell: TweetCell) {
        let indexPath = self.collectionView.indexPath(for: cell)
        switch selectedFilter {
        case .tweets:
            let tweetIndex = tweets[indexPath!.row]
            let controller = UIActivityViewController(activityItems: [tweetIndex.caption], applicationActivities: nil)
            self.present(controller, animated: true, completion: nil)
        case .replies:
            let replyTweetIndex = replyTweet[indexPath!.row]
            let controller = UIActivityViewController(activityItems: [replyTweetIndex.replyCaption], applicationActivities: nil)
            self.present(controller, animated: true, completion: nil)
        case .likes:
            let count = likedTweets.count
            let minusTweet = indexPath!.row - count
            if indexPath!.row < count {
                let controller = UIActivityViewController(activityItems: [likedTweets[indexPath!.row].caption], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            } else {
                let controller = UIActivityViewController(activityItems: [replyLikedTweet[minusTweet].replyCaption], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            }
            
        }
    }
    
    func deleteActionSheet(_ cell: TweetCell) {
        switch selectedFilter {
        case .tweets:
            let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { [self] (action: UIAlertAction!) -> Void in
                let indexPath = self.collectionView.indexPath(for: cell)
                let tweetIndex = self.tweets[indexPath!.row]
                if tweetIndex.replyTweet.isEmpty {
                    cell.imageURLs.enumerated().forEach { index,image in
                        let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                        try? FileManager.default.removeItem(atPath: fileURL)
                    }
                    try! realm.write {
                        realm.delete(tweetIndex)
                        self.tweets.remove(at: indexPath!.row)
                        likedTweets = tweets
                    }
                } else {
                    try! realm.write {
                        tweetIndex.replyTweet.forEach { [weak self]  replyTweets in
                            self?.replyTweet.removeAll(where: { $0.replyTweetId == replyTweets.replyTweetId })
                        }
                        cell.imageURLs.enumerated().forEach { index,image in
                            let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                            try? FileManager.default.removeItem(atPath: fileURL)
                        }
                        tweetIndex.replyTweet.forEach { replys in
                            replys.imageURLs.enumerated().forEach { index,image in
                                let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                                try? FileManager.default.removeItem(atPath: fileURL)
                            }
                        }
                        self.tweets.removeAll(where: { $0.tweetId == tweetIndex.tweetId })
                        realm.delete(tweetIndex.replyTweet)
                        realm.delete(tweetIndex)
                        likedTweets = tweets
                        replyLikedTweet = replyTweet
                    }
                }
                self.collectionView.reloadData()
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
            alert.pruneNegativeWidthConstraints()
            self.present(alert, animated: true, completion: nil)
        case .replies:
            let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
            alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { (action: UIAlertAction!) -> Void in
                let indexPath = self.collectionView.indexPath(for: cell)
                let replyTweetIndex = self.replyTweet[indexPath!.row]
                cell.imageURLs.enumerated().forEach { index,image in
                    let fileURL = self.fileInDocumentsDirectory(filename: image.imageURL)
                    try? FileManager.default.removeItem(atPath: fileURL)
                }
                try! realm.write {
                    realm.delete(replyTweetIndex)
                    self.replyTweet.remove(at: indexPath!.row)
                    self.replyLikedTweet = self.replyTweet
                }
                self.collectionView.reloadData()
            }))
            alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
            alert.pruneNegativeWidthConstraints()
            self.present(alert, animated: true, completion: nil)
        case .likes:
            let indexPath = self.collectionView.indexPath(for: cell)
            let resultTweetLikeCount = likedTweets.count
            let minusTweet = indexPath!.row - resultTweetLikeCount
            if indexPath!.row < resultTweetLikeCount {
                let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { [self] (action: UIAlertAction!) -> Void in
                    let resultTweetLikeIndex = likedTweets[indexPath!.row]
                    if resultTweetLikeIndex.replyTweet.isEmpty {
                        cell.imageURLs.enumerated().forEach { index,image in
                            let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                            try? FileManager.default.removeItem(atPath: fileURL)
                        }
                        try! realm.write {
                            realm.delete(resultTweetLikeIndex)
                            tweets.remove(at: indexPath!.row)
                            self.likedTweets.remove(at: indexPath!.row)
                        }
                    } else {
                        cell.imageURLs.enumerated().forEach { index,image in
                            let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                            try? FileManager.default.removeItem(atPath: fileURL)
                        }
                        resultTweetLikeIndex.replyTweet.forEach { replys in
                            replys.imageURLs.enumerated().forEach { index,image in
                                let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                                try? FileManager.default.removeItem(atPath: fileURL)
                            }
                        }
                        try! realm.write {
                            resultTweetLikeIndex.replyTweet.forEach { [weak self]  replyTweets in
                                self?.replyLikedTweet.removeAll(where: { $0.replyTweetId == replyTweets.replyTweetId })
                                realm.delete(replyTweets)
                                replyTweet.remove(at: indexPath!.row)
                            }
                            realm.delete(resultTweetLikeIndex.replyTweet)
                            realm.delete(resultTweetLikeIndex)
                            tweets.remove(at: indexPath!.row)
                            self.likedTweets.remove(at: indexPath!.row)
                        }
                    }
                    self.collectionView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
                alert.pruneNegativeWidthConstraints()
                self.present(alert, animated: true, completion: nil)
            } else {
                let resultReplyLikeIndex = replyLikedTweet[minusTweet]
                let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
                alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { (action: UIAlertAction!) -> Void in
                    cell.imageURLs.enumerated().forEach { index,image in
                        let fileURL = self.fileInDocumentsDirectory(filename: image.imageURL)
                        try? FileManager.default.removeItem(atPath: fileURL)
                    }
                    try! realm.write {
                        realm.delete(resultReplyLikeIndex)
                        self.replyLikedTweet.remove(at: minusTweet)
                        self.replyTweet.remove(at: minusTweet)
                    }
                    self.collectionView.reloadData()
                }))
                alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
                alert.pruneNegativeWidthConstraints()
                self.present(alert, animated: true, completion: nil)
            }
        }
    }
    
    func selectedImageView(_ imageView: UIImageView, tag: Int, imageURLs: List<CellImageURL>) {
        selectedImageView = imageView
        navigationController?.setNavigationBarHidden(true, animated: true)
        let vc = PhotoPageContainerViewController()
        navigationController?.delegate = vc.transitionController
        vc.transitionController.fromDelegate = self
        vc.transitionController.toDelegate = vc
        vc.delegate = self
        vc.currentIndex = tag
        vc.imageURLs = imageURLs
        navigationController?.pushViewController(vc, animated: true)
    }
}

// MARK: - ZoomAnimatorDelegate

extension ProfileController: ZoomAnimatorDelegate {

    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
    }

    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
    }

    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return selectedImageView
    }

    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        view.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        let unconvertedFrame = getFrameFromImageView(for: selectedImageView)
        let imageViewFrame = selectedImageView.convert(unconvertedFrame, to: self.view)
        if imageViewFrame.minY < self.selectedImageView.largeContentImageInsets.top {
            return CGRect(x: imageViewFrame.minX, y: selectedImageView.largeContentImageInsets.top, width: (selectedImageView.image?.size.width)!, height: imageViewFrame.height - (selectedImageView.largeContentImageInsets.top - imageViewFrame.minY))
        }
        return imageViewFrame
    }

}

// MARK: - PhotoPageContainerViewControllerDelegate

extension ProfileController: PhotoPageContainerViewControllerDelegate {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int) {
    }
}
