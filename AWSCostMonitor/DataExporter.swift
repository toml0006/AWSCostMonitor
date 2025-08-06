import Foundation
import AppKit
import UniformTypeIdentifiers

// Data export formats
enum ExportFormat: String, CaseIterable {
    case csv = "CSV"
    case json = "JSON"
    
    var fileExtension: String {
        switch self {
        case .csv: return "csv"
        case .json: return "json"
        }
    }
    
    var contentType: UTType {
        switch self {
        case .csv: return .commaSeparatedText
        case .json: return .json
        }
    }
}

// Export configuration
struct ExportConfiguration {
    var includeServiceBreakdown: Bool = false
    var includeHistoricalData: Bool = false
    var includeProjections: Bool = false
    var dateRange: DateRange = .currentMonth
    
    enum DateRange: Hashable {
        case currentMonth
        case lastMonth
        case last3Months
        case last6Months
        case custom(start: Date, end: Date)
        
        var displayName: String {
            switch self {
            case .currentMonth: return "Current Month"
            case .lastMonth: return "Last Month"
            case .last3Months: return "Last 3 Months"
            case .last6Months: return "Last 6 Months"
            case .custom: return "Custom Range"
            }
        }
    }
}

class DataExporter: ObservableObject {
    private let awsManager: AWSManager
    
    init(awsManager: AWSManager) {
        self.awsManager = awsManager
    }
    
    // MARK: - Export Methods
    
