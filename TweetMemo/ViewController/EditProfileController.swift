
import UIKit
import RealmSwift

private let realm = try! Realm()

protocol EditProfileControllerDelegate: AnyObject {
    func controller(_ controller: EditProfileController, wantsToUpdate user: User)
    func handleLogout()
}

enum EditProfileOptions: Int, CaseIterable {
    case fullname
    case username
    case profile

    var description: String {
        switch self {
        case .username: return "Username"
        case .fullname: return "FullName"
        case .profile: return "Profile"
        }
    }
}

final class EditProfileController: UITableViewController {
    
    // MARK: - Properties
    
    let currentUser = CurrentUser.shared
    private var users = Array(realm.objects(User.self))
    
    private let reuseIdentifier = "EditProfileCell"
    
    private lazy var headerView = EditProfileHeader()
    private let footerView = EditProfileFooter()
    private let imagePicker = UIImagePickerController()
    private var userInfoChange = false
    
    
    private var imageChanged: Bool {
        return selectedImage != nil
    }
    
    weak var delegate: EditProfileControllerDelegate?
    
    private var selectedImage: UIImage? {
        didSet {
            headerView.profileImageView.image = selectedImage
        }
    }
    
    // MARK: - Lifecycle
    
    init(){
        super.init(style: .plain)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigationBar()
        configureUI()
        configureImagePicker()
        navigationItem.rightBarButtonItem?.isEnabled = false
    }
    
    // MARK: - Selectors
    
    @objc private func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func handleDone(){
        view.endEditing(true)
        dismiss(animated: true, completion: nil)
    }
    
    @objc private func textFieldEditingChanged(sender: UITextField) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
    
    // MARK: - UI
    
    private func configureNavigationBar(){
        navigationController?.navigationBar.barTintColor = .twitterBlue
        navigationController?.navigationBar.barStyle = .black
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "Edit Profile"
        navigationItem.leftBarButtonItem = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(handleCancel))
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(handleDone))
    }
    
    private func configureUI(){
        tableView.tableHeaderView = headerView
        tableView.tableFooterView = UIView(frame: .zero)
        headerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 180)
        headerView.delegate = self
        headerView.profileImageView.image = UIImage(data: currentUser.user!.profileImage!)
        footerView.frame = CGRect(x: 0, y: 0, width: view.frame.width, height: 100)
        tableView.tableFooterView = footerView
        footerView.delegate = self
        view.addSubview(headerView)
        tableView.rowHeight = 100
        tableView.register(EditProfileCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    private func configureImagePicker(){
        imagePicker.delegate = self
        imagePicker.allowsEditing = true
    }
    
}

// MARK - UITableViewDataSource

extension EditProfileController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return EditProfileOptions.allCases.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! EditProfileCell
        cell.delegate = self
        cell.profileTextView.delegate = self
        guard let option = EditProfileOptions(rawValue: indexPath.row) else { return cell}
        cell.configure(option: option)
        return cell
    }

}

 // MARK - UITableViewDelegate

extension EditProfileController {

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        guard let option = EditProfileOptions(rawValue: indexPath.row) else { return 0 }
        return option == .profile ? 100 : 48
    }

}

// MARK - EditProfileHeaderDelegate

extension EditProfileController: EditProfileHeaderDelegate {
    func didTapChangeProfilePhoto(){
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK - UIImagePickerControllerDelegate

extension EditProfileController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[.editedImage] as? UIImage else { return }
        selectedImage = image
        let userFirstIndex = users.first(where: { $0.id == currentUser.user?.id})
        try! realm.write {
            let pngData = selectedImage?.toPNGData()
            let jpegData = selectedImage?.toJPEGData()
            currentUser.user!.profileImage = pngData as Data? ?? jpegData as Data?
            userFirstIndex?.profileImage = pngData as Data? ?? jpegData as Data?
        }
        dismiss(animated: true, completion: nil)
    }
    
}


// MARK - EditProfileCellDelegate

extension EditProfileController: EditProfileCellDelegate {
    
    func updateUserInfo(_ cell: EditProfileCell, option: EditProfileOptions) {
        cell.infoTextField.addTarget(self,
                                     action: #selector(textFieldEditingChanged(sender:)),
                                     for: .editingChanged)
        let userFirstIndex = users.first(where: { $0.id == currentUser.user?.id})
        try! realm.write {
            switch option {
            case .fullname:
                guard let fullname = cell.infoTextField.text else { return }
                currentUser.user?.fullname = fullname
                userFirstIndex?.fullname = fullname
                cell.commonInit()
            case .username:
                guard let username = cell.infoTextField.text else { return }
                currentUser.user?.username = username
                userFirstIndex?.username = username
                cell.commonInit()
            case .profile:
                guard let profile = cell.profileTextView.text else { return }
                currentUser.user?.profileText = profile
                userFirstIndex?.profileText = profile
                cell.commonInit()
            }
        }
    }
    
}
    
// MARK - EditProfileFooterDelegate

extension EditProfileController: EditProfileFooterDelegate {
    
    func handleLogout() {
        let alert = UIAlertController(title: nil, message: "ログアウトしますか？", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Log Out", style: .destructive, handler: { [self] _ in
            currentUser.signout()
            let controller = UserListController()
            self.navigationController?.pushViewController(controller, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(alert, animated: true, completion: nil)
    }
    
}

// MARK - UITextViewDelegate

extension EditProfileController: UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {
        navigationItem.rightBarButtonItem?.isEnabled = true
    }
}
