
import Foundation
import UIKit
import RealmSwift

protocol CreateNewIDRepository {
    func newId<T: Object>(model: T) -> Int?
    func replyNewId<T: Object>(model: T) -> Int?
}

enum UploadTweetConfiguration {
    case tweet
    case reply(Tweet)
}

private let realm = try! Realm()

class UploadTweetController: UIViewController {
    
    // MARK: - Properties
    
    private let currentUser = CurrentUser.shared
    
    private let reuseIdentifier = "UploadTweetCell"
    
    private var tweets: [Tweet] = [Tweet]()
    private var replyTweets: [ReplyTweet] = [ReplyTweet]()
    private let config: UploadTweetConfiguration
    
    let users = Array(realm.objects(User.self))
    
    private let actionButtonTitle: String
    private let placeholderText: String
    private let shouldShowReplyLabel: Bool
    private var replyText: String?
    
    private var textViewHeight: NSLayoutConstraint!
    
    private let imagePicker = UIImagePickerController()
    private var selectedImage = [UIImage]()
    
    private var collectionView: UICollectionView!
    
    private lazy var actionButton: UIButton = {
        let button = UIButton(type: .system)
        button.backgroundColor = .twitterBlue
        button.setTitle("Tweet", for: .normal)
        button.titleLabel?.textAlignment = .center
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.frame = CGRect(x: 0, y: 0, width: 64, height: 32)
        button.layer.cornerRadius = 32 / 2
        button.addTarget(self, action: #selector(handleUploadTweet), for: .touchUpInside)
        return button
    }()
    
    private let cameraButton = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraButtonTapped))
    
    private let profileImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.setDimensions(width: 48, height: 48)
        iv.layer.cornerRadius = 48 / 2
        iv.image = UIImage(named: "placeholderImg")
        return iv
    }()
    
    private let captionTextView = UITextView()
    
    private let placeholderLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .darkGray
        label.text = "What happend?"
        return label
    }()
    
    // MARK: - Lifecycle
    
    init(config: UploadTweetConfiguration){
        self.config = config
        switch config {
        case .tweet:
            actionButtonTitle = "ツイート"
            placeholderText = "今何してる？"
            shouldShowReplyLabel = false
        case .reply(let tweet):
            actionButtonTitle = "返信"
            placeholderText = "返信してみよう！"
            shouldShowReplyLabel = true
            replyText = "Replying to @\(tweet.caption)"
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Mode")
        captionTextView.delegate = self
        captionTextView.backgroundColor = UIColor(named: "Mode")
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: UICollectionViewFlowLayout())
        collectionView.reloadData()
        collectionView.backgroundColor = UIColor(named: "Mode")
        configureUI()
        commonInit(button: true)
        configureImagePicker()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textViewDidChange(notification:)),
                                               name: UITextView.textDidChangeNotification, object: captionTextView)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextInputChange), name: UITextView.textDidChangeNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        collectionView.reloadData()
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Selecters
    
    @objc private func handleTextInputChange(){
        if captionTextView.text.isEmpty {
            placeholderLabel.isHidden = false
        } else {
            placeholderLabel.isHidden = true
        }
    }
    
    @objc private func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleUploadTweet(){
        view.endEditing(true)
        let saveTweet = Tweet()
        let saveReplyTweet = ReplyTweet()
        guard let caption = captionTextView.text else { return }
        uploadTweet(caption: caption, type: config) { [self] in
            switch config {
            case .tweet:
                saveTweet.caption = caption
                saveTweet.tweetId = newId(model: saveTweet)!
                saveTweet.userId = currentUser.user!.id
                try! realm.write {
                    realm.add(saveTweet)
                    tweets.append(saveTweet)
                    selectedImage.forEach {
                        let fileName = "\(NSUUID().uuidString).png"
                        let path = fileInDocumentsDirectory(filename: fileName)
                        saveImageToDocuments(image: $0, path: path)
                        let cellImageURL = CellImageURL()
                        cellImageURL.imageURL = fileName
                        saveTweet.imageURLs.append(cellImageURL)
                    }
                }
            case .reply(let tweet):
                saveReplyTweet.replyCaption = caption
                saveReplyTweet.replyTweetId = replyNewId(model: saveReplyTweet)!
                saveReplyTweet.userId = currentUser.user!.id
                try! realm.write {
                    tweet.replyTweet.append(saveReplyTweet)
                    selectedImage.forEach {
                        let fileName = "\(NSUUID().uuidString).png"
                        let path = fileInDocumentsDirectory(filename: fileName)
                        saveImageToDocuments(image: $0, path: path)
                        let cellImageURL = CellImageURL()
                        cellImageURL.imageURL = fileName
                        tweet.replyTweet[saveReplyTweet.replyTweetId].imageURLs.append(cellImageURL)
                    }
                    replyTweets.append(saveReplyTweet)
                }
            }
        }
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func textViewDidChange(notification: NSNotification){
        let maxLength = 140
        let textView = notification.object as! UITextView
        if textView == captionTextView {
            textView.resolveHashTags()
            if let text = textView.text {
                var eachCharacter = [Int]()
                for i in 0..<text.count {
                    let textIndex = text.index(text.startIndex, offsetBy: i)
                    eachCharacter.append(String(text[textIndex]).lengthOfBytes(using: String.Encoding.shiftJIS))
                }
                if textView.markedTextRange == nil && text.lengthOfBytes(using: String.Encoding.shiftJIS) > maxLength {
                    var countByte = 0
                    var countCharacter = 0
                    for n in eachCharacter {
                        if countByte < maxLength - 1 {
                            countByte += n
                            countCharacter += 1
                        }
                    }
                    textView.text = text.prefix(countCharacter).description
                }
            }
        }
    }
    
    @objc private func cameraButtonTapped(){
        present(imagePicker, animated: true, completion: nil)
    }
    
    // MARK: - UI

    private func configureUI(){
        if currentUser.user!.profileImage != nil {
            profileImageView.image = UIImage(data: currentUser.user!.profileImage!)
        } else {
            profileImageView.image = UIImage(named: "placeholderImg")
        }
        configureNavigationBar()
        
        let stack = UIStackView(arrangedSubviews: [profileImageView, captionTextView])
        stack.axis = .horizontal
        stack.spacing = 12
        stack.alignment = .leading
        view.addSubview(stack)
        
        actionButton.setTitle(actionButtonTitle, for: .normal)
        placeholderLabel.text = placeholderText
        stack.anchor(top: view.safeAreaLayoutGuide.topAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 16, paddingLeft: 16, paddingRight: 16)
        
        captionTextView.font = UIFont.systemFont(ofSize: 16)
        captionTextView.isScrollEnabled = false
        textViewHeight = captionTextView.heightAnchor.constraint(equalToConstant: 30)
        textViewHeight.isActive = true
        
        view.addSubview(placeholderLabel)
        placeholderLabel.anchor(top: captionTextView.topAnchor, left: captionTextView.leftAnchor, paddingTop: 8, paddingLeft: 8)
        
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UploadTweetCell.self, forCellWithReuseIdentifier: reuseIdentifier)
        collectionView.isPagingEnabled = true
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        collectionView.collectionViewLayout = layout
        
        view.addSubview(collectionView)
        collectionView.leadingAnchor.constraint(equalTo: captionTextView.leadingAnchor).isActive = true
        collectionView.topAnchor.constraint(equalTo: captionTextView.bottomAnchor, constant: 30).isActive = true
        collectionView.anchor(top: stack.bottomAnchor,left: captionTextView.leftAnchor, right: stack.rightAnchor, paddingTop: 8, paddingLeft: 0, paddingRight: 8, height: 150)
    }
    
    private func configureNavigationBar(){
        navigationController?.navigationBar.barTintColor = .white
        navigationController?.navigationBar.isTranslucent = false
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(customView: actionButton)
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(named: "Mode")
        navigationController?.navigationBar.standardAppearance = appearance
    }
    
    // MARK: - Helper
    
    private func uploadTweet(caption: String, type: UploadTweetConfiguration, completion: @escaping() -> Void){
        completion()
    }
    
    private func commonInit(button: Bool){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)
        cameraButton.isEnabled = true
        tools.items = [cameraButton]
        captionTextView.inputAccessoryView = tools
    }
    
    private func configureImagePicker(){
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
    private func imageNewId<T: Object>(model: T) -> Int? {
        guard let key = T.primaryKey() else { return nil }
        if let last = realm.objects(T.self).sorted(byKeyPath: "imageId", ascending: true).last,
            let lastId = last[key] as? Int {
            return lastId + 1
        } else {
            return 0
        }
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
    
    private func saveImageToDocuments(image: UIImage, path: String) {
        do {
            let pngImageData = image.pngData()
            try pngImageData!.write(to: URL(fileURLWithPath: path), options: .atomic)
        } catch {
            print(error)
        }
    }
    
    private func saveImage() {
        selectedImage.forEach {
            let fileName = "\(NSUUID().uuidString).png"
            let path = fileInDocumentsDirectory(filename: fileName)
            saveImageToDocuments(image: $0, path: path)
        }
    }
    
}

// MARK: - Repository

extension UploadTweetController: CreateNewIDRepository {
    
    func newId<T: Object>(model: T) -> Int? {
        guard let key = T.primaryKey() else { return nil }
        if let last = realm.objects(T.self).sorted(byKeyPath: "tweetId", ascending: true).last,
            let lastId = last[key] as? Int {
            return lastId + 1
        } else {
            return 0
        }
    }
    
    func replyNewId<T: Object>(model: T) -> Int? {
        guard let key = T.primaryKey() else { return nil }
        if let last = realm.objects(T.self).sorted(byKeyPath: "replyTweetId", ascending: true).last,
            let lastId = last[key] as? Int {
            return lastId + 1
        } else {
            return 0
        }
    }
    
}

// MARK - UIImagePickerControllerDelegate

extension UploadTweetController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        selectedImage.append(image)
        collectionView.reloadData()
        dismiss(animated: true, completion: nil)
    }
}

