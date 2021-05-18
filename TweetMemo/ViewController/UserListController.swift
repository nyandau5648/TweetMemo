
import UIKit
import RealmSwift

private let realm = try! Realm()

class UserListController : UITableViewController {
    
    // MARK: - Properties
    
    private let currentUser = CurrentUser.shared
    
    private var users = Array(realm.objects(User.self))
    private let reuseIdentifier = "UserListCell"
    private var userAddButton: UIBarButtonItem!
    
    private var tweets: [Tweet] = [Tweet]()
    private var replys: [ReplyTweet] = [ReplyTweet]()
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .twitterBlue
        configureNavigationBar()
        configureUI()
        setUser()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUser()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        configureUI()
        setUser()
    }
    
    // MARK: - Selectors
    
    @objc private func handleAdd(){
        let controller = UserCreateController()
        navigationController?.pushViewController(controller, animated: true)
    }
    
    // MARK: - UI
    
    private func configureUI(){
        tableView.rowHeight = 80
        tableView.separatorColor = .white
        tableView.register(UserListCell.self, forCellReuseIdentifier: reuseIdentifier)
    }
    
    private func configureNavigationBar(){
        navigationController?.navigationBar.barTintColor = .twitterBlue
        navigationController?.navigationBar.backgroundColor = .twitterBlue
        navigationController?.navigationBar.barStyle = .default
        navigationController?.navigationBar.isTranslucent = false
        navigationController?.navigationBar.tintColor = .white
        navigationItem.title = "User List"
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = .twitterBlue
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.prefersLargeTitles = true
        navigationItem.largeTitleDisplayMode = .always
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.standardAppearance = appearance
        userAddButton = UIBarButtonItem(title: "Add", style: .done, target: self, action: #selector(handleAdd))
        navigationItem.rightBarButtonItem = userAddButton
        navigationItem.hidesBackButton = true
    }
    
    private func setUser() {
        users = Array(realm.objects(User.self))
        tableView.reloadData()
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

extension UserListController {

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! UserListCell
        let userIndex = users[indexPath.row]
        if userIndex.profileImage == nil {
            cell.profileImageView.image = UIImage(data: (UIImage(named: "placeholderImg")?.toPNGData())!)
        } else {
            cell.profileImageView.image = UIImage(data: userIndex.profileImage!)
        }
        cell.userNameLabel.text = userIndex.username
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let id = realm.objects(User.self).filter({ [self] in $0.id == users[indexPath.row].id}).last
        let alert = UIAlertController(title: "", message: "ユーザーを選択してください", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "このユーザーを選択する", style: .default, handler: { [self] (action: UIAlertAction!) -> Void in
            currentUser.setUser(id!)
            let controller = MainTabController()
            navigationController?.pushViewController(controller, animated: true)
        }))
        alert.addAction(UIAlertAction(title: "このユーザーを削除する", style: .destructive, handler: { [self] (action: UIAlertAction!) -> Void in
            try! realm.write {
                tweets = Array(realm.objects(Tweet.self))
                    .filter({ $0.userId == id?.id  })
                replys = Array(realm.objects(ReplyTweet.self))
                    .filter({ $0.userId == id?.id })
                tweets.forEach { tweets in
                    tweets.imageURLs.enumerated().forEach { index,image in
                        let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                        try? FileManager.default.removeItem(atPath: fileURL)
                    }
                    realm.delete(tweets.replyTweet)
                }
                replys.forEach{ replys in
                    replys.imageURLs.enumerated().forEach { index,image in
                        let fileURL = fileInDocumentsDirectory(filename: image.imageURL)
                        try? FileManager.default.removeItem(atPath: fileURL)
                    }
                    realm.delete(replys)
                }
                realm.delete(tweets)
                realm.delete(id!)
                users.remove(at: indexPath.row)
            }
            tableView.reloadData()
        }))
        alert.addAction(UIAlertAction(title: "キャンセル", style: UIAlertAction.Style.default, handler: nil))
        alert.pruneNegativeWidthConstraints()
        present(alert, animated: true, completion: nil)
    }

}
