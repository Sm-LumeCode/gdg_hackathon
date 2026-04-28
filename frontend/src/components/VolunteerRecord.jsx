import React from 'react';
import { useAuth } from '../context/AuthContext';
import { Clock, Truck, CheckCircle } from 'lucide-react';

export default function VolunteerRecord() {
  const { getAllIncidents, updateIncident } = useAuth();
  const allIncidents = getAllIncidents();
  
  const pending = allIncidents.filter(i => i.status === 'pending');
  const assigned = allIncidents.filter(i => i.status === 'assigned');

  const markCompleted = (id, userId) => {
    updateIncident(id, userId, { status: 'completed' });
  };

  const renderCard = (inc, isAssigned) => (
    <div key={inc.id} className="bg-[#1c252a] p-4 rounded-xl border border-[#2a343a] mb-4">
      <div className="flex justify-between items-start mb-2">
        <h4 className="font-semibold text-white">{inc.incidentType || 'Emergency'}</h4>
        <span className={`px-2 py-0.5 rounded text-xs font-medium ${isAssigned ? 'bg-blue-500/20 text-blue-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
          {isAssigned ? inc.responderType : 'Pending'}
        </span>
      </div>
      <p className="text-sm text-gray-400 mb-3">{inc.description}</p>
      <div className="text-xs text-gray-500 mb-1">User: {inc.userName}</div>
      <div className="text-xs text-gray-500">Location: {inc.place}</div>
      
      {isAssigned && (
        <button 
          onClick={() => markCompleted(inc.id, inc.userId)}
          className="w-full mt-4 flex items-center justify-center gap-2 bg-green-500/10 hover:bg-green-500/20 text-green-400 py-2 rounded-lg transition-colors border border-green-500/20 text-sm"
        >
          <CheckCircle size={16} />
          Mark as Completed
        </button>
      )}
    </div>
  );

  return (
    <div className="p-6 h-full flex flex-col">
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-white mb-1">Active Records</h2>
        <p className="text-gray-400">Track pending and assigned missions. Completed missions are moved to History.</p>
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 md:grid-cols-2 gap-8">
        {/* Pending Column */}
        <div className="bg-[#182024] rounded-2xl border border-[#2a343a]/50 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a] flex items-center gap-2">
            <Clock className="text-yellow-500" size={20} />
            <h3 className="font-semibold text-white text-lg">Pending ({pending.length})</h3>
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            {pending.length === 0 ? (
              <p className="text-center text-gray-500 mt-4">No pending records.</p>
            ) : (
              pending.map(inc => renderCard(inc, false))
            )}
          </div>
        </div>

        {/* Assigned Column */}
        <div className="bg-[#182024] rounded-2xl border border-[#2a343a]/50 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a] flex items-center gap-2">
            <Truck className="text-blue-500" size={20} />
            <h3 className="font-semibold text-white text-lg">Assigned & En Route ({assigned.length})</h3>
          </div>
          <div className="flex-1 overflow-y-auto p-4">
            {assigned.length === 0 ? (
              <p className="text-center text-gray-500 mt-4">No assigned records.</p>
            ) : (
              assigned.map(inc => renderCard(inc, true))
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