extension UploadTweetController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        captionTextView.translatesAutoresizingMaskIntoConstraints = false
        let height = textView.sizeThatFits(CGSize(width: textView.frame.size.width, height: CGFloat.greatestFiniteMagnitude)).height
        textViewHeight.constant = height
    }
}

// MARK: - UICollectionViewDelegate, UICollectionViewDataSource

extension UploadTweetController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if selectedImage.count >= 4 {
            cameraButton.isEnabled = false
        } else {
            cameraButton.isEnabled = true
        }
        return selectedImage.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! UploadTweetCell
        cell.delegate = self
        cell.selectedImageView.image = selectedImage[indexPath.item]
        return cell
    }

}

// MARK: - UICollectionViewDelegateFlowLayout

extension UploadTweetController: UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 150, height: 150)
    }
    
}

// MARK: - UploadTweetCellDelegate

extension UploadTweetController: UploadTweetCellDelegate {
    
    func deleteImage(_ cell: UploadTweetCell) {
        let indexPath = collectionView.indexPath(for: cell)
        selectedImage.remove(at: indexPath!.item)
        collectionView.reloadData()
    }
    
}

// MARK: - UITextView

extension UITextView {

    func resolveHashTags() {
        let nsText = NSString(string: self.text)
        let words = nsText.components(separatedBy: CharacterSet(charactersIn: "#ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789_").inverted)
        let attrString = NSMutableAttributedString()
        attrString.setAttributedString(self.attributedText)
        for word in words {
            if word.count < 3 {
                continue
            }
            if word.hasPrefix("#") {
                let matchRange:NSRange = nsText.range(of: word as String)
                let stringifiedWord = word.dropFirst()
                if let firstChar = stringifiedWord.unicodeScalars.first, NSCharacterSet.decimalDigits.contains(firstChar) {
                } else {
                    attrString.addAttribute(NSAttributedString.Key.link, value: "hash:\(stringifiedWord)", range: matchRange)
                }
            }
        }
        self.attributedText = attrString
    }
    
}
