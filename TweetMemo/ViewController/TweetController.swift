
import UIKit
import RealmSwift

private let realm = try! Realm()
private let userObject = Array(realm.objects(User.self))

protocol TweetTimeStampRepository {
    func getTimeStamp(from: Date) -> String
    func getHeaderTimeStamp(from: Date) -> String
}

class TweetController: UICollectionViewController {
    
    // MARK: - Properties
    
    private let currentUser = CurrentUser.shared
    private let userId: Int
    private var users = Array(realm.objects(User.self))
    
    weak var headerDelegate: TweetHeader?
    
    private let reuseIdentifier = "TweetCell"
    private let headeerIdentifier = "TweetHeader"
    
    private var tweets: Tweet
    private var replyTweet = [ReplyTweet]()
    
    private var selectedImageView = UIImageView()
    
    private var pageViewController: UIPageViewController {
        return self.children[0] as! UIPageViewController
    }
    
    private var currentViewController: PhotoZoomViewController {
        return self.pageViewController.viewControllers![0] as! PhotoZoomViewController
    }
    
    internal var currentLeftSafeAreaInset  : CGFloat = 0.0
    internal var currentRightSafeAreaInset : CGFloat = 0.0
    
    // MARK: - Lifecycle

    init(tweets: Tweet, userId: Int){
        self.tweets = tweets
        self.userId = userId
        super.init(collectionViewLayout: UICollectionViewFlowLayout())
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        replyTweet = Array(tweets.replyTweet)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configureUI()
        configureCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        replyTweet = Array(tweets.replyTweet)
        collectionView.reloadData()
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11, *) {
            self.currentLeftSafeAreaInset = view.safeAreaInsets.left
            self.currentRightSafeAreaInset = view.safeAreaInsets.right
        }
    }
    
    // MARK: - UI
    
    private func configureUI(){
        view.backgroundColor = UIColor(named: "Mode")
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationController?.setNavigationBarHidden(false, animated: false)
    }

    private func configureCollectionView(){
        collectionView.backgroundColor = UIColor(named: "Mode")
        collectionView.register(TweetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.register(TweetHeader.self, forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader, withReuseIdentifier: headeerIdentifier)
        collectionView.reloadData()
    }
    
    // MARK: Selector
    
    @objc private func leftBarButton(){
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: Helper
    
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
        let replyTweetIndex = replyTweet[index]
        let userFirstIndex = users.first(where: { $0.id == replyTweetIndex.userId})
        let title = NSMutableAttributedString(string: userFirstIndex!.fullname, attributes: [.font: UIFont.boldSystemFont(ofSize: 14)])
        title.append(NSAttributedString(string: " @\(userFirstIndex!.username)", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        title.append(NSAttributedString(string: "・\(getTimeStamp(from: replyTweetIndex.replyTimeStamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray]))
        return title
    }
    
    private func getFrameFromImageView(for selectedImage: UIImageView) -> CGRect {
        return selectedImageView.frame
    }
    
    // MARK: Documents
    
    private func getDocumentsURL() -> NSURL {
        let documentsURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0] as NSURL
        return documentsURL
    }
    
    private func fileInDocumentsDirectory(filename: String) -> String {
        let fileURL = getDocumentsURL().appendingPathComponent(filename)
        return fileURL!.path
    }
    
}

// MARK: Repository

extension TweetController: TweetTimeStampRepository {
    
    func getTimeStamp(from: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: from)
    }
    
    func getHeaderTimeStamp(from: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
        return formatter.string(from: from)
    }
    
}

// MARK: - UICollectionViewDataSource

extension TweetController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return replyTweet.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TweetCell
        cell.delegate = self
        let count = replyTweet.count
        let replyIndex = tweets.replyTweet[indexPath.row]
        let userFirstIndex = users.first(where: { $0.id == replyIndex.userId})
        cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
        if indexPath.row < count {
            cell.captionLabel.text = replyIndex.replyCaption
            cell.infoLabel.attributedText = getTitle(for: indexPath.row)
        }
        if replyIndex.didLike == false {
            cell.likeButton.tintColor = .lightGray
            cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
        } else {
            cell.likeButton.tintColor = .red
            cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
        }
        cell.imageURLs = replyIndex.imageURLs
        cell.configure()
        return cell
    }

}

// MARK: - UICollectionViewDelegate

