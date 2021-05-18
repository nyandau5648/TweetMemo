
import UIKit

protocol UploadTweetCellDelegate: AnyObject {
    func deleteImage(_ cell: UploadTweetCell)
}

class UploadTweetCell: UICollectionViewCell {
    
    // MARK: - Properties
    
    weak var delegate: UploadTweetCellDelegate?
    
    let selectedImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = UIImage(named: "placeholderImg")
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.backgroundColor = .lightGray
        iv.layer.borderColor = UIColor.white.cgColor
        iv.layer.borderWidth = 1.5
        iv.layer.cornerRadius = 10
        iv.isUserInteractionEnabled = true
        iv.layer.masksToBounds = true
        return iv
    }()
    
    private lazy var deleteImageButton: UIButton = {
        let button = UIButton(type: .system)
        button.frame = CGRect(x: 0, y: 0, width: 20, height: 20)
        button.tintColor = .black
        button.setImage(UIImage(named: "_i_icon_11920_icon_119202_48"), for: .normal)
        button.layer.cornerRadius = 20 / 2
        button.addTarget(self, action: #selector(handleDeleteImage), for: .touchUpInside)
        return button
    }()
    
    // MARK: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(selectedImageView)
        selectedImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0)

        addSubview(deleteImageButton)
        deleteImageButton.anchor(top: selectedImageView.topAnchor, right: selectedImageView.rightAnchor, paddingTop: 8, paddingRight: 8, width: 20, height: 20)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Selector
    
    @objc func handleDeleteImage() {
        delegate?.deleteImage(self)
    }
    
}
