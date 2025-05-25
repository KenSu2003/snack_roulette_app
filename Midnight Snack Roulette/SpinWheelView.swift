import UIKit

protocol SpinWheelViewDelegate: AnyObject {
    func spinWheelDidSelectItem(_ item: String)
}

class SpinWheelView: UIView {
    // MARK: - Properties
    private var items: [String] = []
    private var currentRotation: CGFloat = 0
    private var isSpinning = false
    private var selectedItemAfterSpin: String?
    weak var delegate: SpinWheelViewDelegate?
    
    private let wheelContainerLayer = CALayer()
    private let pointerLayer = CAShapeLayer()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupLayers()
    }
    
    // MARK: - Setup
    private func setupLayers() {
        layer.addSublayer(wheelContainerLayer)
        layer.addSublayer(pointerLayer)
    }
    
    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        wheelContainerLayer.frame = bounds
        pointerLayer.frame = bounds
        drawWheel()
        updatePointerPath()
        wheelContainerLayer.setAffineTransform(CGAffineTransform(rotationAngle: currentRotation))
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        print("[SpinWheelView] bounds: \(bounds), center: \(center), layer.anchorPoint: \(layer.anchorPoint), layer.position: \(layer.position)")
    }
    
    private func drawWheel() {
        wheelContainerLayer.sublayers?.forEach { $0.removeFromSuperlayer() }
        guard !items.isEmpty else { return }
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let radius = min(bounds.width, bounds.height) / 2 - 10
        let itemAngle = (2 * .pi) / CGFloat(items.count)
        
        for (index, item) in items.enumerated() {
            let startAngle = CGFloat(index) * itemAngle
            let endAngle = startAngle + itemAngle
            
            // Segment
            let segmentPath = UIBezierPath()
            segmentPath.move(to: center)
            segmentPath.addArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: true)
            segmentPath.close()
            
            let segmentLayer = CAShapeLayer()
            segmentLayer.path = segmentPath.cgPath
            segmentLayer.fillColor = (index % 2 == 0 ? UIColor.systemBlue.withAlphaComponent(0.3) : UIColor.systemBlue.withAlphaComponent(0.1)).cgColor
            segmentLayer.strokeColor = UIColor.systemBlue.cgColor
            segmentLayer.lineWidth = 2
            wheelContainerLayer.addSublayer(segmentLayer)
            
            // Label (no counter-rotation, rotates with the wheel)
            let textAngle = startAngle + itemAngle / 2
            let textRadius = radius * 0.7
            let textPoint = CGPoint(
                x: center.x + cos(textAngle) * textRadius,
                y: center.y + sin(textAngle) * textRadius
            )
            
            let textLayer = CATextLayer()
            textLayer.string = NSAttributedString(string: item, attributes: [
                .font: UIFont.systemFont(ofSize: 14, weight: .semibold),
                .foregroundColor: UIColor.black
            ])
            textLayer.alignmentMode = .center
            textLayer.contentsScale = UIScreen.main.scale
            let textSize = (item as NSString).size(withAttributes: [.font: UIFont.systemFont(ofSize: 14, weight: .semibold)])
            textLayer.frame = CGRect(x: textPoint.x - textSize.width / 2, y: textPoint.y - textSize.height / 2, width: textSize.width, height: textSize.height)
            wheelContainerLayer.addSublayer(textLayer)
        }
    }
    
    private func updatePointerPath() {
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let pointerWidth: CGFloat = 24
        let pointerHeight: CGFloat = 28
        let radius = min(bounds.width, bounds.height) / 2 - 10
        let tipY = center.y - radius + 5
        
        let path = UIBezierPath()
        path.move(to: CGPoint(x: center.x, y: tipY)) // tip at top edge
        path.addLine(to: CGPoint(x: center.x - pointerWidth / 2, y: tipY + pointerHeight))
        path.addLine(to: CGPoint(x: center.x + pointerWidth / 2, y: tipY + pointerHeight))
        path.close()
        
        pointerLayer.path = path.cgPath
        pointerLayer.fillColor = UIColor.systemRed.cgColor
        pointerLayer.zPosition = 10 // ensure on top
    }
    
    // MARK: - Public Methods
    func setItems(_ items: [String]) {
        self.items = items
        setNeedsLayout()
    }
    
    func spin() {
        guard !isSpinning, !items.isEmpty else { return }
        isSpinning = true

        // Remove any lingering animations and set the transform to the current rotation
        wheelContainerLayer.removeAllAnimations()
        wheelContainerLayer.setAffineTransform(CGAffineTransform(rotationAngle: currentRotation))

        // Random number of full rotations (3-5)
        let fullRotations = CGFloat.random(in: 3...5)
        // Random final angle
        let finalAngle = CGFloat.random(in: 0...(2 * .pi))

        let totalRotation = (fullRotations * 2 * .pi) + finalAngle

        // Create rotation animation
        let rotation = CABasicAnimation(keyPath: "transform.rotation.z")
        rotation.fromValue = currentRotation
        rotation.toValue = currentRotation + totalRotation
        rotation.duration = 3.0
        rotation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        rotation.isRemovedOnCompletion = false
        rotation.fillMode = .forwards
        rotation.delegate = self

        wheelContainerLayer.add(rotation, forKey: "rotation")
        currentRotation += totalRotation

        // Calculate selected item and store for use after animation
        let itemAngle = (2 * .pi) / CGFloat(items.count)
        let normalizedAngle = currentRotation.truncatingRemainder(dividingBy: 2 * .pi)
        let selectedIndex = min(Int((2 * .pi - normalizedAngle) / itemAngle) % items.count, items.count - 1)
        selectedItemAfterSpin = items[selectedIndex]
    }
}

// MARK: - CAAnimationDelegate
extension SpinWheelView: CAAnimationDelegate {
    func animationDidStop(_ anim: CAAnimation, finished flag: Bool) {
        guard flag else { return }
        // Sync the model layer's transform to the presentation layer's transform
        if let pres = wheelContainerLayer.presentation() {
            let t = pres.affineTransform()
            wheelContainerLayer.setAffineTransform(t)
            currentRotation = atan2(t.b, t.a)
        }
        wheelContainerLayer.removeAllAnimations()
        isSpinning = false
        if let selected = selectedItemAfterSpin {
            delegate?.spinWheelDidSelectItem(selected)
            selectedItemAfterSpin = nil
        }
    }
} 