extension TweetController {
    override func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(ofKind: kind, withReuseIdentifier: headeerIdentifier, for: indexPath) as! TweetHeader
        header.delegate = self
        let userFirstIndex = users.first(where: { $0.id == tweets.userId})
        header.captionLabel.text = tweets.caption
        header.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
        header.fullnameLabel.text = userFirstIndex!.fullname
        header.usernameLabel.text = "@" + userFirstIndex!.username
        let dateText = NSAttributedString(string: "・\(getHeaderTimeStamp(from: tweets.timestamp))", attributes: [.font: UIFont.systemFont(ofSize: 14), .foregroundColor: UIColor.lightGray])
        header.dateLabel.attributedText = dateText
        if tweets.didLike == false {
            header.likeButton.tintColor = .lightGray
            header.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
        } else {
            header.likeButton.tintColor = .red
            header.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
        }
        header.imageURLs = tweets.imageURLs
        header.configure()
        return header
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension TweetController: UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, referenceSizeForHeaderInSection section: Int) -> CGSize {
        let height = calcSize(width: view.frame.width, text: tweets.caption).height
        let imageContainerHeight: CGFloat = tweets.imageURLs.isEmpty ? 0 : 160
        return CGSize(width: view.frame.width, height: height + 170 + imageContainerHeight)
    }

    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let replyTweetIndex = replyTweet[indexPath.row]
        let height = calcSize(width: view.frame.width, text: replyTweetIndex.replyCaption).height
        let imageContainerHeight: CGFloat = replyTweetIndex.imageURLs.isEmpty ? 0 : 160
        return CGSize(width: view.frame.width, height: height + 100 + imageContainerHeight)
    }

}

// MARK: - TweetHeaderDelegate

extension TweetController: TweetHeaderDelegate {
    
    func handleProfileImageTapped(_ header: TweetHeader) {
        let controller = ProfileController(userId: currentUser.user!.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func handleReplyTapped(_ header: TweetHeader) {
        let controller = UploadTweetController(config: .reply(tweets))
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func handleRetweetTapped(_ cell: TweetHeader) {
        let tweet = tweets
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
        let formatString = formatter.string(from: Date())
        try! realm.write {
            tweet.timestamp = formatter.date(from: formatString)!
        }
        collectionView.reloadData()
    }
    
    func handleLikeTapped(_ header: TweetHeader) {
        try! realm.write {
            tweets.didLike.toggle()
            if tweets.didLike == false {
                header.likeButton.tintColor = .lightGray
                header.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                tweets.likes -= 1
                realm.add(tweets, update: .all)
            } else {
                header.likeButton.tintColor = .red
                header.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                tweets.likes += 1
                realm.add(tweets, update: .all)
            }
        }
    }
    
    func handleShareTapped(_ header: TweetHeader) {
        let controller = UIActivityViewController(activityItems: [tweets.caption], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
    }
        
}

// MARK: - TweetCellDelegate

extension TweetController: TweetCellDelegate {
    
    func handleProfileImageTapped(_ cell: TweetCell) {
        let controller = ProfileController(userId: currentUser.user!.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func handleReplyTapped(_ cell: TweetCell) {
        let controller = UploadTweetController(config: .reply(tweets))
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func handleRetweetTapped(_ cell: TweetCell) {
        let indexPath = collectionView.indexPath(for: cell)
        let tweetReplyIndex = replyTweet[indexPath!.row]
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
        let formatString = formatter.string(from: Date())
        try! realm.write {
            tweetReplyIndex.replyTimeStamp = formatter.date(from: formatString)!
        }
        self.replyTweet = replyTweet.sorted(by: { $0.replyTimeStamp > $1.replyTimeStamp })
        collectionView.reloadData()
    }
    
    func handleLikeTapped(_ cell: TweetCell) {
        let indexPath = self.collectionView.indexPath(for: cell)
        let tweetReplyIndex = replyTweet[indexPath!.row]
        try! realm.write {
            tweetReplyIndex.didLike.toggle()
            if tweetReplyIndex.didLike == false {
                cell.likeButton.tintColor = .lightGray
                cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
                tweetReplyIndex.likes -= 1
                realm.add(tweetReplyIndex, update: .all)
            } else {
                cell.likeButton.tintColor = .red
                cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
                tweetReplyIndex.likes += 1
                realm.add(tweetReplyIndex, update: .all)
            }
        }
    }
    
    func handleShareTapped(_ cell: TweetCell) {
        let indexPath = self.collectionView.indexPath(for: cell)
        let tweetReplyIndex = replyTweet[indexPath!.row]
        let controller = UIActivityViewController(activityItems: [tweetReplyIndex.replyCaption], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
    }
    
    func deleteActionSheet(_ cell: TweetCell) {
        let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { [self] (action: UIAlertAction!) -> Void in
            let indexPath = self.collectionView.indexPath(for: cell)
            let tweetReplyIndex = self.replyTweet[indexPath!.row]
            cell.imageURLs.enumerated().forEach { index,image in
                let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                try? FileManager.default.removeItem(atPath: fileURL)
            }
            try! realm.write {
                realm.delete(tweetReplyIndex)
                replyTweet.remove(at: indexPath!.row)
            }
            self.collectionView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
        alert.pruneNegativeWidthConstraints()
        self.present(alert, animated: true, completion: nil)
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

extension TweetController: ZoomAnimatorDelegate {
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

extension TweetController: PhotoPageContainerViewControllerDelegate {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int) {
    }
}

