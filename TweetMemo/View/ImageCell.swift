
import UIKit

class ImageCell: UICollectionViewCell {
    
    // MARK: - Properties
    
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
        iv.setDimensions(width: 150, height: 150)
        return iv
    }()
    
    // MARK: - LifeCycle
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        addSubview(selectedImageView)
        selectedImageView.anchor(top: topAnchor, left: leftAnchor, bottom: bottomAnchor, right: rightAnchor, paddingTop: 0, paddingLeft: 0, paddingBottom: 0, paddingRight: 0, width: 150, height: 150)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
}
