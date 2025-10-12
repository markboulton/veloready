import Foundation
import HealthKit

// MARK: - Codable HealthKit Wrappers

// Helper function to get appropriate unit for quantity type
private func getUnitForQuantityType(_ identifier: String) -> HKUnit {
    switch identifier {
    case HKQuantityTypeIdentifier.stepCount.rawValue:
        return HKUnit.count()
    case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue:
        return HKUnit.kilocalorie()
    case HKQuantityTypeIdentifier.heartRateVariabilitySDNN.rawValue:
        return HKUnit.secondUnit(with: .milli)
    case HKQuantityTypeIdentifier.restingHeartRate.rawValue, HKQuantityTypeIdentifier.heartRate.rawValue:
        return HKUnit.count().unitDivided(by: .minute())
    case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
        return HKUnit.meterUnit(with: .kilo)
    case HKQuantityTypeIdentifier.distanceCycling.rawValue:
        return HKUnit.meterUnit(with: .kilo)
    default:
        return HKUnit.count()
    }
}

/// Codable wrapper for HKQuantitySample
struct CodableHKQuantitySample: Codable {
    let startDate: Date
    let endDate: Date
    let quantityTypeIdentifier: String
    let quantityValue: Double
    let quantityUnit: String
    let sourceName: String?
    let sourceRevision: String?
    let device: String?
    let metadata: [String: String]?
    
    init(from sample: HKQuantitySample) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.quantityTypeIdentifier = sample.quantityType.identifier
        let unit = getUnitForQuantityType(sample.quantityType.identifier)
        self.quantityValue = sample.quantity.doubleValue(for: unit)
        self.quantityUnit = unit.unitString
        self.sourceName = sample.sourceRevision.source.name
        self.sourceRevision = sample.sourceRevision.version
        self.device = sample.device?.name
        self.metadata = sample.metadata as? [String: String]
    }
    
    // Custom coding keys for metadata
    private enum CodingKeys: String, CodingKey {
        case startDate, endDate, quantityTypeIdentifier, quantityValue, quantityUnit
        case sourceName, sourceRevision, device, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        quantityTypeIdentifier = try container.decode(String.self, forKey: .quantityTypeIdentifier)
        quantityValue = try container.decode(Double.self, forKey: .quantityValue)
        quantityUnit = try container.decode(String.self, forKey: .quantityUnit)
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        sourceRevision = try container.decodeIfPresent(String.self, forKey: .sourceRevision)
        device = try container.decodeIfPresent(String.self, forKey: .device)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(quantityTypeIdentifier, forKey: .quantityTypeIdentifier)
        try container.encode(quantityValue, forKey: .quantityValue)
        try container.encode(quantityUnit, forKey: .quantityUnit)
        try container.encodeIfPresent(sourceName, forKey: .sourceName)
        try container.encodeIfPresent(sourceRevision, forKey: .sourceRevision)
        try container.encodeIfPresent(device, forKey: .device)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}

/// Codable wrapper for HKCategorySample
struct CodableHKCategorySample: Codable {
    let startDate: Date
    let endDate: Date
    let categoryTypeIdentifier: String
    let categoryValue: Int
    let sourceName: String?
    let sourceRevision: String?
    let device: String?
    let metadata: [String: String]?
    
    init(from sample: HKCategorySample) {
        self.startDate = sample.startDate
        self.endDate = sample.endDate
        self.categoryTypeIdentifier = sample.categoryType.identifier
        self.categoryValue = sample.value
        self.sourceName = sample.sourceRevision.source.name
        self.sourceRevision = sample.sourceRevision.version
        self.device = sample.device?.name
        self.metadata = sample.metadata as? [String: String]
    }
    
    // Custom coding keys for metadata
    private enum CodingKeys: String, CodingKey {
        case startDate, endDate, categoryTypeIdentifier, categoryValue
        case sourceName, sourceRevision, device, metadata
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        startDate = try container.decode(Date.self, forKey: .startDate)
        endDate = try container.decode(Date.self, forKey: .endDate)
        categoryTypeIdentifier = try container.decode(String.self, forKey: .categoryTypeIdentifier)
        categoryValue = try container.decode(Int.self, forKey: .categoryValue)
        sourceName = try container.decodeIfPresent(String.self, forKey: .sourceName)
        sourceRevision = try container.decodeIfPresent(String.self, forKey: .sourceRevision)
        device = try container.decodeIfPresent(String.self, forKey: .device)
        metadata = try container.decodeIfPresent([String: String].self, forKey: .metadata)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(categoryTypeIdentifier, forKey: .categoryTypeIdentifier)
        try container.encode(categoryValue, forKey: .categoryValue)
        try container.encodeIfPresent(sourceName, forKey: .sourceName)
        try container.encodeIfPresent(sourceRevision, forKey: .sourceRevision)
        try container.encodeIfPresent(device, forKey: .device)
        try container.encodeIfPresent(metadata, forKey: .metadata)
    }
}
