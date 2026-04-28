import React, { useState } from 'react';
import { 
  LayoutDashboard, AlertTriangle, Briefcase, Route, 
  Search, Bell, Settings, Activity, HelpCircle, LogOut, 
  Menu, X, History, Map, ClipboardList, Database, RefreshCw
} from 'lucide-react';
import { useCrisisContext } from './context/CrisisContext';
import { useAuth } from './context/AuthContext';

import VolunteerDashboard from './components/VolunteerDashboard';
import VolunteerAllotment from './components/VolunteerAllotment';
import VolunteerRecord from './components/VolunteerRecord';
import VolunteerHistory from './components/VolunteerHistory';

import LoginSignup from './components/LoginSignup';
import UserDashboard from './components/UserDashboard';
import UserHistory from './components/UserHistory';
import UserAllocation from './components/UserAllocation';
import UserRouting from './components/UserRouting';

export default function App() {
  const { currentUser, logout, updateUser } = useAuth();
  const [activeTab, setActiveTab] = useState('dashboard');
  const [userActiveTab, setUserActiveTab] = useState('dashboard');
  const [isSidebarOpen, setIsSidebarOpen] = useState(true);
  const [showNotifications, setShowNotifications] = useState(false);
  const { searchQuery, setSearchQuery } = useCrisisContext();

  if (!currentUser) {
    return <LoginSignup />;
  }

  const isVolunteer = currentUser.role === 'volunteer';

  const volunteerNavItems = [
    { id: 'dashboard', label: 'Dashboard',      icon: LayoutDashboard },
    { id: 'allotment', label: 'Allotment',      icon: Briefcase },
    { id: 'record',    label: 'Record',         icon: ClipboardList },
    { id: 'history',   label: 'History',        icon: Database },
  ];

  const userNavItems = [
    { id: 'dashboard',  label: 'Dashboard',      icon: LayoutDashboard },
    { id: 'history',    label: 'History',        icon: History },
    { id: 'allocation', label: 'Allocation',     icon: Briefcase },
    { id: 'routing',    label: 'Routing',        icon: Map },
  ];

  const toggleSidebar = () => setIsSidebarOpen(!isSidebarOpen);

  const changeAvatar = () => {
    const randomSeed = Math.random().toString(36).substring(7);
    updateUser(currentUser.id, { avatarSeed: randomSeed });
  };

  const currentAvatarSeed = currentUser.avatarSeed || currentUser.email;

  return (
    <div className="flex h-screen bg-[#182024] text-gray-300 font-sans overflow-hidden selection:bg-[#00d68f]/30">
      
      {/* Sidebar */}
      <aside 
        className={`${isSidebarOpen ? 'w-64' : 'w-0'} bg-[#182024] flex flex-col shrink-0 z-20 border-r border-[#2a343a]/50 transition-all duration-300 ease-in-out overflow-hidden`}
      >
        <div className="w-64 flex flex-col h-full">
          {/* Logo */}
          <div className="h-[72px] flex items-center px-6 shrink-0 justify-between">
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
            {isVolunteer ? (
              volunteerNavItems.map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  onClick={() => setActiveTab(id)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 outline-none ${
                    activeTab === id 
                      ? 'bg-[#2a343a] text-white font-medium border-l-[3px] border-[#00d68f]' 
                      : 'text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent'
                  }`}
                >
                  <Icon size={18} className={activeTab === id ? 'text-[#00d68f]' : 'text-gray-400'} />
                  <span className="tracking-wide text-sm">{label}</span>
                </button>
              ))
            ) : (
              userNavItems.map(({ id, label, icon: Icon }) => (
                <button
                  key={id}
                  onClick={() => setUserActiveTab(id)}
                  className={`w-full flex items-center gap-3 px-4 py-3 rounded-lg transition-all duration-200 outline-none ${
                    userActiveTab === id 
                      ? 'bg-[#2a343a] text-white font-medium border-l-[3px] border-[#00d68f]' 
                      : 'text-gray-400 hover:text-gray-200 border-l-[3px] border-transparent'
                  }`}
                >
                  <Icon size={18} className={userActiveTab === id ? 'text-[#00d68f]' : 'text-gray-400'} />
                  <span className="tracking-wide text-sm">{label}</span>
                </button>
              ))
            )}

            {isVolunteer && (
              <>
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
              </>
            )}
          </nav>

          {/* Footer */}
          <div className="p-4 px-8 pb-8 shrink-0">
            <div className="mb-4 flex items-center gap-3 text-white">
              <div className="w-8 h-8 bg-[#00d68f] text-[#182024] rounded-full flex justify-center items-center font-bold relative group cursor-pointer" onClick={changeAvatar} title="Change Avatar">
                <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${currentAvatarSeed}&backgroundColor=00d68f`} alt="Profile" className="w-full h-full rounded-full" />
                <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                  <RefreshCw size={14} className="text-white" />
                </div>
              </div>
              <span className="text-sm truncate">{currentUser.name || currentUser.email}</span>
            </div>
            <button onClick={logout} className="flex items-center gap-3 text-gray-500 hover:text-red-400 transition-colors w-full">
              <LogOut size={18} />
              <span className="tracking-wide text-sm">Log Out</span>
            </button>
          </div>
        </div>
      </aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 bg-[#1c252a]">
        
        {/* Topbar */}
        <header className="h-[72px] flex items-center justify-between px-6 shrink-0 border-b border-[#2a343a]/50 relative">
          <div className="flex items-center gap-4">
            <button 
              onClick={toggleSidebar}
              className="text-gray-400 hover:text-white transition-colors p-2 rounded-lg hover:bg-[#2a343a]"
            >
              <Menu size={20} />
            </button>
            {!isSidebarOpen && (
              <div className="flex items-center gap-3">
                <div className="text-[#00d68f]">
                  <svg width="20" height="20" viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
                    <path d="M4 4L10 20H14L8 4H4Z" fill="currentColor"/>
                    <path d="M14 4L20 20H16L10 4H14Z" fill="currentColor"/>
                  </svg>
                </div>
              </div>
            )}
          </div>
          
          {isVolunteer && (
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
          )}

          <div className={`flex items-center gap-5 ${!isVolunteer ? 'ml-auto' : ''}`}>
            <div className="relative">
              <button 
                onClick={() => setShowNotifications(!showNotifications)}
                className={`relative transition-colors ${showNotifications ? 'text-[#00d68f]' : 'text-gray-400 hover:text-white'}`}
              >
                <Bell size={20} />
                <span className="absolute -top-1 -right-1 w-2.5 h-2.5 bg-[#00d68f] rounded-full animate-pulse"></span>
              </button>
              
              {showNotifications && (
                <div className="absolute right-0 top-full mt-4 w-72 bg-[#182024] border border-[#2a343a]/50 rounded-xl shadow-2xl overflow-hidden z-50 animate-fade-in-up">
                  <div className="p-3 border-b border-[#2a343a]/50 bg-[#1c252a] flex justify-between items-center">
                    <h4 className="font-bold text-white text-sm">Notifications</h4>
                    <span className="text-xs text-[#00d68f]">1 New</span>
                  </div>
                  <div className="p-2 max-h-64 overflow-y-auto">
                    <div className="p-3 bg-[#1c252a]/50 hover:bg-[#1c252a] rounded-lg transition-colors cursor-pointer border-l-2 border-[#00d68f] mb-1">
                      <div className="text-sm text-white font-medium">System Update</div>
                      <div className="text-xs text-gray-400 mt-1">Real-time mapping feature successfully integrated.</div>
                    </div>
                    <div className="p-3 hover:bg-[#1c252a] rounded-lg transition-colors cursor-pointer mb-1 opacity-70">
                      <div className="text-sm text-gray-300 font-medium">Welcome!</div>
                      <div className="text-xs text-gray-500 mt-1">You logged into the Command Center.</div>
                    </div>
                  </div>
                </div>
              )}
            </div>
            
            <div 
              className="w-8 h-8 rounded-full bg-[#2a343a] border border-[#2a343a] relative group cursor-pointer"
              onClick={changeAvatar}
              title="Click to randomize avatar"
            >
              <img src={`https://api.dicebear.com/7.x/avataaars/svg?seed=${currentAvatarSeed}&backgroundColor=00d68f`} alt="Profile" className="w-full h-full rounded-full" />
              <div className="absolute inset-0 bg-black/40 rounded-full flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                <RefreshCw size={14} className="text-white" />
              </div>
            </div>
          </div>
        </header>

        {/* Dashboard Canvas */}
        <div className="flex-1 overflow-y-auto p-4 md:p-8 pt-4">
          <div className="max-w-[1400px] mx-auto h-full">
            {isVolunteer ? (
              <>
                {activeTab === 'dashboard' && <VolunteerDashboard />}
                {activeTab === 'allotment' && <VolunteerAllotment />}
                {activeTab === 'record'    && <VolunteerRecord />}
                {activeTab === 'history'   && <VolunteerHistory />}
              </>
            ) : (
              <>
                {userActiveTab === 'dashboard'  && <UserDashboard />}
                {userActiveTab === 'history'    && <UserHistory />}
                {userActiveTab === 'allocation' && <UserAllocation />}
                {userActiveTab === 'routing'    && <UserRouting />}
              </>
            )}
          </div>
        </div>
      </main>
    </div>
  );
}