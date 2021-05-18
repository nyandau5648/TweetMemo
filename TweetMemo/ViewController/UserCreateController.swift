
import UIKit
import RealmSwift

class UserCreateController: UIViewController {
    
    // MARK: - Properties
    
    private let imagePicker = UIImagePickerController()
    private var profileImage: UIImage?
    
    private let plusPhotoButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(named: "plus_photo"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(handleAddProfilePhoto), for: .touchUpInside)
        return button
    }()
    
    private lazy var fullnameContainerView: UIView = {
        let image = #imageLiteral(resourceName: "ic_person_outline_white_2x")
        let view = CostomView().inputContainerView(withImage: image, textField: fullnameTextField)
        return view
    }()
    
    private lazy var usernameContainerView: UIView = {
        let image = #imageLiteral(resourceName: "ic_lock_outline_white_2x")
        let view = CostomView().inputContainerView(withImage: image, textField: usernameTextField)
        return view
    }()
    
    private let fullnameTextField: UITextField = {
        let tf = CostomView().textField(withPlaceholder: "Full Name")
        return tf
    }()
    
    private let usernameTextField: UITextField = {
        let tf = CostomView().textField(withPlaceholder: "User Name")
        return tf
    }()
    
    private let registrationButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("登録する", for: .normal)
        button.setTitleColor(.twitterBlue, for: .normal)
        button.alpha = 0.5
        button.backgroundColor = .white
        button.layer.cornerRadius = 5
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 20)
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        button.isEnabled = false
        button.addTarget(self, action: #selector(handleRegistration), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
        commonInit()
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textFieldDidChange(notification:)),
                                               name: UITextField.textDidChangeNotification, object: fullnameTextField)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(textFieldDidChange(notification:)),
                                               name: UITextField.textDidChangeNotification, object: usernameTextField)
        NotificationCenter.default.addObserver(self, selector: #selector(handleTextInputChange), name: UITextField.textDidChangeNotification, object: nil)
    }
    
    // MARK: - Selecters
    
    @objc private func handleShowLogin(){
        navigationController?.popViewController(animated: true)
    }
    
    @objc private func handleAddProfilePhoto(){
        present(imagePicker, animated: true, completion: nil)
    }
    
    @objc private func handleRegistration(){
        let user = User()
        user.fullname = fullnameTextField.text!
        user.username = usernameTextField.text!
        user.id = newId(model:user)!
        let pngData = profileImage?.toPNGData()
        let jpegData = profileImage?.toJPEGData()
        user.profileImage = pngData as Data? ?? jpegData as Data?
        let realm = try! Realm()
        try! realm.write {
            realm.add(user, update: .all)
        }
        self.navigationController?.popViewController(animated: true)
    }
    
    @objc private func closeButtonTapped(){
        view.endEditing(true)
        resignFirstResponder()
    }
    
    @objc private func textFieldDidChange(notification: NSNotification){
        let maxLength = 20
        let textField = notification.object as! UITextField
        if textField == usernameTextField {
            if let text = textField.text {
                var eachCharacter = [Int]()
                for i in 0..<text.count {
                    let textIndex = text.index(text.startIndex, offsetBy: i)
                    eachCharacter.append(String(text[textIndex]).lengthOfBytes(using: String.Encoding.shiftJIS))
                }
                if textField.markedTextRange == nil && text.lengthOfBytes(using: String.Encoding.shiftJIS) > maxLength {
                    var countByte = 0
                    var countCharacter = 0
                    for n in eachCharacter {
                        if countByte < maxLength - 1 {
                            countByte += n
                            countCharacter += 1
                        }
                    }
                    textField.text = text.prefix(countCharacter).description
                }
            }
        }
        if textField == fullnameTextField {
            if let text = textField.text {
                var eachCharacter = [Int]()
                for i in 0..<text.count {
                    let textIndex = text.index(text.startIndex, offsetBy: i)
                    eachCharacter.append(String(text[textIndex]).lengthOfBytes(using: String.Encoding.shiftJIS))
                }
                if textField.markedTextRange == nil && text.lengthOfBytes(using: String.Encoding.shiftJIS) > maxLength {
                    var countByte = 0
                    var countCharacter = 0
                    for n in eachCharacter {
                        if countByte < maxLength - 1 {
                            countByte += n
                            countCharacter += 1
                        }
                    }
                    textField.text = text.prefix(countCharacter).description
                }
            }
        }
    }
    
    @objc private func handleTextInputChange(){
        if fullnameTextField.text!.isEmpty || usernameTextField.text!.isEmpty {
            registrationButton.isEnabled = false
            registrationButton.alpha = 0.5
        } else {
            registrationButton.isEnabled = true
            registrationButton.alpha = 1.0
        }
    }
    
    // MARK: - Helpers
    
    func configureUI() {
        
        view.backgroundColor = .twitterBlue
        navigationController?.navigationBar.prefersLargeTitles = false
        
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
        
        view.addSubview(plusPhotoButton)
        plusPhotoButton.centerX(inView: view, topAnchor: view.safeAreaLayoutGuide.topAnchor, paddingTop: 32)
        plusPhotoButton.setDimensions(width: 128, height: 128)
        
        let stack = UIStackView(arrangedSubviews: [fullnameContainerView, usernameContainerView, registrationButton])
        stack.axis = .vertical
        stack.spacing = 20
        stack.distribution = .fillEqually
        
        view.addSubview(stack)
        stack.anchor(top: plusPhotoButton.bottomAnchor, left: view.leftAnchor, right: view.rightAnchor, paddingTop: 32, paddingLeft: 32, paddingRight: 32)
        
    }
    
    func newId<T: Object>(model: T) -> Int? {
        guard let key = T.primaryKey() else { return nil }
        let realm = try! Realm()
        if let last = realm.objects(T.self).sorted(byKeyPath: "id", ascending: true).last,
            let lastId = last[key] as? Int {
            return lastId + 1
        } else {
            return 0
        }
    }
    
    func commonInit(){
        let tools = UIToolbar()
        tools.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 40)
        let spacer = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil)
        let closeButton = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(closeButtonTapped))
        tools.items = [spacer, closeButton]
        usernameTextField.inputAccessoryView = tools
        fullnameTextField.inputAccessoryView = tools
    }
    
}

// MARK: - UIImagePickerControllerDelegate

extension UserCreateController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let profileImage = info[.editedImage] as? UIImage else { return }
        self.profileImage = profileImage
        plusPhotoButton.layer.cornerRadius = 128 / 2
        plusPhotoButton.layer.masksToBounds = true
        plusPhotoButton.imageView?.contentMode = .scaleAspectFill
        plusPhotoButton.imageView?.clipsToBounds = true
        plusPhotoButton.layer.borderColor = UIColor.white.cgColor
        plusPhotoButton.layer.borderWidth = 3
        self.plusPhotoButton.setImage(profileImage.withRenderingMode(.alwaysOriginal), for: .normal)
        dismiss(animated: true, completion: nil)
    }
    
}

