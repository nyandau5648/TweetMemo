
import UIKit
import RealmSwift

private let realm = try! Realm()

class NotificationViewController: UITableViewController {
    
    //MARK: - Properties
    
    let currentUser = CurrentUser.shared
    
    private let reuseIdentifier = "NotificationCell"
    
    private var users = Array(realm.objects(User.self))
    
    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.navigationBar.isHidden = false
        navigationController?.navigationBar.barStyle = .default
    }
    
    //MARK: - UI
    
    func configureUI(){
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(named: "Mode")
        navigationController?.navigationBar.standardAppearance = appearance
        view.backgroundColor = UIColor(named: "Mode")
        navigationItem.title = "Notifications"
        tableView.register(NotificationCell.self, forCellReuseIdentifier: reuseIdentifier)
        tableView.rowHeight = 60
        tableView.separatorStyle = .none
    }
    
}

// MARK: - UITableViewDataSource

extension NotificationViewController {
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath) as! NotificationCell
        cell.delegate = self
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.contentView.isUserInteractionEnabled = false
        let userIndex = users[indexPath.row]
        cell.profileImageView.image = UIImage(data: userIndex.profileImage!)
        cell.notificationLabel.text = userIndex.username
        if currentUser.user?.id == userIndex.id {
            cell.followButton.isEnabled = false
            cell.followButton.setTitle("My Account", for: .normal)
            cell.followButton.setTitleColor(.white, for: .normal)
            cell.followButton.backgroundColor = .twitterBlue
        } else {
            if currentUser.user!.followUserList.contains(where: {$0 == userIndex.id }) {
                    cell.followButton.setTitle("unfollow", for: .normal)
                    cell.followButton.backgroundColor = .white
                    cell.followButton.setTitleColor(.twitterBlue, for: .normal)
                } else {
                    cell.followButton.setTitle("follow", for: .normal)
                    cell.followButton.backgroundColor = .twitterBlue
                    cell.followButton.setTitleColor(.white, for: .normal)
            }
        }
        return cell
    }
    
}

// MARK: - NotificationCellDelegate

extension NotificationViewController: NotificationCellDelegate {
    
    func didTapFollow(_ cell: NotificationCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        guard let currentUserIndex = users.firstIndex(where: {$0.id == currentUser.user?.id }) else { return }
        let user = users[indexPath.row]
        try! realm.write {
            if let index = currentUser.user!.followUserList.firstIndex(where: {$0 == user.id }) {
                users[currentUserIndex].followUserList.remove(at: index)
                cell.followButton.setTitle("follow", for: .normal)
                cell.followButton.backgroundColor = .twitterBlue
                cell.followButton.setTitleColor(.white, for: .normal)
            } else {
                users[currentUserIndex].followUserList.append(user.id)
                cell.followButton.setTitle("unfollow", for: .normal)
                cell.followButton.backgroundColor = .white
                cell.followButton.setTitleColor(.twitterBlue, for: .normal)
            }
            currentUser.setUser(users[currentUserIndex])
        }
    }
    
    func didTapProfileImage(_ cell: NotificationCell) {
        guard let indexPath = tableView.indexPath(for: cell) else { return }
        let user = users[indexPath.row]
        let controller = ProfileController(userId: user.id)
        navigationController?.pushViewController(controller, animated: true)
    }
    
}