    func exportData(format: ExportFormat, configuration: ExportConfiguration) async -> URL? {
        let data: Data?
        let filename: String
        
        switch format {
        case .csv:
            data = generateCSV(configuration: configuration)
            filename = generateFilename(format: .csv)
        case .json:
            data = generateJSON(configuration: configuration)
            filename = generateFilename(format: .json)
        }
        
        guard let data = data else {
            print("Failed to generate export data")
            return nil
        }
        
        // Save to temporary file first
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try data.write(to: tempURL)
            return tempURL
        } catch {
            print("Failed to write export file: \(error)")
            return nil
        }
    }
    
    func saveExportedFile(from tempURL: URL, format: ExportFormat) {
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = tempURL.lastPathComponent
        savePanel.allowedContentTypes = [format.contentType]
        savePanel.canCreateDirectories = true
        savePanel.isExtensionHidden = false
        savePanel.title = "Export AWS Cost Data"
        savePanel.message = "Choose where to save your cost data export"
        
        savePanel.begin { response in
            if response == .OK, let destinationURL = savePanel.url {
                do {
                    // Remove existing file if it exists
                    if FileManager.default.fileExists(atPath: destinationURL.path) {
                        try FileManager.default.removeItem(at: destinationURL)
                    }
                    
                    // Copy file to chosen location
                    try FileManager.default.copyItem(at: tempURL, to: destinationURL)
                    
                    // Clean up temp file
                    try? FileManager.default.removeItem(at: tempURL)
                    
                    // Show in Finder
                    NSWorkspace.shared.selectFile(destinationURL.path, inFileViewerRootedAtPath: "")
                    
                    self.awsManager.log(.info, category: "Export", "Data exported to: \(destinationURL.path)")
                } catch {
                    print("Failed to save export file: \(error)")
                    self.awsManager.log(.error, category: "Export", "Failed to save export: \(error)")
                }
            }
        }
    }
    
    // MARK: - CSV Generation
    
    private func generateCSV(configuration: ExportConfiguration) -> Data? {
        var csvString = ""
        
        // Get data based on configuration
        let costData = getCostDataForRange(configuration.dateRange)
        
        // Header row
        var headers = ["Date", "Profile", "Amount", "Currency"]
        if configuration.includeProjections {
            headers.append("Projected Monthly Total")
        }
        csvString += headers.joined(separator: ",") + "\n"
        
        // Current month data
        for cost in costData {
            var row = [
                formatDate(Date()),
                cost.profileName,
                String(format: "%.2f", NSDecimalNumber(decimal: cost.amount).doubleValue),
                cost.currency
            ]
            
            if configuration.includeProjections,
               let projection = awsManager.projectedMonthlyTotal {
                row.append(String(format: "%.2f", NSDecimalNumber(decimal: projection).doubleValue))
            } else if configuration.includeProjections {
                row.append("")
            }
            
            csvString += row.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
        }
        
        // Service breakdown if requested
        if configuration.includeServiceBreakdown && !awsManager.serviceCosts.isEmpty {
            csvString += "\n\nService Breakdown\n"
            csvString += "Service,Amount,Currency\n"
            
            for service in awsManager.serviceCosts {
                let row = [
                    service.serviceName,
                    String(format: "%.2f", NSDecimalNumber(decimal: service.amount).doubleValue),
                    service.currency
                ]
                csvString += row.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
            }
        }
        
        // Historical data if requested
        if configuration.includeHistoricalData {
            let historicalData = getHistoricalDataForRange(configuration.dateRange)
            
            if !historicalData.isEmpty {
                csvString += "\n\nHistorical Data\n"
                csvString += "Month,Profile,Amount,Currency,Complete\n"
                
                for historical in historicalData {
                    let row = [
                        formatMonthYear(historical.date),
                        historical.profileName,
                        String(format: "%.2f", NSDecimalNumber(decimal: historical.amount).doubleValue),
                        historical.currency,
                        historical.isComplete ? "Yes" : "No"
                    ]
                    csvString += row.map { escapeCSVField($0) }.joined(separator: ",") + "\n"
                }
            }
        }
        
        return csvString.data(using: .utf8)
    }
    
    // MARK: - JSON Generation
    
    private func generateJSON(configuration: ExportConfiguration) -> Data? {
        var exportData: [String: Any] = [:]
        
        // Metadata
        exportData["exportDate"] = ISO8601DateFormatter().string(from: Date())
        exportData["exportVersion"] = "1.0"
        
        // Current costs
        let costData = getCostDataForRange(configuration.dateRange)
        exportData["currentCosts"] = costData.map { cost in
            var costDict: [String: Any] = [
                "profileName": cost.profileName,
                "amount": NSDecimalNumber(decimal: cost.amount).doubleValue,
                "currency": cost.currency,
                "date": ISO8601DateFormatter().string(from: Date())
            ]
            
            if configuration.includeProjections,
               let projection = awsManager.projectedMonthlyTotal {
                costDict["projectedMonthlyTotal"] = NSDecimalNumber(decimal: projection).doubleValue
            }
            
            return costDict
        }
        
        // Service breakdown
        if configuration.includeServiceBreakdown && !awsManager.serviceCosts.isEmpty {
            exportData["serviceBreakdown"] = awsManager.serviceCosts.map { service in
                [
                    "serviceName": service.serviceName,
                    "amount": NSDecimalNumber(decimal: service.amount).doubleValue,
                    "currency": service.currency
                ]
            }
        }
        
        // Historical data
        if configuration.includeHistoricalData {
            let historicalData = getHistoricalDataForRange(configuration.dateRange)
            exportData["historicalData"] = historicalData.map { historical in
                [
                    "profileName": historical.profileName,
                    "date": ISO8601DateFormatter().string(from: historical.date),
                    "amount": NSDecimalNumber(decimal: historical.amount).doubleValue,
                    "currency": historical.currency,
                    "isComplete": historical.isComplete
                ]
            }
        }
        
        // Budget information
        if let profile = awsManager.selectedProfile {
            let budget = awsManager.getBudget(for: profile.name)
            let status = awsManager.calculateBudgetStatus(
                cost: costData.first?.amount ?? 0,
                budget: budget
            )
            
            exportData["budgetInfo"] = [
                "monthlyBudget": NSDecimalNumber(decimal: budget.monthlyBudget).doubleValue,
                "alertThreshold": budget.alertThreshold,
                "currentPercentage": status.percentage,
                "isOverBudget": status.isOverBudget,
                "isNearThreshold": status.isNearThreshold
            ]
        }
        
        // Trends
        exportData["costTrend"] = [
            "direction": awsManager.costTrend == .stable ? "stable" :
                        (awsManager.costTrend.description.contains("+") ? "up" : "down"),
            "description": awsManager.costTrend.description
        ]
        
        // Convert to JSON
        do {
            return try JSONSerialization.data(withJSONObject: exportData, options: .prettyPrinted)
        } catch {
            print("Failed to generate JSON: \(error)")
            return nil
        }
    }
    
    // MARK: - Helper Methods
    
    private func getCostDataForRange(_ range: ExportConfiguration.DateRange) -> [CostData] {
        // For now, return current cost data
        // In a full implementation, this would filter based on date range
        return awsManager.costData
    }
    
    func getHistoricalDataForRange(_ range: ExportConfiguration.DateRange) -> [HistoricalCostData] {
        let calendar = Calendar.current
        let now = Date()
        
        switch range {
        case .currentMonth:
            return awsManager.historicalData.filter {
                calendar.isDate($0.date, equalTo: now, toGranularity: .month)
            }
        case .lastMonth:
            let lastMonth = calendar.date(byAdding: .month, value: -1, to: now)!
            return awsManager.historicalData.filter {
                calendar.isDate($0.date, equalTo: lastMonth, toGranularity: .month)
            }
        case .last3Months:
            let threeMonthsAgo = calendar.date(byAdding: .month, value: -3, to: now)!
            return awsManager.historicalData.filter { $0.date >= threeMonthsAgo }
        case .last6Months:
            let sixMonthsAgo = calendar.date(byAdding: .month, value: -6, to: now)!
            return awsManager.historicalData.filter { $0.date >= sixMonthsAgo }
        case .custom(let start, let end):
            return awsManager.historicalData.filter { $0.date >= start && $0.date <= end }
        }
    }
    
    private func generateFilename(format: ExportFormat) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: Date())
        
        let profileName = awsManager.selectedProfile?.name ?? "all-profiles"
        
        return "aws-costs-\(profileName)-\(dateString).\(format.fileExtension)"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
    
    private func formatMonthYear(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: date)
    }
    
    private func escapeCSVField(_ field: String) -> String {
        if field.contains(",") || field.contains("\"") || field.contains("\n") {
            return "\"\(field.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return field
    }
}