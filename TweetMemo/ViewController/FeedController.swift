
import UIKit
import RealmSwift
import ActiveLabel

private let realm = try! Realm()

class FeedController: UICollectionViewController{
    
    //MARK: - Properties
    
    var notificationtoken: NotificationToken?
    
    private let currentUser = CurrentUser.shared
    private var users = Array(realm.objects(User.self))
    
    private let reuseIdentifier = "TweetCell"
    private let headeerIdentifier = "TweetHeader"
    
    private var profileImage: UIImage?
    private var viewControllers: [UIViewController] = []

    var userId: Int = 0
    
    private var tweets: [Tweet] = [Tweet]() {
        didSet { collectionView.reloadData() }
    }
    
    private let actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.tintColor = .white
        button.backgroundColor = .twitterBlue
        button.setImage(UIImage(named: "baseline_playlist_add_white_36pt_1x"), for: .normal)
        button.addTarget(self, action: #selector(actionButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private var selectedImageView = UIImageView()
    
    private var pageViewController: UIPageViewController {
        return self.children[0] as! UIPageViewController
    }
    
    private var currentViewController: PhotoZoomViewController {
        return self.pageViewController.viewControllers![0] as! PhotoZoomViewController
    }
    
    public var currentLeftSafeAreaInset  : CGFloat = 0.0
    public var currentRightSafeAreaInset : CGFloat = 0.0

    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        fetchTweets()
        collectionView.backgroundColor = UIColor(named: "Mode")
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11, *) {
            self.currentLeftSafeAreaInset = view.safeAreaInsets.left
            self.currentRightSafeAreaInset = view.safeAreaInsets.right
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.backgroundColor = .white
        navigationController?.navigationBar.prefersLargeTitles = false
        navigationController?.setNavigationBarHidden(false, animated: false)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(named: "Mode")
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        fetchTweets()
        configureUI()
        collectionView.backgroundColor = UIColor(named: "Mode")
        collectionView.reloadData()
    }
    
    // MARK: - Selectors
    
    @objc private func handleRefresh(){
        fetchTweets()
    }
    
