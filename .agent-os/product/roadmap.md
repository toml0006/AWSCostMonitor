# Product Roadmap

> Last Updated: 2025-08-11
> Version: 1.2.0
> Status: Active Development

## Phase 0: Already Completed (v1.0.0 - v1.2.0)

The following features have been implemented:

### Core Menu Bar Features (v1.0.0)
- [x] **Menu Bar Application** - Basic SwiftUI menu bar app with dollar sign icon `XS`
- [x] **AWS Profile Loading** - Parse and load profiles from ~/.aws/config `S`
- [x] **Profile Selection** - Dropdown picker to select active AWS profile `S`
- [x] **MTD Cost Display** - Fetch and display month-to-date spending `M`
- [x] **Profile Persistence** - Remember last selected profile in UserDefaults `XS`
- [x] **Basic Error Handling** - Display errors when API calls fail `S`
- [x] **Manual Refresh** - Button to manually refresh cost data `XS`

### Calendar View & Visualizations (v1.2.0)
- [x] **Calendar View** - Monthly calendar with color-coded daily spending `L`
- [x] **Interactive Donut Charts** - Service breakdown with hover effects `M`
- [x] **Day Detail View** - Click any day for detailed cost breakdown `M`
- [x] **Service Histogram View** - Visual service cost analysis `M`
- [x] **Real Histogram View** - Temporal spending trends `M`
- [x] **Keyboard Shortcuts** - ⌘K for calendar, ⌘R refresh, ⌘1-9 profiles `S`
- [x] **MVC Architecture** - Refactored with Controllers, Models, Utilities `L`
- [x] **Debug Timer Controls** - Testing tools for refresh functionality `S`

## Phase 1: Enhanced Display & Configuration (Next Priority)

**Goal:** Improve the display flexibility and add persistent configuration
**Success Criteria:** Users can customize what they see and settings persist across app restarts

### Must-Have Features

- [ ] **Configurable Menu Bar Display** - Options for data format (full/abbreviated/icon-only) `M`
- [ ] **Settings Window** - Preferences UI for all configuration options `M`
- [ ] **Persistent Configuration** - Save all user preferences to disk `S`
- [ ] **Display Format Options** - Currency symbols, decimal places, abbreviations `S`

### Should-Have Features

- [x] **Keyboard Shortcuts** - Quick actions for refresh and profile switching `S` ✅ v1.2.0
- [ ] **Status Indicators** - Visual cues for loading/error states in menu bar `S`

### Dependencies

- SwiftUI Settings scene
- Enhanced UserDefaults or plist storage

## Phase 2: Optimized API Usage & Smart Refresh (3 weeks)

**Goal:** Maximize data extraction from single API calls with intelligent caching and refresh
**Success Criteria:** Extract 10+ data points per call while respecting rate limits and minimizing costs

### Must-Have Features

- [ ] **Single-Call Data Strategy** - Get MTD, daily breakdown, and service costs in one GetCostAndUsage call `L`
- [ ] **Intelligent Caching** - 15-60 minute cache based on budget proximity `M`
- [ ] **Per-Profile Budgets** - Set monthly spending limits per AWS profile `M`
- [ ] **Smart Refresh Logic** - Adjust polling frequency based on budget usage and cache `L`
- [ ] **API Rate Limiting** - Hard limit of 1 request/minute with circuit breaker `M`

### Should-Have Features

- [ ] **Cache Status Display** - Show data freshness and next refresh time `S`
- [ ] **Manual Override** - Force refresh with rate limit warning and cache bypass `S`
- [ ] **API Cost Tracking** - Display estimated monthly API costs ($0.01/call) `S`

### API Optimization Details

**Single Call Retrieves:**
- Current month daily costs (DAILY granularity)
- Service-level breakdown (GroupBy: SERVICE)
- AmortizedCost metric
- All data needed for forecasting and trends

**Cache Strategy:**
- In-memory cache with optional disk persistence
- Cache key: Profile + Date + Granularity
- Invalidation on profile switch or manual refresh
- Budget-based duration (far from budget = longer cache)

### Dependencies

- GetCostAndUsage API implementation
- Cache management system
- Timer/scheduling with circuit breaker

## Phase 3: Cost Intelligence from Single API Call (2 weeks)

**Goal:** Extract maximum insights from the optimized single API call data
**Success Criteria:** Provide 10+ metrics and insights without additional API calls

