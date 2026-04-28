import React, { useState, useEffect } from 'react';
import { MapPin, Truck, Clock, AlertTriangle, Activity } from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import { getRemainingSeconds } from '../allotmentLogic';

export default function UserRouting() {
  const { currentUser, updateIncident } = useAuth();
  
  // Find the most recent active incident
  const activeIncident = currentUser?.incidents
    ?.filter(inc => inc.status !== 'completed')
    ?.sort((a, b) => new Date(b.date) - new Date(a.date))[0];

  const isAssigned = activeIncident?.status === 'assigned';
  const initialEta = activeIncident ? getRemainingSeconds(activeIncident) : 0;

  const [timeLeft, setTimeLeft] = useState(initialEta);
  const [progress, setProgress] = useState(0);

  // Sync state if a new ETA comes in
  useEffect(() => {
    if (isAssigned && activeIncident?.etaSeconds) {
      setTimeLeft(getRemainingSeconds(activeIncident));
    }
  }, [isAssigned, activeIncident?.id, activeIncident?.assignedAt, activeIncident?.etaSeconds]);

  // Timer for routing countdown
  useEffect(() => {
    if (!isAssigned) return;
    
    const timer = setInterval(() => {
      const remaining = getRemainingSeconds(activeIncident);
      setTimeLeft(remaining);
      if (remaining <= 0 && activeIncident?.id) {
        clearInterval(timer);
        updateIncident(activeIncident.id, currentUser.id, {
          status: 'completed',
          completedAt: new Date().toISOString(),
        });
      }
    }, 1000);

    return () => clearInterval(timer);
  }, [isAssigned, activeIncident, currentUser?.id, updateIncident]);

  useEffect(() => {
    if (!isAssigned) return;
    
    // Calculate progress percentage
    const totalTime = activeIncident?.etaSeconds || 1;
    const currentProgress = ((totalTime - timeLeft) / totalTime) * 100;
    setProgress(Math.min(100, Math.max(0, currentProgress)));
  }, [timeLeft, isAssigned, activeIncident?.etaSeconds]);

  if (!activeIncident) {
    return (
      <div className="p-6 h-full flex items-center justify-center">
        <div className="text-gray-500 text-center">
          <MapPin size={48} className="mx-auto mb-4 opacity-50" />
          <p>No active incidents to track.</p>
        </div>
      </div>
    );
  }

  const score = activeIncident.score;

  if (!isAssigned) {
    return (
      <div className="p-6 h-full flex flex-col items-center justify-center">
        <div className="bg-[#182024] border border-[#2a343a] rounded-2xl p-10 w-full max-w-lg shadow-xl text-center flex flex-col items-center">
          
          <h2 className="text-2xl font-bold text-white mb-2">Analyzing Request</h2>
          <p className="text-gray-400 mb-12">Determining severity and locating nearest responders...</p>

          <div className="relative flex items-center justify-center w-64 h-64 mb-12">
            {/* Radar / Pulsing Animation */}
            <div className="absolute inset-0 rounded-full border-[3px] border-orange-500 animate-[ping_2s_cubic-bezier(0,0,0.2,1)_infinite] opacity-30"></div>
            <div className="absolute inset-4 rounded-full border-[2px] border-orange-400 animate-pulse opacity-40"></div>
            <div className="absolute inset-8 rounded-full border-[1px] border-yellow-500 opacity-20"></div>
            
            <div className="relative z-10 bg-[#1c252a] rounded-full w-40 h-40 flex flex-col items-center justify-center border-2 border-orange-500 shadow-[0_0_40px_rgba(249,115,22,0.2)]">
              <Activity className="text-orange-500 mb-2" size={24} />
              <div className="text-5xl font-black text-white leading-none tracking-tighter">
                {score !== null ? score : '--'}
              </div>
              <div className="text-xs text-orange-400 uppercase tracking-widest font-semibold mt-1">Criticality</div>
            </div>
          </div>

          <div className="flex items-center justify-center gap-3 bg-[#1c252a] px-6 py-3 rounded-full border border-[#2a343a]">
            <div className="w-2 h-2 rounded-full bg-[#00d68f] animate-pulse"></div>
            <span className="text-gray-300 font-medium">Waiting to be assigned...</span>
          </div>
        </div>
      </div>
    );
  }

  const minutes = Math.floor(timeLeft / 60);
  const seconds = timeLeft % 60;

  return (
    <div className="p-6 h-full flex flex-col relative animate-fade-in-up">
      <div className="absolute top-8 left-1/2 -translate-x-1/2 z-10 bg-[#1c252a] px-6 py-3 rounded-full border border-[#00d68f]/50 shadow-lg shadow-[#00d68f]/10 flex items-center gap-3">
        <Clock className="text-[#00d68f]" size={20} />
        <div>
          <span className="text-white font-bold text-lg">{minutes} min {seconds} sec</span>
          <span className="text-gray-400 text-sm ml-2">left to reach destination</span>
        </div>
      </div>

      <div className="flex-1 bg-[#1c252a] rounded-2xl border border-[#2a343a] overflow-hidden relative mt-4">
        {/* Mock Map Background */}
        <div className="absolute inset-0 opacity-20" style={{
          backgroundImage: 'radial-gradient(#2a343a 2px, transparent 2px)',
          backgroundSize: '30px 30px'
        }}></div>
        
        {/* Route Path */}
        <div className="absolute top-1/2 left-[10%] right-[10%] h-2 bg-[#2a343a] rounded-full -translate-y-1/2 overflow-hidden">
          <div 
            className="h-full bg-[#00d68f] transition-all duration-1000 ease-linear"
            style={{ width: `${progress}%` }}
          ></div>
        </div>

        {/* Start Point (Dispatch) */}
        <div className="absolute top-1/2 left-[10%] -translate-x-1/2 -translate-y-1/2 flex flex-col items-center">
          <div className="w-6 h-6 rounded-full bg-[#2a343a] border-4 border-[#1c252a] shadow-[0_0_0_2px_#323d44] z-10"></div>
          <span className="mt-2 text-xs text-gray-400 font-medium">Dispatch Unit</span>
        </div>

        {/* End Point (User Location) */}
        <div className="absolute top-1/2 right-[10%] translate-x-1/2 -translate-y-1/2 flex flex-col items-center">
          <MapPin className="text-red-500 fill-red-500/20 z-10" size={32} />
          <span className="mt-2 text-xs text-gray-400 font-medium">Your Location</span>
        </div>

        {/* Moving Vehicle */}
        <div 
          className="absolute top-1/2 left-[10%] -translate-y-1/2 transition-all duration-1000 ease-linear z-20"
          style={{ left: `calc(10% + ${progress * 0.8}%)`, transform: 'translate(-50%, -50%)' }}
        >
          <div className="bg-[#00d68f] p-2 rounded-full shadow-lg shadow-[#00d68f]/20 text-[#182024]">
            <Truck size={24} />
          </div>
          <div className="absolute -top-8 left-1/2 -translate-x-1/2 whitespace-nowrap bg-[#182024] text-xs px-2 py-1 rounded border border-[#2a343a] text-gray-300">
            {activeIncident.responderName || activeIncident.responderType || 'Designated Vehicle'}
          </div>
        </div>
      </div>
      
      {/* Status Details */}
      <div className="mt-6 bg-[#182024] rounded-xl border border-[#2a343a]/50 p-6 flex items-center justify-between">
        <div className="flex items-center gap-4">
          <div className="w-12 h-12 rounded-full bg-[#1c252a] flex items-center justify-center border border-[#2a343a]">
            <img src="https://api.dicebear.com/7.x/avataaars/svg?seed=Responder&backgroundColor=00d68f" alt="Driver" className="w-10 h-10 rounded-full" />
          </div>
          <div>
            <h4 className="text-white font-medium">Responder Unit Dispatched</h4>
            <p className="text-sm text-gray-400">{activeIncident.responderType || 'Emergency Unit'} | {activeIncident.distanceKm || '--'} km | ETA {activeIncident.etaMinutes || '--'} min</p>
          </div>
        </div>
        <div className="text-right">
          <div className="text-[#00d68f] font-medium">En Route</div>
          <div className="text-sm text-gray-400">Arriving shortly</div>
        </div>
      </div>
    </div>
  );
}
