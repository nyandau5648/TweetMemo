
import UIKit
import ActiveLabel
import RealmSwift

private let realm = try! Realm()
private let userObject = realm.objects(User.self)

protocol TweetHeaderDelegate: AnyObject {
    func handleProfileImageTapped(_ header: TweetHeader)
    func handleReplyTapped(_ header: TweetHeader)
    func handleRetweetTapped(_ cell: TweetHeader)
    func handleLikeTapped(_ header: TweetHeader)
    func handleShareTapped(_ header: TweetHeader)
    func selectedImageView(_ imageView: UIImageView, tag: Int, imageURLs: List<CellImageURL>)
}

class TweetHeader: UICollectionReusableView {

    // MARK: - Properties
    
    let currentUser = CurrentUser.shared
    
    var tweets: Tweet = Tweet()
    
    var replyTweets: ReplyTweet = ReplyTweet()
    
    weak var delegate: TweetHeaderDelegate?

    lazy var profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.setDimensions(width: 48, height: 48)
        iv.layer.cornerRadius = 48 / 2
        iv.backgroundColor = .twitterBlue
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleProfileImageTapped))
        iv.addGestureRecognizer(tap)
        iv.isUserInteractionEnabled = true
        return iv
    }()

    let fullnameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        return label
    }()

    let usernameLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .lightGray
        return label
    }()

    let captionLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.numberOfLines = 0
        return label
    }()

    let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .lightGray
        label.textAlignment = .left
        return label
    }()
    
    let replyLabel: ActiveLabel = {
        let label = ActiveLabel()
        label.textColor = .lightGray
        label.font = UIFont.systemFont(ofSize: 12)
        label.mentionColor = .twitterBlue
        return label
    }()
    
    var imageURLs = List<CellImageURL>()
    
    var imageContainer = UIStackView()

    lazy var statsView: UIView = {
        let view = UIView()
        
        let divider1 = UIView()
        divider1.backgroundColor = .systemGroupedBackground
        view.addSubview(divider1)
        divider1.anchor(top: view.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingLeft: 8, height: 1.0)
        
        let stack = UIStackView(arrangedSubviews: [commentButton, retweetButton, likeButton, shareButton])
        stack.axis = .horizontal
        stack.spacing = 72
        
        view.addSubview(stack)
        stack.centerY(inView: view)
        stack.anchor(left: view.leftAnchor, paddingLeft: 60)
        
        let divider2 = UIView()
        divider2.backgroundColor = .systemGroupedBackground
        view.addSubview(divider2)
        divider2.anchor(left: view.leftAnchor, bottom: view.bottomAnchor, right: view.rightAnchor, paddingLeft: 8, height: 1.0)
        
        return view
    }()
    

    lazy var commentButton: UIButton = {
        let button = createButton(withImageName: "outline_mode_comment_black_24pt_1x")
        button.addTarget(self, action: #selector(handleReplyTapped), for: .touchUpInside)
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
        let button = createButton(withImageName: "like_unselected")
        button.addTarget(self, action: #selector(handleLikeTapped), for: .touchUpInside)
        return button
    }()

    lazy var shareButton: UIButton = {
        let button = createButton(withImageName: "outline_share_black_24pt_1x")
        button.addTarget(self, action: #selector(handleShareTapped), for: .touchUpInside)
        return button
    }()

    // MARK: - Lifecycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageContainer.removeFromSuperview()
    }

    // MARK: - Selector

    @objc private func handleProfileImageTapped(){
        delegate?.handleProfileImageTapped(self)
    }

    @objc private func handleReplyTapped(){
        delegate?.handleReplyTapped(self)
    }
    
    @objc private func handleRetweetTapped(){
        delegate?.handleRetweetTapped(self)
    }
    
    @objc private func handleLikeTapped(){
        delegate?.handleLikeTapped(self)
    }

    @objc private func handleShareTapped(){
        delegate?.handleShareTapped(self)
    }
    
    func imageUrls(imageUrls: List<CellImageURL>){
        self.imageURLs = imageUrls
    }

    // MARK: - UI

    func configure(){
        backgroundColor = UIColor(named: "Mode")

        addSubview(profileImageView)
        profileImageView.anchor(top: topAnchor, left: leftAnchor, paddingTop: 16, paddingLeft: 16)
        
        let labelStack = UIStackView(arrangedSubviews: [fullnameLabel, usernameLabel])
        labelStack.axis = .horizontal
        labelStack.spacing = 3
        addSubview(labelStack)
        labelStack.anchor(top: profileImageView.topAnchor, left: profileImageView.rightAnchor, paddingTop: 4, paddingLeft: 16)

        addSubview(captionLabel)
        addSubview(dateLabel)
        
        if imageURLs.isEmpty == false {
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
            captionLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, bottom: imageContainer.topAnchor,right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingBottom: 0,paddingRight: 8)
            imageContainer.leadingAnchor.constraint(equalTo: captionLabel.leadingAnchor).isActive = true
            imageContainer.topAnchor.constraint(equalTo: captionLabel.bottomAnchor).isActive = true
            imageContainer.anchor(top: captionLabel.bottomAnchor, left: captionLabel.leftAnchor, right: captionLabel.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingRight: 0, height: 160)
            imageContainer.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
            
            dateLabel.anchor(top: imageContainer.bottomAnchor, left: leftAnchor, paddingTop: 8, paddingLeft: 0)
            
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
            captionLabel.anchor(top: profileImageView.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 8, paddingLeft: 8, paddingRight: 8)
            dateLabel.anchor(top: captionLabel.bottomAnchor, left: leftAnchor, paddingTop: 8, paddingLeft:  0)
        }
        addSubview(statsView)
        statsView.anchor(top: dateLabel.bottomAnchor, left: leftAnchor, right: rightAnchor, paddingTop: 12, height: 40)
        
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
