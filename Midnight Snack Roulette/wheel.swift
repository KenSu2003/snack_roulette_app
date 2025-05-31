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
    
    // MARK: - UI Components
    private lazy var countdownLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
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
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        checkTimeAndInitialize()
        loadRestaurantData()
        loadSimulatedFriends()
        startStatusUpdates()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        stopStatusUpdates()
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Setup status bar
        statusBarView.addSubview(statusIconImageView)
        statusBarView.addSubview(statusLabel)
        
        // Add subviews
        view.addSubview(countdownLabel)
        view.addSubview(statusBarView)
        view.addSubview(friendsCollectionView)
        view.addSubview(spinWheelView)
        view.addSubview(spinButton)
        
        // Setup constraints
        NSLayoutConstraint.activate([
            countdownLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            countdownLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            
            // Status bar constraints
            statusBarView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
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
            
            friendsCollectionView.topAnchor.constraint(equalTo: statusBarView.bottomAnchor, constant: 20),
            friendsCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            friendsCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            friendsCollectionView.heightAnchor.constraint(equalToConstant: 80),
            
            spinWheelView.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinWheelView.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            spinWheelView.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.8),
            spinWheelView.heightAnchor.constraint(equalTo: spinWheelView.widthAnchor),
            
            spinButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            spinButton.topAnchor.constraint(equalTo: spinWheelView.bottomAnchor, constant: 30),
            spinButton.widthAnchor.constraint(equalToConstant: 200),
            spinButton.heightAnchor.constraint(equalToConstant: 50)
        ])
        
        // Initially hide interactive elements
        countdownLabel.isHidden = true
        statusBarView.isHidden = true
        friendsCollectionView.isHidden = true
        spinWheelView.isHidden = true
        spinButton.isHidden = true
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
        
        // Setup spin wheel with restaurant names
        let restaurantNames = restaurants.map { $0.name }
        spinWheelView.setItems(restaurantNames)
    }
    
    // MARK: - Actions
    @objc private func spinButtonTapped() {
        print("Spinning with items: \(restaurants.map { $0.name })")
        spinWheelView.spin()
    }
    
    // MARK: - Restaurant Details
    private func showRestaurantDetails(for restaurant: Restaurant) {
        let alert = UIAlertController(
            title: restaurant.name,
            message: """
                \(restaurant.discount)
                Cuisine: \(restaurant.cuisine)
                Rating: \(restaurant.rating)
                Open until: \(restaurant.openUntil)
                Address: \(restaurant.address)
                """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Navigate", style: .default) { [weak self] _ in
            self?.openInMaps(restaurant: restaurant)
        })
        
        alert.addAction(UIAlertAction(title: "Share", style: .default) { [weak self] _ in
            self?.shareRestaurant(restaurant: restaurant)
        })
        
        alert.addAction(UIAlertAction(title: "Spin Again", style: .default) { [weak self] _ in
            self?.spinWheelView.spin()
        })
        
        alert.addAction(UIAlertAction(title: "Close", style: .cancel))
        
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
    
    private func shareRestaurant(restaurant: Restaurant) {
        let text = """
            Check out \(restaurant.name)!
            \(restaurant.discount)
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