### Must-Have Features

- [x] **MTD Analytics** - Total, daily average, burn rate from cached data `S` ✅ v1.2.0
- [ ] **Spending Forecast** - Project month-end using daily trend data `M`
- [x] **Service Breakdown** - Display top 5 services by cost from GroupBy data `M` ✅ v1.2.0
- [x] **Daily Trend Graph** - Visualize daily spending pattern `M` ✅ v1.2.0
- [ ] **Budget Progress** - Show % budget vs % month elapsed `S`

### Should-Have Features

- [ ] **Anomaly Detection** - Flag days with >2x average spending `M`
- [ ] **Week-over-Week** - Compare current week to previous `S`
- [ ] **Weekend vs Weekday** - Identify usage patterns `S`
- [ ] **Top Expensive Days** - Highlight cost spike dates `S`
- [ ] **Velocity Indicator** - Show if spending is accelerating/decelerating `M`

### Data Extracted from Single Call

**From Daily Granularity + Service GroupBy:**
1. MTD total (sum all days)
2. Daily spending array
3. Per-service costs
4. Average daily burn rate
5. Spending velocity/acceleration
6. Forecast (daily avg × days in month)
7. Budget consumption rate
8. Cost anomalies/spikes
9. Week-over-week changes
10. Service cost rankings

### Dependencies

- Phase 2's single-call implementation
- Data visualization components
- Statistical calculation utilities

## Phase 4: Observability & Help (1 week) ✅

**Goal:** Add comprehensive logging and user assistance
**Success Criteria:** Users can troubleshoot issues and understand all features

### Must-Have Features

- [x] **Comprehensive Logging** - Log all API calls, errors, and key events `M`
- [x] **API Request Counter** - Track and display requests per profile `S`
- [x] **Help Documentation** - Built-in help screen with feature explanations `M`
- [x] **AWS Console Links** - Quick access to billing console per profile `S`

### Should-Have Features

- [x] **Debug Mode** - Verbose logging option for troubleshooting `S`
- [x] **Export Logs** - Save logs to file for support `S`

### Dependencies

- Logging framework integration
- Help UI components

## Phase 5: Monetization & Licensing (2 weeks)

**Goal:** Implement one-time purchase model with trial period
**Success Criteria:** Smooth upgrade flow from trial to paid with clear feature differentiation

### Must-Have Features

- [ ] **Trial System** - 14-day full-featured trial with countdown `M`
- [ ] **License Key Validation** - Secure local validation using cryptographic signatures `M`
- [ ] **Feature Gating** - Lock premium features after trial expires `M`
- [ ] **Keychain Storage** - Store license securely in macOS Keychain `S`
- [ ] **Purchase Flow** - In-app upgrade button linking to payment processor `S`

### Should-Have Features

- [ ] **Trial Reminders** - Gentle notifications at day 7, 10, 13 `S`
- [ ] **License Transfer** - Allow moving license between machines `M`
- [ ] **Offline Validation** - No internet required after activation `S`

### Dependencies

- Payment processor account (Paddle/Gumroad/LemonSqueezy)
- License key generation API
- Cryptographic validation library

### Free vs Pro Features

**Free Features (After Trial):**
- Single AWS profile
- Basic MTD cost display  
- Manual refresh
- Basic error handling

**Pro Features ($29 one-time):**
- Unlimited AWS profiles
- Smart refresh with budgets
- Cost forecasting & trends
- Historical data & comparisons
- Cost breakdown by service
- Export functionality
- Keyboard shortcuts
- Custom display formats

## Phase 6: Advanced Features (3 weeks)

**Goal:** Power user features and enhanced integration
**Success Criteria:** Advanced users have powerful tools for cost management

### Must-Have Features

- [ ] **Multi-Profile Dashboard** - View all profiles' costs simultaneously `L`
- [ ] **Cost Alerts** - Configurable notifications for budget thresholds `M`
- [ ] **Data Export** - Export cost data to CSV/JSON `M`

### Should-Have Features

- [ ] **Spotlight Integration** - Quick cost check via Spotlight `L`
- [ ] **Today Widget** - Show costs in Notification Center `XL`
- [ ] **CloudWatch Integration** - Pull custom metrics `L`

### Dependencies

- Notification permissions
- Advanced macOS integrations