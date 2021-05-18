
import UIKit
import RealmSwift
import ActiveLabel

protocol TweetCellDelegate: AnyObject {
    func handleProfileImageTapped(_ cell: TweetCell)
    func handleReplyTapped(_ cell: TweetCell)
    func handleRetweetTapped(_ cell: TweetCell)
    func handleLikeTapped(_ cell: TweetCell)
    func handleShareTapped(_ cell: TweetCell)
    func deleteActionSheet(_ cell: TweetCell)
    func selectedImageView(_ imageView: UIImageView, tag: Int, imageURLs: List<CellImageURL>)
}

private let realm = try! Realm()
private let userObject = Array(realm.objects(User.self))
private let tweetObject = Array(realm.objects(Tweet.self))

class TweetCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    let currentUser = CurrentUser.shared
     
    var tweets: Tweet = Tweet()
    var replyTweets: ReplyTweet = ReplyTweet()
    
    weak var delegate: TweetCellDelegate?
    
    lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.image = UIImage(named: "placeholderImg")
        iv.clipsToBounds = true
        iv.setDimensions(width: 48, height: 48)
        iv.layer.cornerRadius = 48 / 2
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTapped))
        iv.addGestureRecognizer(tap)
        iv.isUserInteractionEnabled = true
        return iv
    }()
    
    let replyLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.mentionColor = .twitterBlue
        return label
    }()
    
    let captionLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.lineBreakMode = .byWordWrapping
        label.numberOfLines = 0
        label.mentionColor = .twitterBlue
        label.hashtagColor = .twitterBlue
        return label
    }()
    
    lazy var commentButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "outline_mode_comment_black_24pt_1x"), for: .normal)
        button.tintColor = .darkGray
        button.setDimensions(width: 20, height: 20)
        button.addTarget(self, action: #selector(handleCommentTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var retweetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "outline_autorenew_black_24pt_1x"), for: .normal)
        button.tintColor = .darkGray
        button.setDimensions(width: 20, height: 20)
        button.addTarget(self, action: #selector(handleRetweetTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var likeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "like_unselected"), for: .normal)
        button.tintColor = .lightGray
        button.setDimensions(width: 20, height: 20)
        button.addTarget(self, action: #selector(handleLikeTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "outline_share_black_24pt_1x"), for: .normal)
        button.tintColor = .darkGray
        button.setDimensions(width: 20, height: 20)
        button.addTarget(self, action: #selector(handleShareTapped), for: .touchUpInside)
        return button
    }()
    
    lazy var optionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "baseline_keyboard_arrow_down_black_24pt_1x-1"), for: .normal)
        button.tintColor = .lightGray
        button.addTarget(self, action: #selector(showActionSheet), for: .touchUpInside)
        return button
    }()
    
    let infoLabel = UILabel()
    
    var imageURLs = List<CellImageURL>()
     
    var imageContainer = UIStackView()
    
    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
        backgroundColor = UIColor(named: "Mode")
        
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
     
     
     override func prepareForReuse() {
         super.prepareForReuse()
         tweets = Tweet()
         replyTweets = ReplyTweet()
         captionLabel.text = ""
         replyLabel.text = ""
         infoLabel.attributedText = nil
         profileImageView.image = nil
         imageURLs = List<CellImageURL>()
         imageContainer.removeFromSuperview()
     }
    
    // MARK: - Selecter
    
    @objc private func handleProfileImageTapped(){
        delegate?.handleProfileImageTapped(self)
    }
    
    @objc private func handleRetweetTapped(){
        delegate?.handleRetweetTapped(self)
    }
    
    @objc private func handleCommentTapped(){
        delegate?.handleReplyTapped(self)
    }
    
    @objc private func handleLikeTapped(){
        delegate?.handleLikeTapped(self)
    }
    
    @objc private func handleShareTapped(){
        delegate?.handleShareTapped(self)
    }
    
    @objc private func showActionSheet(){
        delegate?.deleteActionSheet(self)
    }
    
    // MARK: - UI
     
    func configure(){
        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 8, paddingLeft: 8)
        let stack = UIStackView(arrangedSubviews: [infoLabel, captionLabel])
        stack.axis = .vertical
        stack.spacing = 8
        stack.distribution = .fillProportionally
        addSubview(stack)
        stack.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 12, paddingRight: 12)
        infoLabel.font = UIFont.systemFont(ofSize: 14)
        let actionStack = UIStackView(arrangedSubviews: [commentButton, retweetButton,likeButton, shareButton])
        actionStack.axis = .horizontal
        actionStack.spacing = 72
        addSubview(actionStack)
        actionStack.centerX(inView: self)
        if !imageURLs.isEmpty {
            let vstack1 = UIStackView()
            vstack1.axis = .vertical
            vstack1.spacing = 2
            vstack1.distribution = .fillEqually
            vstack1.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
            let vstack2 = UIStackView()
            vstack2.axis = .vertical
            vstack2.spacing = 2
            vstack2.distribution = .fillEqually
            vstack2.isHidden = imageURLs.count == 1
            vstack2.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
            imageContainer = UIStackView(arrangedSubviews: [vstack1, vstack2])
            imageContainer.axis = .horizontal
            imageContainer.spacing = 2
            imageContainer.distribution = .fillEqually
            addSubview(imageContainer)
            imageContainer.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor).isActive = true
            imageContainer.topAnchor.constraint(equalTo: captionLabel.bottomAnchor).isActive = true
            imageContainer.anchor(top: captionLabel.bottomAnchor, left: captionLabel.leftAnchor, bottom: actionStack.topAnchor, right: self.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 8, paddingRight: 8, height: 160)
            imageContainer.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
            actionStack.anchor(top: imageContainer.bottomAnchor,bottom: bottomAnchor, paddingTop: 8, paddingBottom: 8)
            imageURLs.enumerated().forEach { index, image in
                let path = fileInDocumentsDirectory(filename: image.imageURL)
                let imageView = UIImageView()
                imageView.isUserInteractionEnabled = true
                imageView.image = UIImage(contentsOfFile: path)
                imageView.tag = index
                if index % 2 == 0 {
                    vstack1.addArrangedSubview(imageView)
                } else {
                    vstack2.addArrangedSubview(imageView)
                }
                imageView.addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(imageViewTappedGesture(_:))))
            }
        } else {
            actionStack.anchor(top: stack.bottomAnchor,bottom: bottomAnchor, paddingTop: 8, paddingBottom: 8)
        }
        let underlineView = UIView()
        underlineView.backgroundColor = .systemGroupedBackground
        addSubview(underlineView)
        underlineView.anchor(left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, height: 1)
        addSubview(optionButton)
        optionButton.anchor(top: topAnchor, right: stack.rightAnchor, paddingTop: 8, paddingRight: 8)
    }
    
    private func createButton(withImageName imageName: String) -> UIButton {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: imageName), for: .normal)
        button.tintColor = .darkGray
        button.setDimensions(width: 20, height: 20)
        return button
    }
    
    @objc func imageViewTappedGesture(_ sender: UITapGestureRecognizer){
        let view = sender.view
        let tag = (sender.view?.tag)!
        delegate?.selectedImageView(view! as! UIImageView, tag: tag, imageURLs: imageURLs)
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
    
}
