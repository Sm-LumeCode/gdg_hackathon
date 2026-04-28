## Quick Start Guide

### Setup (Run these commands in your terminal)

```bash
# Navigate to project
cd d:\gdg_hackathon

# Install dependencies
npm install

# Start development server
npm run dev
```

The app will automatically open in your browser at `http://localhost:5173`

### Using the Application

1. **View Crisis Zones**: See all 7 crisis zones with severity, affected people, and distance
2. **Click "Run Allocation"**: Algorithm calculates priority scores and allocates resources
3. **Check Results**: See allocated resources in the table and statistics at top
4. **Reset**: Click "Reset" button to start over

### What You'll See

- **Dashboard Header**: Clean title bar with action buttons
- **Stats Cards**: Real-time resource allocation metrics (when allocated)
- **Main Table**: 
  - Zone details (name, severity, people affected, distance)
  - Priority score (calculated in real-time)
  - Allocated resources per zone
- **Info Section**: Explains priority scoring formula

### Key Features

✓ Priority calculation: (Severity × People Affected) / (Distance × Resources Present + 1)
✓ Smart resource allocation based on zone type
✓ Real-time statistics and tracking
✓ One-click allocation
✓ Clean, professional UI with solid colors and borders

### Customization

To modify data, edit `src/data.js`:
- Add/remove zones
- Change available resources
- Modify zone characteristics

To adjust allocation logic, edit `src/utils.js`:
- Change priority formula
- Modify allocation strategies
- Add new resource types
