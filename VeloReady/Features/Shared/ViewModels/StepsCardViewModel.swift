import SwiftUI
import Combine

/// ViewModel for StepsCardV2
/// Separates business logic from UI presentation
@MainActor
class StepsCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var dailySteps: Int = 0
    @Published private(set) var stepGoal: Int = 10000
    @Published private(set) var walkingDistance: Double = 0
    @Published private(set) var hourlySteps: [HourlyStepData] = []
    @Published private(set) var isLoadingHourly: Bool = false
    
    // MARK: - Dependencies
    
    private let liveActivityService: LiveActivityService
    private let userSettings: UserSettings
    private let healthKitManager: HealthKitManager
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        liveActivityService: LiveActivityService = .shared,
        userSettings: UserSettings = .shared,
        healthKitManager: HealthKitManager = .shared
    ) {
        self.liveActivityService = liveActivityService
        self.userSettings = userSettings
        self.healthKitManager = healthKitManager
        
        setupObservers()
        refreshData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe daily steps changes
        liveActivityService.$dailySteps
            .sink { [weak self] steps in
                self?.dailySteps = steps
            }
            .store(in: &cancellables)
        
        // Observe walking distance changes
        liveActivityService.$walkingDistance
            .sink { [weak self] distance in
                self?.walkingDistance = distance
            }
            .store(in: &cancellables)
        
        // Observe step goal changes
        userSettings.$stepGoal
            .sink { [weak self] goal in
                self?.stepGoal = goal
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        dailySteps = liveActivityService.dailySteps
        stepGoal = userSettings.stepGoal
        walkingDistance = liveActivityService.walkingDistance
    }
    
    func loadHourlySteps() async {
        isLoadingHourly = true
        Logger.debug("📊 [SPARKLINE] StepsCardViewModel: Loading hourly steps...")
        
        let steps = await healthKitManager.fetchTodayHourlySteps()
        Logger.debug("📊 [SPARKLINE] StepsCardViewModel: Fetched \(steps.count) hours of data")
        
        var hourlyData: [HourlyStepData] = []
        for (hour, stepCount) in steps.enumerated() {
            hourlyData.append(HourlyStepData(hour: hour, steps: stepCount))
        }
        
        self.hourlySteps = hourlyData
        self.isLoadingHourly = false
        Logger.debug("📊 [SPARKLINE] StepsCardViewModel: Set hourlySteps count: \(self.hourlySteps.count)")
    }
    
    // MARK: - Computed Properties
    
    var progressPercentage: Int {
        guard stepGoal > 0 else { return 0 }
        return Int((Double(dailySteps) / Double(stepGoal)) * 100)
    }
    
    var formattedProgress: String {
        "\(progressPercentage)% of goal"
    }
    
    var formattedSteps: String {
        formatSteps(dailySteps)
    }
    
    var formattedGoal: String {
        "\(formatSteps(stepGoal)) goal"
    }
    
    var formattedDistance: String {
        formatDistance(walkingDistance)
    }
    
    var hasDistance: Bool {
        walkingDistance > 0
    }
    
    var hasHourlyData: Bool {
        !hourlySteps.isEmpty
    }
    
    // MARK: - Private Helpers
    
    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.groupingSeparator = ","
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }
    
    private func formatDistance(_ kilometers: Double) -> String {
        if userSettings.useMetricUnits {
            return String(format: "%.1f %@", kilometers, CommonContent.Units.kilometers)
        } else {
            let miles = kilometers * 0.621371
            return String(format: "%.1f %@", miles, CommonContent.Units.miles)
        }
    }
}
