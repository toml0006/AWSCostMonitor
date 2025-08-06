import SwiftUI

struct ExportView: View {
    @EnvironmentObject var awsManager: AWSManager
    @Environment(\.dismiss) var dismiss
    
    @State private var selectedFormat: ExportFormat = .csv
    @State private var includeServiceBreakdown = false
    @State private var includeHistoricalData = false
    @State private var includeProjections = false
    @State private var selectedDateRange: ExportConfiguration.DateRange = .currentMonth
    @State private var isExporting = false
    @State private var showingError = false
    @State private var errorMessage = ""
    
    private let exporter: DataExporter
    
    init(awsManager: AWSManager) {
        self.exporter = DataExporter(awsManager: awsManager)
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(alignment: .leading, spacing: 8) {
                Text("Export Cost Data")
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text("Export your AWS cost data in various formats for analysis or record keeping")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color(NSColor.controlBackgroundColor))
            
            Divider()
            
            // Options
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    // Format selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Export Format")
                            .font(.headline)
                        
                        Picker("Format", selection: $selectedFormat) {
                            ForEach(ExportFormat.allCases, id: \.self) { format in
                                Text(format.rawValue).tag(format)
                            }
                        }
                        .pickerStyle(.radioGroup)
                        
                        Text(formatDescription)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Divider()
                    
                    // Date range selection
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Date Range")
                            .font(.headline)
                        
                        Picker("Date Range", selection: $selectedDateRange) {
                            Text("Current Month").tag(ExportConfiguration.DateRange.currentMonth)
                            Text("Last Month").tag(ExportConfiguration.DateRange.lastMonth)
                            Text("Last 3 Months").tag(ExportConfiguration.DateRange.last3Months)
                            Text("Last 6 Months").tag(ExportConfiguration.DateRange.last6Months)
                        }
                        .pickerStyle(.menu)
                        .frame(width: 200)
                    }
                    
                    Divider()
                    
                    // Include options
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Include in Export")
                            .font(.headline)
                        
                        Toggle("Service breakdown", isOn: $includeServiceBreakdown)
                            .disabled(awsManager.serviceCosts.isEmpty)
                        
                        if awsManager.serviceCosts.isEmpty {
                            Text("Load service breakdown first to include it")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                        
                        Toggle("Historical data", isOn: $includeHistoricalData)
                            .disabled(awsManager.historicalData.isEmpty)
                        
                        if awsManager.historicalData.isEmpty {
                            Text("No historical data available")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                        
                        Toggle("Monthly projections", isOn: $includeProjections)
                            .disabled(awsManager.projectedMonthlyTotal == nil)
                        
                        if awsManager.projectedMonthlyTotal == nil {
                            Text("Projections not available for current month")
                                .font(.caption)
                                .foregroundColor(.secondary)
                                .padding(.leading, 20)
                        }
                    }
                    
                    // Preview section
                    if hasDataToExport {
                        Divider()
                        
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Export Preview")
                                .font(.headline)
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Label("Current cost data for \(profileCount) profile(s)", systemImage: "checkmark.circle.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                                
                                if includeServiceBreakdown && !awsManager.serviceCosts.isEmpty {
                                    Label("\(awsManager.serviceCosts.count) services", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                if includeHistoricalData && !awsManager.historicalData.isEmpty {
                                    Label("\(historicalDataCount) historical data points", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                                
                                if includeProjections && awsManager.projectedMonthlyTotal != nil {
                                    Label("Monthly projections", systemImage: "checkmark.circle.fill")
                                        .font(.caption)
                                        .foregroundColor(.green)
                                }
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .cornerRadius(8)
                        }
                    }
                }
                .padding()
            }
            
            Divider()
            
            // Actions
            HStack {
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.escape)
                
                Spacer()
                
                Button("Export") {
                    performExport()
                }
                .keyboardShortcut(.return)
                .disabled(!hasDataToExport || isExporting)
            }
            .padding()
        }
        .frame(width: 500, height: 600)
        .alert("Export Error", isPresented: $showingError) {
            Button("OK") { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private var formatDescription: String {
        switch selectedFormat {
        case .csv:
            return "Comma-separated values format, compatible with Excel and other spreadsheet applications"
        case .json:
            return "JavaScript Object Notation format, ideal for programmatic analysis and data processing"
        }
    }
    
    private var hasDataToExport: Bool {
        !awsManager.costData.isEmpty
    }
    
    private var profileCount: Int {
        awsManager.costData.count
    }
    
    private var historicalDataCount: Int {
        // Count based on selected date range
        return exporter.getHistoricalDataForRange(selectedDateRange).count
    }
    
    private func performExport() {
        isExporting = true
        
        let configuration = ExportConfiguration(
            includeServiceBreakdown: includeServiceBreakdown,
            includeHistoricalData: includeHistoricalData,
            includeProjections: includeProjections,
            dateRange: selectedDateRange
        )
        
        Task {
            if let tempURL = await exporter.exportData(format: selectedFormat, configuration: configuration) {
                await MainActor.run {
                    isExporting = false
                    dismiss()
                    
                    // Show save dialog
                    exporter.saveExportedFile(from: tempURL, format: selectedFormat)
                }
            } else {
                await MainActor.run {
                    isExporting = false
                    errorMessage = "Failed to generate export file"
                    showingError = true
                }
            }
        }
    }
}


#Preview {
    ExportView(awsManager: AWSManager())
        .environmentObject(AWSManager())
}