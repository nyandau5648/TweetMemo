
import UIKit
import RealmSwift

protocol PhotoPageContainerViewControllerDelegate: AnyObject {
    func containerViewController(_ containerViewController: PhotoPageContainerViewController, indexDidUpdate currentIndex: Int)
}

class PhotoPageContainerViewController: UIViewController, UIGestureRecognizerDelegate {

    enum ScreenMode {
        case full, normal
    }
    
    // MARK: - Properties
    
    private var currentMode: ScreenMode = .normal
    
    weak var delegate: PhotoPageContainerViewControllerDelegate?
    
    private var pageViewController: UIPageViewController?
    private var controllers: [UIViewController] = []
    
    var currentViewController: PhotoZoomViewController {
        return self.pageViewController?.viewControllers![0] as! PhotoZoomViewController
    }
    
    internal var currentIndex = 0
    internal var nextIndex: Int?
    
    internal var imageURLs = List<CellImageURL>()
    
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var singleTapGestureRecognizer: UITapGestureRecognizer!
    
    internal var transitionController = ZoomTransitionController()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: nil)
        self.pageViewController?.delegate = self
        self.pageViewController?.dataSource = self
        self.panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(didPanWith(gestureRecognizer:)))
        self.panGestureRecognizer.delegate = self
        self.pageViewController?.view.addGestureRecognizer(self.panGestureRecognizer)
        self.singleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didSingleTapWith(gestureRecognizer:)))
        self.pageViewController?.view.addGestureRecognizer(self.singleTapGestureRecognizer)
        view.addSubview((pageViewController?.view)!)
        
        let vc = PhotoZoomViewController()
        vc.delegate = self
        vc.index = self.currentIndex
        let photos = imageURLs.map { UIImage(contentsOfFile: self.fileInDocumentsDirectory(filename: $0.imageURL)) }
        vc.image = photos[self.currentIndex]!
        let viewControllers = [vc]
        self.pageViewController?.setViewControllers(viewControllers, direction: .forward, animated: true, completion: nil)
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        pageViewController?.didMove(toParent: self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    // MARK: - Selector
    
    @objc private func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    @objc func didPanWith(gestureRecognizer: UIPanGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            self.currentViewController.scrollView.isScrollEnabled = false
            self.transitionController.isInteractive = true
            let _ = self.navigationController?.popViewController(animated: true)
        case .ended:
            if self.transitionController.isInteractive {
                self.currentViewController.scrollView.isScrollEnabled = true
                self.transitionController.isInteractive = false
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        default:
            if self.transitionController.isInteractive {
                self.transitionController.didPanWith(gestureRecognizer: gestureRecognizer)
            }
        }
    }
    
    @objc private func didSingleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        if self.currentMode == .full {
            changeScreenMode(to: .normal)
            self.currentMode = .normal
        } else {
            changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
    
    // MARK: - UI
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        
        if let gestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
            let velocity = gestureRecognizer.velocity(in: self.view)
            
            var velocityCheck : Bool = false
            
            if UIDevice.current.orientation.isLandscape {
                velocityCheck = velocity.x < 0
            }
            else {
                velocityCheck = velocity.y < 0
            }
            if velocityCheck {
                return false
            }
        }
        
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        if otherGestureRecognizer == self.currentViewController.scrollView.panGestureRecognizer {
            if self.currentViewController.scrollView.contentOffset.y == 0 {
                return true
            }
        }
        return false
    }
    
    private func changeScreenMode(to: ScreenMode) {
        if to == .full {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
                            self.view.backgroundColor = .black
                            
            }, completion: { completed in
            })
        } else {
            self.navigationController?.setNavigationBarHidden(true, animated: false)
            UIView.animate(withDuration: 0.25,
                           animations: {
                            if #available(iOS 13.0, *) {
                                self.view.backgroundColor = .systemBackground
                            } else {
                                self.view.backgroundColor = .white
                            }
            }, completion: { completed in
            })
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
    
}

// MARK: - UIPageViewControllerDelegate, UIPageViewControllerDataSource

extension PhotoPageContainerViewController: UIPageViewControllerDelegate, UIPageViewControllerDataSource {
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        if currentIndex == 0 {
            return nil
        }
        let photos = imageURLs.map { UIImage(contentsOfFile: self.fileInDocumentsDirectory(filename: $0.imageURL)) }
        let vc = PhotoZoomViewController()
        vc.delegate = self
        vc.image = photos[currentIndex - 1]!
        vc.index = currentIndex - 1
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        let photos = imageURLs.map { UIImage(contentsOfFile: self.fileInDocumentsDirectory(filename: $0.imageURL)) }
        if currentIndex == (photos.count - 1) {
            return nil
        }
        let vc = PhotoZoomViewController()
        vc.delegate = self
        self.singleTapGestureRecognizer.require(toFail: vc.doubleTapGestureRecognizer)
        vc.image = photos[currentIndex + 1]!
        vc.index = currentIndex + 1
        return vc
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let nextVC = pendingViewControllers.first as? PhotoZoomViewController else {
            return
        }
        self.nextIndex = nextVC.index
    }
    
    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        
        if (completed && self.nextIndex != nil) {
            previousViewControllers.forEach { vc in
                let zoomVC = vc as! PhotoZoomViewController
                zoomVC.scrollView.zoomScale = zoomVC.scrollView.minimumZoomScale
            }
            self.currentIndex = self.nextIndex!
            self.delegate?.containerViewController(self, indexDidUpdate: self.currentIndex)
        }
        
        self.nextIndex = nil
    }
    
}

// MARK: - PhotoZoomViewControllerDelegate

extension PhotoPageContainerViewController: PhotoZoomViewControllerDelegate {
    
    func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView) {
        if scrollView.zoomScale != scrollView.minimumZoomScale && self.currentMode != .full {
            self.changeScreenMode(to: .full)
            self.currentMode = .full
        }
    }
}

// MARK: - ZoomAnimatorDelegate

extension PhotoPageContainerViewController: ZoomAnimatorDelegate {
    
    func transitionWillStartWith(zoomAnimator: ZoomAnimator) {
    }
    
    func transitionDidEndWith(zoomAnimator: ZoomAnimator) {
    }
    
    func referenceImageView(for zoomAnimator: ZoomAnimator) -> UIImageView? {
        return self.currentViewController.imageView
    }
    
    func referenceImageViewFrameInTransitioningView(for zoomAnimator: ZoomAnimator) -> CGRect? {
        return self.currentViewController.scrollView.convert(self.currentViewController.imageView.frame, to: self.currentViewController.view)
    }
    
}
