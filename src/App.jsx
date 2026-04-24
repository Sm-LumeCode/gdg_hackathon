import React, { useState } from 'react';
import { LayoutDashboard, AlertTriangle, Briefcase, Route, Radio, Search, Bell, Settings, Activity, HelpCircle, LogOut } from 'lucide-react';
import { useCrisisContext } from './context/CrisisContext';

import ZoneMonitoringDashboard from './components/ZoneMonitoringDashboard';
import PriorityDecisionDashboard from './components/PriorityDecisionDashboard';
import ResourceAllocationDashboard from './components/ResourceAllocationDashboard';
import RoutingPathDashboard from './components/RoutingPathDashboard';

export default function App() {
  const [activeTab, setActiveTab] = useState('monitoring');
  const { searchQuery, setSearchQuery } = useCrisisContext();

  const navItems = [
    { id: 'monitoring', label: 'Dashboard',      icon: LayoutDashboard },
    { id: 'priority',   label: 'Priority',       icon: AlertTriangle },
    { id: 'allocation', label: 'Allocation',     icon: Briefcase },
    { id: 'routing',    label: 'Routing',        icon: Route },
  ];

  return (
    <div className="flex h-screen bg-[#182024] text-gray-300 font-sans overflow-hidden selection:bg-[#00d68f]/30">
      
      {/* Sidebar */}
      <aside className="w-64 bg-[#182024] flex flex-col shrink-0 z-20 border-r border-[#2a343a]/50">
        {/* Logo */}
        <div className="h-[72px] flex items-center px-6 shrink-0">
          <div className="flex items-center gap-3">
            <div className="text-[#00d68f]">
              <svg width="24" height="24" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                <path d="M4 4L10 20H14L8 4H4Z" fill="currentColor"/>
                <path d="M14 4L20 20H16L10 4H14Z" fill="currentColor"/>
              </svg>
            </div>
            <span className="text-lg font-bold text-white tracking-widest">COMMAND</span>
          </div>
        </div>

        {/* Navigation */}
        <nav className="flex-1 px-4 py-6 space-y-1 overflow-y-auto">
          {navItems.map(({ id, label, icon: Icon }) => {
            const active = activeTab === id;
            return (
              <button
                key={id}
                onClick={() => setActiveTab(id)}
                className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 outline-none ${
                  active 
                    ? 'bg-[#2a343a] text-white font-medium border-l-[3px] border-[#00d68f]' 
                    : 'text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent'
                }`}
              >
                <Icon size={18} className={active ? 'text-[#00d68f]' : 'text-gray-400'} />
                <span className="tracking-wide text-sm">{label}</span>
              </button>
            );
          })}

          <div className="pt-8 pb-2">
            <span className="px-4 text-xs font-semibold text-gray-500 uppercase tracking-wider">System</span>
          </div>
          
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent transition-all">
            <Settings size={18} />
            <span className="tracking-wide text-sm">Settings</span>
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent transition-all">
            <Activity size={18} />
            <span className="tracking-wide text-sm">Activity Log</span>
          </button>
          <button className="w-full flex items-center gap-3 px-4 py-3 rounded-lg text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent transition-all">
            <HelpCircle size={18} />
            <span className="tracking-wide text-sm">Help & Support</span>
          </button>
        </nav>

        {/* Footer */}
        <div className="p-4 px-8 pb-8 shrink-0">
          <button className="flex items-center gap-3 text-gray-500 hover:text-gray-300 transition-colors">
            <LogOut size={18} />
            <span className="tracking-wide text-sm">Log Out</span>
          </button>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#1c252a]">
        
        {/* Topbar */}
        <header className="h-[72px] flex items-center justify-between px-8 shrink-0">
          <div className="flex items-center gap-3 text-gray-400 hover:text-white transition-colors cursor-pointer">
            <div className="w-8 h-8 rounded-full bg-[#2a343a] flex items-center justify-center">
              <span className="text-xs">{'<'}</span>
            </div>
          </div>
          
          <div className="flex-1 max-w-xl mx-8 relative">
            <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-gray-500" size={16} />
            <input 
              type="text" 
              placeholder="Search zones..." 
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="w-full bg-[#182024] text-sm text-gray-200 border border-[#2a343a] rounded-full pl-10 pr-4 py-2 focus:outline-none focus:border-[#00d68f] transition-colors"
            />
          </div>

          <div className="flex items-center gap-5">
            <button className="relative text-gray-400 hover:text-white transition-colors">
              <Bell size={20} />
              <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-[#00d68f] rounded-full"></span>
            </button>
            <div className="w-8 h-8 rounded-full bg-[#2a343a] overflow-hidden border border-[#2a343a]">
              <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Felix&backgroundColor=00d68f" alt="Profile" />
            </div>
          </div>
        </header>

        {/* Dashboard Canvas */}
        <div className="flex-1 overflow-y-auto p-8 pt-4">
          <div className="max-w-[1400px] mx-auto min-h-full">
            {activeTab === 'monitoring' && <ZoneMonitoringDashboard />}
            {activeTab === 'priority'   && <PriorityDecisionDashboard />}
            {activeTab === 'allocation' && <ResourceAllocationDashboard />}
            {activeTab === 'routing'    && <RoutingPathDashboard />}
          </div>
        </div>
      </main>
    </div>
  );
}