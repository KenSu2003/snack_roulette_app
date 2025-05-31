import UIKit

protocol SpinWheelViewDelegate: AnyObject {
    func spinWheelDidSelectItem(_ item: String)
}

class SpinWheelView: UIView {
    // MARK: - Properties
    private var items: [String] = []
    private var currentRotation: CGFloat = 0
    private var isSpinning = false
    private var selectedItem: String?
    weak var delegate: SpinWheelViewDelegate?
    
    // Use a single UIImageView for the wheel instead of CALayers
    private let wheelImageView = UIImageView()
    private let pointerImageView = UIImageView()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupViews()
    }
    
    // MARK: - Setup
    private func setupViews() {
        // Setup wheel image view
        wheelImageView.contentMode = .scaleAspectFit
        wheelImageView.translatesAutoresizingMaskIntoConstraints = false
        wheelImageView.backgroundColor = .systemBlue.withAlphaComponent(0.1)
        wheelImageView.layer.cornerRadius = min(bounds.width, bounds.height) / 2
        wheelImageView.clipsToBounds = true
        addSubview(wheelImageView)
        
        // Setup pointer image view
        pointerImageView.image = UIImage(systemName: "arrowtriangle.down.fill")
        pointerImageView.tintColor = .systemRed
        pointerImageView.contentMode = .scaleAspectFit
        pointerImageView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pointerImageView)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            wheelImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            wheelImageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            wheelImageView.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.9),
            wheelImageView.heightAnchor.constraint(equalTo: wheelImageView.widthAnchor),
            
            pointerImageView.centerXAnchor.constraint(equalTo: centerXAnchor),
            pointerImageView.bottomAnchor.constraint(equalTo: wheelImageView.topAnchor, constant: 10),
            pointerImageView.widthAnchor.constraint(equalToConstant: 30),
            pointerImageView.heightAnchor.constraint(equalToConstant: 30)
        ])
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        // Redraw the wheel when layout changes
        drawWheel()
        
        // Update corner radius as bounds may have changed
        wheelImageView.layer.cornerRadius = wheelImageView.bounds.width / 2
    }
    
    // MARK: - Drawing
    private func drawWheel() {
        guard !items.isEmpty else { return }
        
        // Make sure the wheel has valid dimensions before drawing
        let wheelSize = wheelImageView.bounds.size
        guard wheelSize.width > 0 && wheelSize.height > 0 else {
            print("Cannot draw wheel: invalid size \(wheelSize)")
            return
        }
        
        // Use a fixed size for the image context to avoid zero dimensions
        let size = CGSize(width: max(wheelSize.width, 100), height: max(wheelSize.height, 100))
        
        // Create a new image context
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        let center = CGPoint(x: size.width / 2, y: size.height / 2)
        let radius = min(size.width, size.height) / 2 - 10
        let itemAngle = (2 * .pi) / CGFloat(items.count)
        
        // Draw wheel segments
        for (index, item) in items.enumerated() {
            let startAngle = CGFloat(index) * itemAngle
            let endAngle = startAngle + itemAngle
            
            // Create segment path - using clockwise: true for proper direction
            context.move(to: center)
            context.addArc(center: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            context.closePath()
            
            // Fill segment
            let fillColor = (index % 2 == 0) ? 
                UIColor.systemBlue.withAlphaComponent(0.3) : 
                UIColor.systemBlue.withAlphaComponent(0.1)
            context.setFillColor(fillColor.cgColor)
            context.setStrokeColor(UIColor.systemBlue.cgColor)
            context.setLineWidth(2)
            context.drawPath(using: .fillStroke)
            
            // Add text
            let textAngle = startAngle + (itemAngle / 2)
            let textRadius = radius * 0.7
            let textPoint = CGPoint(
                x: center.x + cos(textAngle) * textRadius,
                y: center.y + sin(textAngle) * textRadius
            )
            
            // Save context state before rotating text
            context.saveGState()
            
            // Translate to text position and rotate
            context.translateBy(x: textPoint.x, y: textPoint.y)
            context.rotate(by: textAngle + .pi/2)
            
            // Configure text attributes
            let attributes: [NSAttributedString.Key: Any] = [
                .font: UIFont.systemFont(ofSize: 14, weight: .medium),
                .foregroundColor: UIColor.black
            ]
            let textSize = (item as NSString).size(withAttributes: attributes)
            
            // Draw text centered at origin (which is now at textPoint after translation)
            (item as NSString).draw(
                at: CGPoint(x: -textSize.width / 2, y: -textSize.height / 2),
                withAttributes: attributes
            )
            
            // Restore context
            context.restoreGState()
        }
        
        // Get the image from the context
        let wheelImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        // Set the image to the image view
        wheelImageView.image = wheelImage
    }
    
    // MARK: - Public Methods
    func setItems(_ items: [String]) {
        self.items = items
        
        // Only draw the wheel if we have a valid size
        if wheelImageView.bounds.size.width > 0 && wheelImageView.bounds.size.height > 0 {
            drawWheel()
        }
    }
    
    func spin() {
        guard !isSpinning, !items.isEmpty else { return }
        isSpinning = true
        
        // Select a random item index
        let selectedIndex = Int.random(in: 0..<items.count)
        print("Selected index will be: \(selectedIndex) (\(items[selectedIndex]))")
        
        // Reset the wheel's transform to avoid accumulated transforms
        wheelImageView.transform = .identity
        wheelImageView.layer.removeAllAnimations()
        
        // Create a rotation animation using CABasicAnimation for better control
        let spinAnimation = CABasicAnimation(keyPath: "transform.rotation")
        
        // Set from value (current rotation)
        spinAnimation.fromValue = 0
        
        // Set a VERY large to value (50-70 full rotations) for dramatic spinning
        // Negative for clockwise rotation
        let rotations = Double.random(in: 50...70)
        spinAnimation.toValue = -2 * Double.pi * rotations
        
        // Configure animation timing
        spinAnimation.duration = 4.0  // 4 seconds total duration
        spinAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        
        // Make sure animation completes
        spinAnimation.fillMode = .forwards
        spinAnimation.isRemovedOnCompletion = false
        
        // Add completion handler using CATransaction
        CATransaction.begin()
        CATransaction.setCompletionBlock {
            // Reset isSpinning flag
            self.isSpinning = false
            
            // Notify delegate with selected item
            if selectedIndex >= 0 && selectedIndex < self.items.count {
                let selected = self.items[selectedIndex]
                self.delegate?.spinWheelDidSelectItem(selected)
            }
            
            // Set the final rotation directly on the layer
            let itemAngle = (2 * Double.pi) / Double(self.items.count)
            let finalAngle = -Double(selectedIndex) * itemAngle
            
            // Adjust the transform to place the selected segment at the top
            self.wheelImageView.layer.transform = CATransform3DMakeRotation(CGFloat(finalAngle), 0, 0, 1)
        }
        
        // Add the animation to the layer
        wheelImageView.layer.add(spinAnimation, forKey: "spinAnimation")
        
        // Log the animation
        print("Spinning wheel with \(rotations) rotations (very fast)")
        
        CATransaction.commit()
    }
} 
