import React, { useState } from 'react';
import { LayoutDashboard, AlertTriangle, Briefcase, Route } from 'lucide-react';
import { mockCrisisZones, availableResources } from './data';
import { allocateResources } from './utils';

import ZoneMonitoringDashboard from './components/ZoneMonitoringDashboard';
import PriorityDecisionDashboard from './components/PriorityDecisionDashboard';
import ResourceAllocationDashboard from './components/ResourceAllocationDashboard';
import RoutingPathDashboard from './components/RoutingPathDashboard';

export default function App() {
  const [activeTab, setActiveTab] = useState('monitoring');
  const [zones, setZones] = useState(mockCrisisZones);
  const [allocation, setAllocation] = useState(null);
  const [isAllocated, setIsAllocated] = useState(false);
  const [remainingResources, setRemainingResources] = useState(availableResources);

  const handleRunAllocation = () => {
    const { allocation: newAllocation, sortedZones } = allocateResources(zones, availableResources);
    setAllocation(newAllocation);
    setZones(sortedZones);
    setIsAllocated(true);

    const remaining = { ...availableResources };
    Object.values(newAllocation).forEach(alloc => {
      remaining.ambulances -= alloc.ambulances;
      remaining.fireUnits -= alloc.fireUnits;
      remaining.rescueTeams -= alloc.rescueTeams;
      remaining.hazmatTeams -= alloc.hazmatTeams;
    });
    setRemainingResources(remaining);
    
    // Switch to Resource Allocation Dashboard after running
    setActiveTab('allocation');
  };

  const navItems = [
    { id: 'monitoring', label: 'Zone Monitoring', icon: AlertTriangle },
    { id: 'priority', label: 'Priority & Decision', icon: LayoutDashboard },
    { id: 'allocation', label: 'Resource Allocation', icon: Briefcase },
    { id: 'routing', label: 'Routing & Path', icon: Route },
  ];

  return (
    <div className="flex h-screen bg-white text-gray-900 font-sans">
      {/* Sidebar */}
      <div className="w-64 bg-gray-50 border-r border-gray-200 flex flex-col">
        <div className="p-6 border-b border-gray-200">
          <h1 className="text-lg font-bold text-black leading-tight">Adaptive Crisis Resource Allocation</h1>
        </div>
        <nav className="flex-1 p-4 space-y-1">
          {navItems.map((item) => {
            const Icon = item.icon;
            const isActive = activeTab === item.id;
            return (
              <button
                key={item.id}
                onClick={() => setActiveTab(item.id)}
                className={`w-full flex items-center gap-3 px-4 py-3 text-sm font-medium transition-colors border ${
                  isActive 
                    ? 'bg-blue-50 text-blue-700 border-blue-200' 
                    : 'bg-transparent text-gray-600 border-transparent hover:bg-gray-100'
                }`}
              >
                <Icon size={18} className={isActive ? 'text-blue-600' : 'text-gray-500'} />
                {item.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Main Content */}
      <div className="flex-1 flex flex-col overflow-hidden">
        {/* Top Header */}
        <header className="bg-white border-b border-gray-200 p-6 flex justify-between items-center">
          <h2 className="text-xl font-bold text-black">
            {navItems.find(item => item.id === activeTab)?.label}
          </h2>
          <div className="text-sm text-gray-500 border border-gray-200 px-3 py-1 bg-gray-50">
            System Status: <span className="font-bold text-green-600">Online</span>
          </div>
        </header>

        {/* Dashboard Area */}
        <main className="flex-1 overflow-y-auto p-6 bg-gray-50">
          <div className="max-w-6xl mx-auto">
            {activeTab === 'monitoring' && (
              <ZoneMonitoringDashboard zones={zones} setZones={setZones} />
            )}
            {activeTab === 'priority' && (
              <PriorityDecisionDashboard 
                zones={zones} 
                onRunAllocation={handleRunAllocation} 
                isAllocated={isAllocated}
              />
            )}
            {activeTab === 'allocation' && (
              <ResourceAllocationDashboard 
                zones={zones}
                allocation={allocation}
                availableResources={availableResources}
                remainingResources={remainingResources}
                isAllocated={isAllocated}
              />
            )}
            {activeTab === 'routing' && (
              <RoutingPathDashboard zones={zones} />
            )}
          </div>
        </main>
      </div>
    </div>
  );
}
