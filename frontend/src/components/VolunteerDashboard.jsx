import React, { useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Play, AlertTriangle, Clock, MapPin, Activity } from 'lucide-react';

export default function VolunteerDashboard() {
  const { getAllIncidents, updateIncident } = useAuth();
  const incidents = getAllIncidents();
  const [isRunning, setIsRunning] = useState(false);

  const runEngine = () => {
    setIsRunning(true);
    // Simulate calculating critical score for all incidents
    setTimeout(() => {
      incidents.forEach(inc => {
        if (inc.score === null || inc.score === undefined) {
          const randomScore = Math.floor(Math.random() * 50) + 50; // Random high score 50-100
          updateIncident(inc.id, inc.userId, { score: randomScore });
        }
      });
      setIsRunning(false);
    }, 2000);
  };

  return (
    <div className="p-6 h-full flex flex-col">
      <div className="flex justify-between items-center mb-8">
        <div>
          <h2 className="text-2xl font-bold text-white mb-1">Global Dashboard</h2>
          <p className="text-gray-400">View all reported incidents and assess severity.</p>
        </div>
        <button
          onClick={runEngine}
          disabled={isRunning}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg font-bold transition-all ${
            isRunning 
              ? 'bg-[#2a343a] text-gray-500 cursor-not-allowed' 
              : 'bg-[#00d68f] text-[#182024] hover:bg-[#00c080] shadow-[0_0_15px_rgba(0,214,143,0.3)]'
          }`}
        >
          {isRunning ? <Activity className="animate-spin" size={20} /> : <Play size={20} />}
          {isRunning ? 'Running Engine...' : 'Run Engine'}
        </button>
      </div>

      <div className="bg-[#182024] rounded-2xl border border-[#2a343a]/50 flex-1 overflow-hidden flex flex-col">
        <div className="grid grid-cols-12 gap-4 p-4 border-b border-[#2a343a]/50 bg-[#1c252a] text-sm font-semibold text-gray-400">
          <div className="col-span-3">Reporter</div>
          <div className="col-span-3">Incident</div>
          <div className="col-span-3">Location</div>
          <div className="col-span-2">Reported Time</div>
          <div className="col-span-1 text-center">Score</div>
        </div>
        
        <div className="flex-1 overflow-y-auto p-2">
          {incidents.length === 0 ? (
            <div className="h-full flex flex-col items-center justify-center text-gray-500">
              <AlertTriangle size={48} className="mb-4 opacity-50" />
              <p>No incidents reported yet.</p>
            </div>
          ) : (
            incidents.map(inc => (
              <div key={inc.id} className="grid grid-cols-12 gap-4 p-4 items-center border-b border-[#2a343a]/30 hover:bg-[#1c252a]/50 transition-colors">
                <div className="col-span-3">
                  <div className="text-white font-medium truncate">{inc.userName || 'Unknown User'}</div>
                </div>
                <div className="col-span-3">
                  <div className="text-gray-300 truncate">{inc.incidentType || 'Unspecified'}</div>
                  <div className="text-xs text-gray-500 truncate">{inc.description}</div>
                </div>
                <div className="col-span-3 flex items-center gap-2 text-gray-400">
                  <MapPin size={14} className="flex-shrink-0" />
                  <span className="truncate">{inc.place}</span>
                </div>
                <div className="col-span-2 flex items-center gap-2 text-gray-400 text-sm">
                  <Clock size={14} className="flex-shrink-0" />
                  {new Date(inc.date).toLocaleTimeString()}
                </div>
                <div className="col-span-1 flex justify-center">
                  {inc.score !== null ? (
                    <span className={`px-2 py-1 rounded-md text-xs font-bold ${
                      inc.score > 80 ? 'bg-red-500/20 text-red-500' :
                      inc.score > 50 ? 'bg-orange-500/20 text-orange-500' :
                      'bg-yellow-500/20 text-yellow-500'
                    }`}>
                      {inc.score}
                    </span>
                  ) : (
                    <span className="text-gray-600 text-sm">-</span>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>
    </div>
  );
}
