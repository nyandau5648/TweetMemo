
import UIKit
import RealmSwift

class MainTabController: UITabBarController {

    //MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(named: "Mode")
        configureViewController()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: true)
        navigationController?.navigationBar.backgroundColor = UIColor(named: "Mode")
    }
    
    //MARK: - Helper
    
    private func configureViewController(){
        let feed = FeedController(collectionViewLayout: UICollectionViewFlowLayout())
        let nav1 = templateNavigationController(image: UIImage(named: "home_unselected")!, rootViewController: feed)
        let notifications = NotificationViewController()
        let nav2 = templateNavigationController(image: UIImage(named: "_i_icon_14195_icon_141952_48")!, rootViewController: notifications)
        viewControllers = [nav1, nav2]
    }
    
    private func templateNavigationController(image: UIImage, rootViewController: UIViewController) -> UINavigationController {
        let nav = UINavigationController(rootViewController: rootViewController)
        nav.tabBarItem.image = image
        let appearance = UINavigationBarAppearance()
        appearance.backgroundColor = UIColor(named: "Mode")
        navigationItem.scrollEdgeAppearance = appearance
        return nav
    }
    
}
