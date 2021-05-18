
import UIKit

protocol PhotoZoomViewControllerDelegate: AnyObject {
    func photoZoomViewController(_ photoZoomViewController: PhotoZoomViewController, scrollViewDidScroll scrollView: UIScrollView)
}

class PhotoZoomViewController: UIViewController {
    
    // MARK: - Properties
    
    internal var imageViewBottomConstraint: NSLayoutConstraint!
    internal var imageViewLeadingConstraint: NSLayoutConstraint!
    internal var imageViewTopConstraint: NSLayoutConstraint!
    internal var imageViewTrailingConstraint: NSLayoutConstraint!
    internal var scrollView = UIScrollView()
    internal var imageView = UIImageView()
    
    weak var delegate: PhotoZoomViewControllerDelegate?
    
    internal var image = UIImage()
    internal var index: Int = 0

    var doubleTapGestureRecognizer = UITapGestureRecognizer()
    
    // MARK: - LifeCycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.scrollView.delegate = self
        configureUI()
        self.doubleTapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(didDoubleTapWith(gestureRecognizer:)))
        self.doubleTapGestureRecognizer.numberOfTapsRequired = 2
        if #available(iOS 11, *) {
            self.scrollView.contentInsetAdjustmentBehavior = .never
        }
        self.imageView.image = self.image
        self.imageView.contentMode = .scaleAspectFit
        self.imageView.frame = CGRect(x: self.imageView.frame.origin.x,
                                      y: self.imageView.frame.origin.y,
                                      width: self.image.size.width,
                                      height: self.image.size.height)
        self.view.addGestureRecognizer(self.doubleTapGestureRecognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: false)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateZoomScaleForSize(view.bounds.size)
        updateConstraintsForSize(view.bounds.size)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        updateZoomScaleForSize(view.bounds.size)
        updateConstraintsForSize(view.bounds.size)
    }
    
    override func viewSafeAreaInsetsDidChange() {
        if #available(iOS 11, *) {
            guard let parentVC = self.navigationController?.viewControllers.first as? FeedController else {
                return
            }
            parentVC.currentLeftSafeAreaInset = self.view.safeAreaInsets.left
            parentVC.currentRightSafeAreaInset = self.view.safeAreaInsets.right
        }
        
    }
    
    // MARK: - Selector
    
    @objc func didDoubleTapWith(gestureRecognizer: UITapGestureRecognizer) {
        let pointInView = gestureRecognizer.location(in: self.imageView)
        var newZoomScale = self.scrollView.maximumZoomScale
        if self.scrollView.zoomScale >= newZoomScale || abs(self.scrollView.zoomScale - newZoomScale) <= 0.01 {
            newZoomScale = self.scrollView.minimumZoomScale
        }
        let width = self.scrollView.bounds.width / newZoomScale
        let height = self.scrollView.bounds.height / newZoomScale
        let originX = pointInView.x - (width / 2.0)
        let originY = pointInView.y - (height / 2.0)
        let rectToZoomTo = CGRect(x: originX, y: originY, width: width, height: height)
        self.scrollView.zoom(to: rectToZoomTo, animated: true)
    }
    
    // MARK: - UI
    
    fileprivate func updateZoomScaleForSize(_ size: CGSize) {
        let widthScale = size.width / imageView.bounds.width
        let heightScale = size.height / imageView.bounds.height
        let minScale = min(widthScale, heightScale)
        scrollView.minimumZoomScale = minScale
        scrollView.zoomScale = minScale
        scrollView.maximumZoomScale = minScale * 4
    }
    
    fileprivate func updateConstraintsForSize(_ size: CGSize) {
        let yOffset = max(0, (size.height - imageView.frame.height) / 2)
        imageViewTopConstraint.constant = yOffset
        imageViewBottomConstraint.constant = yOffset
        let xOffset = max(0, (size.width - imageView.frame.width) / 2)
        imageViewLeadingConstraint.constant = xOffset
        imageViewTrailingConstraint.constant = xOffset
        let contentHeight = yOffset * 2 + self.imageView.frame.height
        view.layoutIfNeeded()
        self.scrollView.contentSize = CGSize(width: self.scrollView.contentSize.width, height: contentHeight)
    }
    
    private func configureUI(){
        view.addSubview(scrollView)
        scrollView.anchor(top: view.topAnchor, left: view.leftAnchor, bottom: view.superview?.bottomAnchor, right: view.superview?.rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: view.frame.width, height: view.frame.height)
        scrollView.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageViewTopConstraint = imageView.topAnchor.constraint(equalTo: scrollView.topAnchor)
        imageViewTopConstraint.isActive = true
        imageViewLeadingConstraint = imageView.leadingAnchor.constraint(equalTo: scrollView.leadingAnchor)
        imageViewLeadingConstraint.isActive = true
        imageViewTrailingConstraint = imageView.trailingAnchor.constraint(equalTo: scrollView.trailingAnchor)
        imageViewTrailingConstraint.isActive = true
        imageViewBottomConstraint = imageView.bottomAnchor.constraint(equalTo: scrollView.bottomAnchor)
        imageViewBottomConstraint.isActive = true
    }
    
}

// MARK: - UIScrollViewDelegate

extension PhotoZoomViewController: UIScrollViewDelegate {
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        updateConstraintsForSize(self.view.bounds.size)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.delegate?.photoZoomViewController(self, scrollViewDidScroll: scrollView)
    }
}
