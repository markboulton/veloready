import SwiftUI
import Combine

/// ViewModel for CaloriesCardV2
/// Handles calorie goal, progress, and badge logic
@MainActor
class CaloriesCardViewModel: ObservableObject {
    // MARK: - Published Properties
    
    @Published private(set) var activeCalories: Double = 0
    @Published private(set) var bmrCalories: Double = 0
    @Published private(set) var calorieGoal: Double = 2000
    @Published private(set) var useBMRAsGoal: Bool = false
    
    // MARK: - Dependencies
    
    private let liveActivityService: LiveActivityService
    private let userSettings: UserSettings
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Initialization
    
    init(
        liveActivityService: LiveActivityService = .shared,
        userSettings: UserSettings = .shared
    ) {
        self.liveActivityService = liveActivityService
        self.userSettings = userSettings
        
        setupObservers()
        refreshData()
    }
    
    // MARK: - Setup
    
    private func setupObservers() {
        // Observe active calories
        liveActivityService.$activeCalories
            .sink { [weak self] calories in
                self?.activeCalories = calories
            }
            .store(in: &cancellables)
        
        // Observe BMR calories
        liveActivityService.$bmrCalories
            .sink { [weak self] bmr in
                self?.bmrCalories = bmr
            }
            .store(in: &cancellables)
        
        // Observe calorie goal
        userSettings.$calorieGoal
            .sink { [weak self] goal in
                self?.calorieGoal = goal
            }
            .store(in: &cancellables)
        
        // Observe BMR goal setting
        userSettings.$useBMRAsGoal
            .sink { [weak self] useBMR in
                self?.useBMRAsGoal = useBMR
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public Methods
    
    func refreshData() {
        activeCalories = liveActivityService.activeCalories
        bmrCalories = liveActivityService.bmrCalories
        calorieGoal = userSettings.calorieGoal
        useBMRAsGoal = userSettings.useBMRAsGoal
    }
    
    // MARK: - Computed Properties
    
    var effectiveGoal: Double {
        useBMRAsGoal ? bmrCalories : calorieGoal
    }
    
    var totalCalories: Double {
        bmrCalories + activeCalories
    }
    
    var progress: Double {
        guard effectiveGoal > 0 else { return 0 }
        // Compare active calories against goal, not total
        // BMR is baseline metabolism, only active calories count toward goal
        return min(activeCalories / effectiveGoal, 1.0)
    }
    
    var progressPercentage: String {
        String(format: "%.0f%% of goal", progress * 100)
    }
    
    var formattedTotal: String {
        "\(Int(totalCalories))"
    }
    
    var formattedGoal: String {
        "\(Int(effectiveGoal))"
    }
    
    var formattedActive: String {
        "\(Int(activeCalories))"
    }
    
    var formattedBMR: String {
        "\(Int(bmrCalories))"
    }
    
    var badge: CardHeader.Badge? {
        // Compare active calories against goal, not total
        // BMR is baseline metabolism, only active calories count toward goal
        if activeCalories >= effectiveGoal {
            return .init(text: "GOAL MET", style: .success)
        } else if progress >= 0.8 {
            return .init(text: "CLOSE", style: .info)
        }
        return nil
    }
}
