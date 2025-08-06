# Product Mission

> Last Updated: 2025-08-02
> Version: 1.0.0

## Pitch

AWSCostMonitor is a lightweight macOS menu bar application that helps AWS users keep a constant handle on their cloud spending by providing real-time month-to-date cost visibility and intelligent alerting based on configurable budgets.

## Users

### Primary Customers

- **Individual Developers**: Developers managing personal AWS accounts who need cost visibility
- **Small Teams**: Small engineering teams without dedicated FinOps tooling
- **DevOps Engineers**: Engineers responsible for monitoring and optimizing cloud costs

### User Personas

**Solo Developer** (25-45 years old)
- **Role:** Independent Developer / Freelancer
- **Context:** Manages multiple AWS accounts for different clients
- **Pain Points:** Unexpected AWS bills, switching between AWS console tabs, no real-time visibility
- **Goals:** Stay within budget, avoid bill shock, quick cost checks without leaving workflow

**Engineering Team Lead** (30-50 years old)
- **Role:** Engineering Manager / Tech Lead
- **Context:** Responsible for team's AWS spending across multiple environments
- **Pain Points:** Manual cost checking, delayed cost awareness, no proactive alerts
- **Goals:** Keep team within monthly budget, identify cost anomalies quickly

## The Problem

### Real-time Cost Visibility

AWS users often discover cost overruns only when the monthly bill arrives, leading to budget surprises and financial stress. Current solutions require logging into the AWS console and navigating multiple screens.

**Our Solution:** Always-visible menu bar display shows MTD spending at a glance.

### Multi-Profile Management

Developers managing multiple AWS accounts must repeatedly switch contexts in the AWS console to check costs across different profiles. This friction leads to less frequent monitoring.

**Our Solution:** Quick profile switching with persistent selection and per-profile configuration.

### Proactive Cost Management

Without automated monitoring, users rely on manual checks which often happen too late to prevent overages. Setting up CloudWatch alarms is complex and still requires console access.

**Our Solution:** Configurable budgets with visual indicators and forecast-based alerting.

## Differentiators

### Native macOS Experience

Unlike web-based solutions or electron apps, we provide a truly native macOS experience with minimal resource usage. This results in instant access, zero login friction, and seamless integration with the macOS workflow.

### Smart API Usage

We implement intelligent polling with per-profile budget-based frequency adjustment and hard limits on API calls. This results in cost-effective monitoring that respects AWS API limits while providing timely updates.

### Privacy-First Design

All data stays local on the user's machine with no external services or telemetry. This results in complete data privacy and no additional security concerns.

## Key Features

### Core Features

- **Menu Bar Cost Display:** Always-visible MTD spending in the macOS menu bar
- **Multi-Profile Support:** Switch between AWS profiles with persistent selection
- **Cost Comparison:** Visual indicators comparing current vs. previous month spending
- **Spending Forecast:** Predictive end-of-month cost projections
- **Quick AWS Console Access:** Direct links to AWS billing console from menu

### Configuration Features

- **Customizable Display:** Configure data format and refresh intervals
- **Per-Profile Budgets:** Set monthly budgets for intelligent refresh rates
- **API Request Tracking:** Monitor API usage per profile
- **Persistent Settings:** All configurations saved locally

### Safety Features

- **API Rate Limiting:** Hard limit of one request per minute with escape hatch
- **Comprehensive Logging:** Detailed activity logging for troubleshooting
- **Help Documentation:** Built-in help screen for user guidance