    @objc private func handleProfileImageTap() {
        let userFirstIndex = users.first(where: { $0.id == currentUser.user?.id})
        let controller = ProfileController(userId: userFirstIndex!.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    @objc private func actionButtonTapped(){
        let controller = UploadTweetController(config: .tweet)
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    //MARK: - UI
    
    private func configureUI(){
        view.backgroundColor = .white
        view.addSubview(actionButton)
        actionButton.anchor(bottom: view.safeAreaLayoutGuide.bottomAnchor, right: view.rightAnchor, paddingBottom: 64, paddingRight: 16, width: 56, height: 56)
        actionButton.layer.cornerRadius = 56 / 2
        collectionView.register(TweetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.backgroundColor = UIColor(named: "Mode")
        configureLeftBarButton()
    }
    
    private func configureLeftBarButton(){
        let user = realm.objects(User.self)
        user.forEach { (user) in
            if user.id == currentUser.user!.id {
                userId = user.id
                let profileImageView = UIImageView()
                if currentUser.user!.profileImage == nil {
                    try! realm.write {
                        let userFirstIndex = users.first(where: { $0.id == currentUser.user?.id})
                        let image = UIImage(named: "placeholderImg")?.toPNGData()
                        userFirstIndex!.profileImage = image
                        currentUser.user?.profileImage = image
                        realm.add(userFirstIndex!, update: .all)
                    }
                } else {
                    guard let image = UIImage(data: currentUser.user!.profileImage!) else { return }
                    profileImageView.image = image
                }
                
                guard let image = UIImage(data: currentUser.user!.profileImage!) else { return }
                profileImageView.image = image
                profileImageView.setDimensions(width: 32, height: 32)
                profileImageView.layer.cornerRadius = 32 / 2
                profileImageView.layer.masksToBounds = true
                profileImageView.isUserInteractionEnabled = true

                let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTap))
                profileImageView.addGestureRecognizer(tap)

                navigationController?.setNavigationBarHidden(false, animated: false)
                navigationItem.leftBarButtonItem = UIBarButtonItem(customView: profileImageView)
                navigationController?.navigationBar.barTintColor = .white

                let appearance = UINavigationBarAppearance()
                appearance.backgroundColor = UIColor(named: "Mode")
                navigationItem.largeTitleDisplayMode = .never
                navigationController?.navigationBar.standardAppearance = appearance
            }
        }
        
    }
    
    //MARK: - Helpers
    
    private func fetchTweets(){
        tweets = Array(realm.objects(Tweet.self))
            .filter {
                currentUser.user!.followUserList.firstIndex(of: $0.userId) != nil || $0.userId == currentUser.user!.id
//            }
//                    let bool = currentUser.user.followUserList.index(of: $0.userId) != nil
//                    print(currentUser.user.followUserList, $0.userId, bool)
//                    return bool
            }
            .sorted(by: { $0.timestamp > $1.timestamp })
        collectionView.reloadData()
    }
    
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
    
    private func getFrameFromImageView(for selectedImage: UIImageView) -> CGRect {
        return selectedImageView.frame
    }
    
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

extension FeedController: TimeStampRepository {
    
    func getTimeStamp(from: Date) -> String{
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd"
        return formatter.string(from: from)
    }
    
}

// MARK: - UICollectionViewDelegate/DataSource

extension FeedController {

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return tweets.count
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! TweetCell
        cell.delegate = self
        let tweetIndex = tweets[indexPath.row]
        let userFirstIndex = users.first(where: { $0.id == tweetIndex.userId})
        cell.tweets = tweetIndex
        cell.captionLabel.text = tweetIndex.caption
        cell.infoLabel.attributedText = getTitle(for: indexPath.row)
        cell.profileImageView.image = UIImage(data: userFirstIndex!.profileImage!)
        if tweetIndex.didLike == false {
            cell.likeButton.tintColor = .lightGray
            cell.likeButton.setImage(UIImage(named: "like_unselected"), for: .normal)
        } else {
            cell.likeButton.tintColor = .red
            cell.likeButton.setImage(UIImage(named: "baseline_favorite_black_24pt_1x"), for: .normal)
        }
        cell.imageURLs = tweetIndex.imageURLs
        tweetIndex.replyTweet.forEach { replys in
            
        }
        cell.configure()
        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let tweetIndex = tweets[indexPath.row]
        let userFirstIndex = users.first(where: { $0.id == tweetIndex.userId})
        let controller = TweetController(tweets: tweetIndex, userId: userFirstIndex!.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
}

// MARK: - UICollectionViewDelegateFlowLayout

extension FeedController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let tweetIndex = tweets[indexPath.row]
        let height = calcSize(width: view.frame.width, text: tweetIndex.caption).height
        let imageContainerHeight: CGFloat = tweetIndex.imageURLs.isEmpty ? 0 : 160
        return CGSize(width: view.frame.width, height: height + 80 + imageContainerHeight)
    }
    
}

// MARK: - TweetCellDelegate

extension FeedController: TweetCellDelegate {
    
    func handleLikeTapped(_ cell: TweetCell) {
        let indexPath = collectionView.indexPath(for: cell)
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
    }
    
    func handleReplyTapped(_ cell: TweetCell) {
        let tweet = cell.tweets
        let controller = UploadTweetController(config: .reply(tweet))
        let nav = UINavigationController(rootViewController: controller)
        nav.modalPresentationStyle = .fullScreen
        present(nav, animated: true, completion: nil)
    }
    
    func handleRetweetTapped(_ cell: TweetCell) {
        let indexPath = collectionView.indexPath(for: cell)
        let tweetIndex = tweets[indexPath!.row]
        let formatter: DateFormatter = DateFormatter()
        formatter.dateFormat = "yyyy/MM/dd ・h:mm a "
        let formatString = formatter.string(from: Date())
        try! realm.write {
            tweetIndex.timestamp = formatter.date(from: formatString)!
        }
        fetchTweets()
        collectionView.reloadData()
    }
    
    func handleShareTapped(_ cell: TweetCell) {
        let indexPath = collectionView.indexPath(for: cell)
        let tweetIndex = tweets[indexPath!.row]
        let controller = UIActivityViewController(activityItems: [tweetIndex.caption], applicationActivities: nil)
        self.present(controller, animated: true, completion: nil)
    }
    
    func handleProfileImageTapped(_ cell: TweetCell) {
        navigationController?.setNavigationBarHidden(false, animated: false)
        let controller = ProfileController(userId: currentUser.user!.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
    func deleteActionSheet(_ cell: TweetCell) {
        let alert = UIAlertController(title: "", message: "ツイートを本当に削除しますか？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "削除する", style: .destructive, handler: { [self] (action: UIAlertAction!) -> Void in
            let indexPath = collectionView.indexPath(for: cell)
            let tweetsIndex = tweets[indexPath!.row]
            cell.imageURLs.enumerated().forEach { index,image in
                let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                try? FileManager.default.removeItem(atPath: fileURL)
            }
            tweetsIndex.replyTweet.forEach { replys in
                replys.imageURLs.enumerated().forEach { index,image in
                    let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                    try? FileManager.default.removeItem(atPath: fileURL)
                }
            }
            try! realm.write {
                realm.delete(tweetsIndex.replyTweet)
                realm.delete(tweetsIndex)
                tweets.remove(at: indexPath!.row)
            }
            collectionView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
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

extension FeedController: ZoomAnimatorDelegate {

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

extension FeedController: PhotoPageContainerViewControllerDelegate {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int) {
    }
}
