import UIKit
import MapKit

// MARK: - Models
struct Restaurant: Codable {
    let id: String
    let name: String
    let discount: String
    let address: String
    let latitude: Double
    let longitude: Double
    let cuisine: String
    let rating: Double
    let openUntil: String
    
    enum CodingKeys: String, CodingKey {
        case id, name, discount, address, latitude, longitude, cuisine, rating
        case openUntil = "open_until"
    }
}

struct RestaurantResponse: Codable {
    let restaurants: [Restaurant]
}

struct Friend: Codable {
    let id: String
    let name: String
    let avatar: String // This will be a system image name
    let isOnline: Bool
}

class WheelViewController: UIViewController {
    
    // MARK: - Properties
    private var countdownTimer: Timer?
    private var restaurants: [Restaurant] = []
    private var selectedRestaurant: Restaurant?
    private var friends: [Friend] = []
    private var selectedItemAfterSpin: String?
    private var statusUpdateTimer: Timer?
    private var currentStatusIndex = 0
    private var spinLockTimer: Timer?
    private var remainingLockTime: TimeInterval = 0
    private var isSpinLocked = false
    private var currentDiscountCode: String = ""
    private var hasSpunToday = false
    
    // Time restriction settings
    private let allowedStartHour = 0  // 12:00 AM (midnight)
    private let allowedEndHour = 10   // 10:00 AM
    
    // Testing toggle - set to true to bypass time restrictions
    private let mockTimeForTesting = false   // false by default
    private let mockHourForTesting = 9 // 2:00 AM (within allowed time)
    
    // Simulated friend status messages
    private let friendStatuses = [
        "Alice is enjoying Tacos at Taco Time",
        "Bob just ordered a Double Burger at Burger Joint",
        "Charlie is eating Pizza Paradise right now",
        "Diana recommends the spicy ramen at Midnight Ramen",
        "Eve is on her way to Tasty Bites",
        "Frank just finished his meal at Pizza Paradise",
        "Grace loves the dessert at Midnight Ramen"
    ]
    
    // Discount codes
    private let discountCodes = [
        "MIDNIGHT25",
        "LATENIGHT20",
        "HUNGRYHOUR15",
        "SNACKTIME10",
        "MIDNIGHTMUNCH",
        "LATENIGHTBITE",
        "MIDNIGHTCRAVING"
    ]
    
