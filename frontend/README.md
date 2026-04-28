# Crisis Resource Allocation System

A clean, functional web app prototype for optimally allocating emergency resources to multiple crisis zones.

## Features

- **Crisis Zone Management**: Display 7 crisis zones with severity levels, affected people, and distance
- **Priority Scoring**: Automatic calculation using formula: `(Severity × People Affected) / (Distance × Resources Present + 1)`
- **Resource Allocation**: Intelligent allocation of ambulances, fire units, rescue teams, and hazmat teams
- **One-Click Allocation**: "Run Allocation" button sorts zones by priority and assigns resources
- **Real-time Statistics**: Track allocated vs. available resources
- **Clean UI**: Professional dashboard with solid colors, borders, and minimal design

## Project Structure

```
gdg_hackathon/
├── src/
│   ├── components/
│   │   ├── StatsSummary.jsx    # Stats display component
│   │   └── ZoneRow.jsx         # Table row component for zones
│   ├── App.jsx                  # Main application component
│   ├── data.js                  # Mock crisis zones and resources
│   ├── utils.js                 # Allocation logic and calculations
│   ├── main.jsx                 # React entry point
│   └── index.css                # Tailwind imports
├── index.html                   # HTML entry point
├── vite.config.js               # Vite configuration
├── tailwind.config.js           # Tailwind CSS configuration
├── postcss.config.js            # PostCSS configuration
├── package.json                 # Project dependencies
└── README.md                    # This file
```

## Tech Stack

- **React 18** - UI framework
- **Vite** - Build tool and dev server
- **Tailwind CSS** - Utility-first CSS framework
- **JavaScript ES6** - Core logic

## Installation & Running

1. Install dependencies:
```bash
npm install
```

2. Start development server:
```bash
npm run dev
```

3. Open browser to `http://localhost:5173`

## How It Works

1. **Initial View**: All 7 crisis zones displayed in a table with basic information
2. **Run Allocation**: Click "Run Allocation" button to:
   - Calculate priority scores for each zone
   - Sort zones by priority (highest first)
   - Allocate available resources optimally
   - Display allocation summary
3. **Resource Allocation Logic**:
   - Ambulances: Allocated based on number of affected people
   - Fire Units: Prioritized for fire and explosion zones
   - Rescue Teams: Allocated to collapse and explosion zones
   - Hazmat Teams: Reserved for hazmat spills

## Allocation Algorithm

The system uses a greedy algorithm that:
1. Calculates priority scores for all zones
2. Sorts zones by priority (descending)
3. Iterates through sorted zones
4. Allocates available resources based on zone type and need
5. Tracks remaining resources

## UI Design Philosophy

- **No Gradients**: Solid colors only
- **Minimal Styling**: Borders instead of shadows
- **Professional Look**: Clean tables and simple layout
- **Clear Typography**: Inter font family
- **High Contrast**: Easy to read text on clean backgrounds

## Mock Data

The system includes 7 pre-configured crisis zones:
- Downtown Hospital Fire
- Highway Multi-vehicle Collision
- Industrial Building Explosion
- Residential Building Collapse
- Public Transport Accident
- Hazmat Chemical Spill
- Warehouse Fire

## Available Resources

- 12 Ambulances
- 8 Fire Units
- 5 Rescue Teams
- 2 Hazmat Teams

## Future Enhancements

- Real map integration with actual coordinates
- Dijkstra's algorithm for true shortest path calculation
- Live data feed from emergency services
- Multi-user allocation coordination
- Resource utilization analytics
