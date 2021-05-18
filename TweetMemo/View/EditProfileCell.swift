
import UIKit
import RealmSwift

protocol EditProfileCellDelegate: AnyObject {
    func updateUserInfo(_ cell: EditProfileCell, option: EditProfileOptions)
}

private let realm = try! Realm()
private let userObject = realm.objects(User.self)

class EditProfileCell: UITableViewCell, UITextViewDelegate {
    
    // MARK: - Properties
    
    let currentUser = CurrentUser.shared
    
    weak var delegate: EditProfileCellDelegate?
    
    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    lazy var infoTextField: UITextField = {
        let tf = UITextField()
        tf.borderStyle = .none
        tf.font = UIFont.systemFont(ofSize: 14)
        tf.textAlignment = .left
        tf.textColor = .twitterBlue
        tf.addTarget(self, action: #selector(handleUpdateUserInfo), for: .editingDidEnd)
        return tf
    }()
    
    let profileTextView: UITextView = {
        let tv = UITextView()
        tv.font = UIFont.systemFont(ofSize: 14)
        tv.textColor = .twitterBlue
        tv.text = "Profile"
        return tv
    }()
    
    var option: EditProfileOptions = .fullname

    var shouldHidePlaceholderLabel: Bool {
        return currentUser.user!.profileText != nil
    }
    
    var shouldHideTextView: Bool {
        option != .profile
    }
    
    var shouldHideTextField: Bool {
        option == .profile
    }
    
    var titleText: String {
        option.description
    }
    
    var optionValue: String? {
        switch option {
        case .fullname: return currentUser.user?.fullname
        case .username: return currentUser.user?.username
        case .profile: return currentUser.user!.profileText
        }
    }
    
    // MARK: - Lifecycle
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        commonInit()
        
        contentView.addSubview(titleLabel)
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        titleLabel.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
        titleLabel.anchor(top: topAnchor, left: leftAnchor, paddingTop: 12, paddingLeft: 16)
        
        contentView.addSubview(infoTextField)
        infoTextField.translatesAutoresizingMaskIntoConstraints = false
        infoTextField.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
        infoTextField.anchor(top: topAnchor, left: titleLabel.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 16, paddingRight: 8)
    
        contentView.addSubview(profileTextView)
        profileTextView.translatesAutoresizingMaskIntoConstraints = false
        profileTextView.contentHuggingPriority(for: NSLayoutConstraint.Axis(rawValue: 750)!)
        profileTextView.isScrollEnabled = true
        profileTextView.anchor(top: topAnchor, left: titleLabel.rightAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 4, paddingLeft: 14, paddingRight: 8)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleUpdateUserInfo), name: UITextView.textDidEndEditingNotification, object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textViewDidChange(notification:)),
                                               name: UITextView.textDidChangeNotification,
                                               object: profileTextView)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selector
    
    @objc private func handleUpdateUserInfo(){
        delegate?.updateUserInfo(self, option: option)
    }
    
    @objc private func textViewDidChange(notification: NSNotification){
        let maxLength = 100
        let textView = notification.object as! UITextView
        if textView == profileTextView {
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
    
    @objc private func closeButtonTapped(){
        endEditing(true)
        resignFirstResponder()
    }
    
    // MARK: - UI
    
    func configure(option: EditProfileOptions){
        self.option = option
        titleLabel.text = titleText
        infoTextField.text = optionValue
        profileTextView.text = optionValue
        switch option {
        case .fullname:
            profileTextView.isHidden = shouldHideTextView
        case .username:
            profileTextView.isHidden = shouldHideTextView
        case .profile:
            infoTextField.isHidden = shouldHideTextField
        }
    }
    
    func commonInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: frame.width, height: 40)
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonTapped))
        tools.items = [spacer, closeButton]
        infoTextField.inputAccessoryView = tools
        profileTextView.inputAccessoryView = tools
    }
    
}

