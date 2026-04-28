import React from 'react';
import { useAuth } from '../context/AuthContext';
import { CheckCircle, Clock, AlertTriangle } from 'lucide-react';

export default function UserHistory() {
  const { currentUser } = useAuth();
  
  const incidents = currentUser?.incidents || [];

  return (
    <div className="p-6">
      <h2 className="text-2xl font-bold text-white mb-6">Your Incident History</h2>
      
      {incidents.length === 0 ? (
        <div className="bg-[#182024] rounded-xl border border-[#2a343a]/50 p-8 text-center">
          <p className="text-gray-400">You haven't reported any incidents yet.</p>
        </div>
      ) : (
        <div className="space-y-4">
          {incidents.map((incident) => (
            <div key={incident.id} className="bg-[#182024] rounded-xl border border-[#2a343a]/50 p-5 flex items-start gap-4 transition-all hover:border-[#2a343a]">
              <div className={`p-3 rounded-lg flex-shrink-0 ${incident.status === 'completed' ? 'bg-green-500/20 text-green-500' : 'bg-yellow-500/20 text-yellow-500'}`}>
                {incident.status === 'completed' ? <CheckCircle size={24} /> : <Clock size={24} />}
              </div>
              
              <div className="flex-1 min-w-0">
                <div className="flex items-center justify-between mb-1">
                  <h3 className="text-lg font-semibold text-white truncate">{incident.incidentType}</h3>
                  <span className={`text-xs px-2 py-1 rounded-full font-medium ${
                    incident.status === 'completed' ? 'bg-green-500/10 text-green-400' : 'bg-yellow-500/10 text-yellow-400'
                  }`}>
                    {incident.status === 'completed' ? 'Solved' : 'Pending'}
                  </span>
                </div>
                
                <p className="text-gray-400 text-sm mb-2">{incident.description}</p>
                
                <div className="flex flex-wrap gap-4 text-xs text-gray-500">
                  <div className="flex items-center gap-1">
                    <AlertTriangle size={14} />
                    <span>{incident.place}</span>
                  </div>
                  <div className="flex items-center gap-1">
                    <Clock size={14} />
                    <span>{new Date(incident.date).toLocaleString()}</span>
                  </div>
                </div>
              </div>
              
              {incident.image && (
                <div className="w-20 h-20 rounded-lg overflow-hidden flex-shrink-0 border border-[#2a343a]">
                  <img src={incident.image} alt="Incident" className="w-full h-full object-cover" />
                </div>
              )}
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