    // MARK: - UI Components
    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var discountCodeView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemGray6
        view.layer.cornerRadius = 10
        view.isHidden = true
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var discountCodeLabel: UILabel = {
        let label = UILabel()
        label.text = "Your Discount Code"
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .systemGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var discountCodeValueLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = .systemBlue
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusBarView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        view.layer.cornerRadius = 10
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    private lazy var statusLabel: UILabel = {
        let label = UILabel()
        label.text = friendStatuses.first
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14)
        label.textColor = .darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private lazy var statusIconImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(systemName: "bubble.left.fill"))
        imageView.tintColor = .systemBlue
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private lazy var messageTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "What should I eat for late-night snack?"
        textField.borderStyle = .roundedRect
        textField.translatesAutoresizingMaskIntoConstraints = false
        return textField
    }()
    
    private lazy var spinButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("SPIN!", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 24, weight: .bold)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 25
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(spinButtonTapped), for: .touchUpInside)
        return button
    }()
    
    private lazy var spinWheelView: SpinWheelView = {
        let wheel = SpinWheelView()
        wheel.translatesAutoresizingMaskIntoConstraints = false
        wheel.delegate = self
        return wheel
    }()
    
    private lazy var friendsCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 80)
        layout.minimumLineSpacing = 10
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.register(FriendCell.self, forCellWithReuseIdentifier: "FriendCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        return collectionView
    }()
    
    private lazy var resetButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Reset", for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 14)
        button.backgroundColor = .systemRed.withAlphaComponent(0.7)
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        button.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        return button
    }()
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkTimeAndInitialize()
        loadRestaurantData()
        loadSimulatedFriends()
        startStatusUpdates()
        loadSpinRecord()
        checkSpinRestrictions()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Check restrictions each time the view appears
        checkSpinRestrictions()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStatusUpdates()
        stopLockTimer()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup status bar
        statusBarView.addSubview(statusIconImageView)
        statusBarView.addSubview(statusLabel)
        
        // Setup discount code view
        discountCodeView.addSubview(discountCodeLabel)
        discountCodeView.addSubview(discountCodeValueLabel)
        
        // Add subviews
        view.addSubview(countdownLabel) // This is only for initial countdown, not the lock countdown
        view.addSubview(statusBarView)
        view.addSubview(friendsCollectionView)
        view.addSubview(spinWheelView)
        view.addSubview(spinButton)
        view.addSubview(discountCodeView)
        view.addSubview(resetButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Hidden initial countdown (center of screen)
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Status bar at top with more padding
            statusBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 40),
            statusBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusBarView.heightAnchor.constraint(equalToConstant: 44),
            
            statusIconImageView.leadingAnchor.constraint(equalTo: statusBarView.leadingAnchor, constant: 12),
            statusIconImageView.centerYAnchor.constraint(equalTo: statusBarView.centerYAnchor),
            statusIconImageView.widthAnchor.constraint(equalToConstant: 20),
            statusIconImageView.heightAnchor.constraint(equalToConstant: 20),
            
            statusLabel.leadingAnchor.constraint(equalTo: statusIconImageView.trailingAnchor, constant: 8),
            statusLabel.trailingAnchor.constraint(equalTo: statusBarView.trailingAnchor, constant: -12),
            statusLabel.centerYAnchor.constraint(equalTo: statusBarView.centerYAnchor),
            
            // Friends collection below status bar with more spacing
            friendsCollectionView.topAnchor.constraint(equalTo: statusBarView.bottomAnchor, constant: 30),
            friendsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            friendsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            friendsCollectionView.heightAnchor.constraint(equalToConstant: 80),
            
            // Wheel with more spacing from friends
            spinWheelView.topAnchor.constraint(equalTo: friendsCollectionView.bottomAnchor, constant: 50),
            spinWheelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinWheelView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            spinWheelView.heightAnchor.constraint(equalTo: spinWheelView.widthAnchor),
            
            // More space between wheel and spin button
            spinButton.topAnchor.constraint(equalTo: spinWheelView.bottomAnchor, constant: 60),
            spinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinButton.widthAnchor.constraint(equalToConstant: 200),
            spinButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Discount code view below spin button
            discountCodeView.topAnchor.constraint(equalTo: spinButton.bottomAnchor, constant: 20),
            discountCodeView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            discountCodeView.widthAnchor.constraint(equalToConstant: 250),
            discountCodeView.heightAnchor.constraint(equalToConstant: 80),
            discountCodeView.bottomAnchor.constraint(lessThanOrEqualTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            
            // Discount code labels
            discountCodeLabel.topAnchor.constraint(equalTo: discountCodeView.topAnchor, constant: 10),
            discountCodeLabel.centerXAnchor.constraint(equalTo: discountCodeView.centerXAnchor),
            discountCodeLabel.leadingAnchor.constraint(equalTo: discountCodeView.leadingAnchor, constant: 10),
            discountCodeLabel.trailingAnchor.constraint(equalTo: discountCodeView.trailingAnchor, constant: -10),
            
            discountCodeValueLabel.topAnchor.constraint(equalTo: discountCodeLabel.bottomAnchor, constant: 10),
            discountCodeValueLabel.centerXAnchor.constraint(equalTo: discountCodeView.centerXAnchor),
            discountCodeValueLabel.leadingAnchor.constraint(equalTo: discountCodeView.leadingAnchor, constant: 10),
            discountCodeValueLabel.trailingAnchor.constraint(equalTo: discountCodeView.trailingAnchor, constant: -10),
            
            // Reset button at bottom of screen
            resetButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            resetButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            resetButton.widthAnchor.constraint(equalToConstant: 100),
            resetButton.heightAnchor.constraint(equalToConstant: 40)
        ])
        
        // Initially hide interactive elements
        countdownLabel.isHidden = true
        statusBarView.isHidden = true
        friendsCollectionView.isHidden = true
        spinWheelView.isHidden = true
        spinButton.isHidden = true
        discountCodeView.isHidden = true
        resetButton.isHidden = true
        
        // Style the spin button to match the wheel
        spinButton.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        spinButton.layer.cornerRadius = 25

        // Style the reset button to be more visible
        resetButton.backgroundColor = .systemRed.withAlphaComponent(0.8)
        resetButton.layer.cornerRadius = 20
        resetButton.titleLabel?.font = .systemFont(ofSize: 18, weight: .bold)
    }
    
    // MARK: - Data Loading
    private func loadRestaurantData() {
        guard let url = Bundle.main.url(forResource: "restaurants", withExtension: "json") else {
            print("Error: Could not find restaurants.json")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let decoder = JSONDecoder()
            let response = try decoder.decode(RestaurantResponse.self, from: data)
            self.restaurants = response.restaurants
            print("Successfully loaded \(restaurants.count) restaurants")
            let restaurantNames = self.restaurants.map { $0.name }
            self.spinWheelView.setItems(restaurantNames)
            self.spinButton.isEnabled = !restaurantNames.isEmpty
            self.spinButton.alpha = restaurantNames.isEmpty ? 0.5 : 1.0
        } catch {
            print("Error loading restaurant data: \(error)")
        }
    }
    
    private func loadSimulatedFriends() {
        // Simulate friends data with more variety
        friends = [
            Friend(id: "1", name: "Alice", avatar: "person.circle.fill", isOnline: true),
            Friend(id: "2", name: "Bob", avatar: "person.circle.fill", isOnline: false),
            Friend(id: "3", name: "Charlie", avatar: "person.circle.fill", isOnline: true),
            Friend(id: "4", name: "Diana", avatar: "person.circle.fill", isOnline: true),
            Friend(id: "5", name: "Eve", avatar: "person.circle.fill", isOnline: false),
            Friend(id: "6", name: "Frank", avatar: "person.circle.fill", isOnline: true),
            Friend(id: "7", name: "Grace", avatar: "person.circle.fill", isOnline: true),
            Friend(id: "8", name: "Henry", avatar: "person.circle.fill", isOnline: false)
        ]
    }
    
    // MARK: - Time Check Methods
    private func checkTimeAndInitialize() {
        // For testing, always show interactive phase
        proceedToInteractivePhase()
    }
    
    // MARK: - Interactive Phase Methods
    private func proceedToInteractivePhase() {
        countdownLabel.isHidden = true
        statusBarView.isHidden = false
        friendsCollectionView.isHidden = false
        spinWheelView.isHidden = false
        spinButton.isHidden = false
        discountCodeView.isHidden = true  // Hidden until a discount code is generated
        resetButton.isHidden = true  // Show reset button
        
        // Setup spin wheel with restaurant names
        let restaurantNames = restaurants.map { $0.name }
        spinWheelView.setItems(restaurantNames)
    }
    
    // MARK: - Time Restriction Methods
    private func checkSpinRestrictions() {
        if hasSpunToday {
            // User has already spun today
            lockSpinWithMessage("You've already spun today")
            return
        }
        
        if !isWithinAllowedTimeRange() {
            // Outside allowed time range
            let nextAllowedTime = getNextAllowedTime()
            lockSpinUntil(nextAllowedTime, message: "Spinning available 12AM-10AM")
        } else {
            // Within allowed time range and hasn't spun yet
            unlockSpin()
        }
    }
    
    private func isWithinAllowedTimeRange() -> Bool {
        let calendar = Calendar.current
        let now = Date()
        
        // If testing mode is enabled, use mock time
        if mockTimeForTesting {
            return mockHourForTesting >= allowedStartHour && mockHourForTesting < allowedEndHour
        }
        
        let hour = calendar.component(.hour, from: now)
        return hour >= allowedStartHour && hour < allowedEndHour
    }
    
    private func getNextAllowedTime() -> Date {
        let calendar = Calendar.current
        let now = Date()
        
        // If it's after the end time, next allowed time is midnight
        var components = calendar.dateComponents([.year, .month, .day], from: now)
        components.day! += 1  // Next day
        components.hour = allowedStartHour
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? Date()
    }
    
    private func lockSpinWithMessage(_ message: String) {
        isSpinLocked = true
        spinButton.isEnabled = false
        spinButton.backgroundColor = .systemGray3
        spinButton.setTitle(message, for: .normal)
    }
    
    private func unlockSpin() {
        isSpinLocked = false
        spinButton.isEnabled = true
        spinButton.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        spinButton.setTitle("SPIN!", for: .normal)
    }
    
    // MARK: - Actions
    @objc private func spinButtonTapped() {
        if isSpinLocked {
            let alert = UIAlertController(
                title: "Spinning Not Available",
                message: "Spinning is only available between 12:00 AM and 10:00 AM, and only once per day.",
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            present(alert, animated: true)
            return
        }
        
        // Mark as spun for today
        hasSpunToday = true
        
        print("Spinning with items: \(restaurants.map { $0.name })")
        spinWheelView.spin()
        
        // Save the fact that user has spun today
        saveSpinRecord()
    }
    
    // MARK: - Restaurant Details
    private func showRestaurantDetails(for restaurant: Restaurant) {
        currentDiscountCode = generateDiscountCode()
        let discountMessage = "Use code: \(currentDiscountCode) for an extra \(restaurant.discount)"
        
        let alert = UIAlertController(
            title: restaurant.name,
            message: """
                \(discountMessage)
                Cuisine: \(restaurant.cuisine)
                Rating: \(restaurant.rating)
                Open until: \(restaurant.openUntil)
                Address: \(restaurant.address)
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Navigate", style: .default) { [weak self] _ in
            self?.openInMaps(restaurant: restaurant)
            self?.showDiscountCode(self?.currentDiscountCode ?? "")
            self?.lockSpinUntilMidnight()
        })
        
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            self?.shareRestaurant(restaurant: restaurant, discountCode: self?.currentDiscountCode ?? "")
            self?.showDiscountCode(self?.currentDiscountCode ?? "")
            self?.lockSpinUntilMidnight()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel) { [weak self] _ in
            self?.showDiscountCode(self?.currentDiscountCode ?? "")
            self?.lockSpinUntilMidnight()
        })
        
        present(alert, animated: true)
    }
    
    private func openInMaps(restaurant: Restaurant) {
        let coordinate = CLLocationCoordinate2D(
            latitude: restaurant.latitude,
            longitude: restaurant.longitude
        )
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate))
        mapItem.name = restaurant.name
        mapItem.openInMaps(launchOptions: nil)
    }
    
    private func shareRestaurant(restaurant: Restaurant, discountCode: String) {
        let text = """
            Check out \(restaurant.name)!
            \(restaurant.discount)
            Use discount code: \(discountCode) for an extra discount!
            Open until \(restaurant.openUntil)
            Address: \(restaurant.address)
            """
        
        let activityVC = UIActivityViewController(
            activityItems: [text],
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }
    
    // Status update methods
    private func startStatusUpdates() {
        // Update status immediately
        updateStatusBar()
        
        // Start timer to cycle through statuses
        statusUpdateTimer = Timer.scheduledTimer(
            timeInterval: 5.0, // Update every 5 seconds
            target: self,
            selector: #selector(updateStatusBar),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func stopStatusUpdates() {
        statusUpdateTimer?.invalidate()
        statusUpdateTimer = nil
    }
    
    @objc private func updateStatusBar() {
        // Animate the transition
        UIView.transition(with: statusLabel, duration: 0.5, options: .transitionCrossDissolve, animations: {
            self.statusLabel.text = self.friendStatuses[self.currentStatusIndex]
        }, completion: nil)
        
        // Increment index and wrap around if needed
        currentStatusIndex = (currentStatusIndex + 1) % friendStatuses.count
    }
    
    // MARK: - Spin Lock Timer
    private func lockSpinUntil(_ unlockTime: Date, message: String? = nil) {
        // Calculate seconds until unlock time
        remainingLockTime = unlockTime.timeIntervalSince(Date())
        
        // Lock spin button
        isSpinLocked = true
        spinButton.isEnabled = false
        spinButton.backgroundColor = .systemGray3
        
        if let message = message {
            spinButton.setTitle(message, for: .normal)
        }
        
        // Start timer
        updateLockTimerDisplay()
        spinLockTimer = Timer.scheduledTimer(
            timeInterval: 1.0,
            target: self,
            selector: #selector(updateLockTimer),
            userInfo: nil,
            repeats: true
        )
    }
    
    private func lockSpinUntilMidnight() {
        // Calculate time until midnight
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date())
        components.day! += 1  // Next day
        components.hour = 0   // Midnight
        components.minute = 0
        components.second = 0
        
        guard let midnightDate = calendar.date(from: components) else { return }
        
        lockSpinUntil(midnightDate)
    }
    
    private func stopLockTimer() {
        spinLockTimer?.invalidate()
        spinLockTimer = nil
    }
    
    @objc private func updateLockTimer() {
        remainingLockTime -= 1.0
        
        if remainingLockTime <= 0 {
            // Unlock spin button
            isSpinLocked = false
            spinButton.isEnabled = true
            spinButton.backgroundColor = .systemBlue.withAlphaComponent(0.7)
            spinButton.setTitle("SPIN!", for: .normal)
            discountCodeView.isHidden = true
            stopLockTimer()
        } else {
            updateLockTimerDisplay()
        }
    }
    
    private func updateLockTimerDisplay() {
        let hours = Int(remainingLockTime) / 3600
        let minutes = (Int(remainingLockTime) % 3600) / 60
        let seconds = Int(remainingLockTime) % 60
        
        // Update the button title to show countdown
        spinButton.setTitle(String(format: "%02d:%02d:%02d", hours, minutes, seconds), for: .normal)
    }
    
    private func generateDiscountCode() -> String {
        return discountCodes.randomElement() ?? "MIDNIGHT25"
    }
    
    private func showDiscountCode(_ code: String) {
        discountCodeValueLabel.text = code
        discountCodeView.isHidden = false
    }
    
    // MARK: - Data Persistence
    private func saveSpinRecord() {
        let defaults = UserDefaults.standard
        let today = Calendar.current.startOfDay(for: Date())
        defaults.set(today, forKey: "lastSpinDate")
    }
    
    private func loadSpinRecord() {
        let defaults = UserDefaults.standard
        if let lastSpinDate = defaults.object(forKey: "lastSpinDate") as? Date {
            let today = Calendar.current.startOfDay(for: Date())
            hasSpunToday = Calendar.current.isDate(lastSpinDate, inSameDayAs: today)
        } else {
            hasSpunToday = false
        }
    }
    
    // Reset user data by clearing spin record
    private func resetUserData() {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: "lastSpinDate")
        hasSpunToday = false
        unlockSpin()
        resetButton.isHidden = false // Ensure button remains visible
        print("User data reset successfully")
    }
    
    @objc private func resetButtonTapped() {
        resetUserData()
    }
}

// MARK: - SpinWheelViewDelegate
extension WheelViewController: SpinWheelViewDelegate {
    func spinWheelDidSelectItem(_ item: String) {
        if let restaurant = restaurants.first(where: { $0.name == item }) {
            showRestaurantDetails(for: restaurant)
        }
    }
}

// MARK: - UICollectionViewDelegate & DataSource
extension WheelViewController: UICollectionViewDelegate, UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return friends.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "FriendCell", for: indexPath) as! FriendCell
        let friend = friends[indexPath.item]
        cell.configure(with: friend)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let friend = friends[indexPath.item]
        let alert = UIAlertController(
            title: "Invite \(friend.name)?",
            message: "Would you like to invite \(friend.name) to join your late-night snack?",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Invite", style: .default) { _ in
            // Simulate sending invitation
            print("Invitation sent to \(friend.name)")
        })
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(alert, animated: true)
    }
}

// MARK: - FriendCell
class FriendCell: UICollectionViewCell {
    private let avatarImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemBlue
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    private let nameLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 12)
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let onlineIndicator: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGreen
        view.layer.cornerRadius = 4
        view.translatesAutoresizingMaskIntoConstraints = false
        return view
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(avatarImageView)
        contentView.addSubview(nameLabel)
        contentView.addSubview(onlineIndicator)
        
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: contentView.topAnchor),
            avatarImageView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),
            avatarImageView.widthAnchor.constraint(equalToConstant: 40),
            avatarImageView.heightAnchor.constraint(equalToConstant: 40),
            
            nameLabel.topAnchor.constraint(equalTo: avatarImageView.bottomAnchor, constant: 4),
            nameLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            nameLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            
            onlineIndicator.topAnchor.constraint(equalTo: avatarImageView.topAnchor),
            onlineIndicator.trailingAnchor.constraint(equalTo: avatarImageView.trailingAnchor),
            onlineIndicator.widthAnchor.constraint(equalToConstant: 8),
            onlineIndicator.heightAnchor.constraint(equalToConstant: 8)
        ])
    }
    
    func configure(with friend: Friend) {
        avatarImageView.image = UIImage(systemName: friend.avatar)
        nameLabel.text = friend.name
        onlineIndicator.isHidden = !friend.isOnline
    }
}
