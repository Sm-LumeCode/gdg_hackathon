import React from 'react';
import { useAuth } from '../context/AuthContext';
import { Clock, CheckCircle, Truck, AlertTriangle } from 'lucide-react';

export default function UserAllocation() {
  const { currentUser } = useAuth();
  
  const incidents = currentUser?.incidents || [];
  
  // For demonstration, let's randomly consider some pending ones as assigned if needed, 
  // or just use the actual status if we implemented status changes.
  // We'll stick to actual status ('pending', 'assigned', 'completed').
  const pending = incidents.filter(i => i.status === 'pending');
  const assigned = incidents.filter(i => i.status === 'assigned');
  const completed = incidents.filter(i => i.status === 'completed');

  const renderIncidentCard = (incident) => (
    <div key={incident.id} className="bg-[#1c252a] rounded-lg p-4 border border-[#2a343a] mb-3 last:mb-0">
      <div className="flex justify-between items-start mb-2">
        <h4 className="font-medium text-gray-200">{incident.incidentType || 'Unknown Incident'}</h4>
        <span className="text-xs text-gray-500">{new Date(incident.date).toLocaleDateString()}</span>
      </div>
      <p className="text-sm text-gray-400 mb-2 truncate">{incident.description}</p>
      <div className="flex items-center text-xs text-gray-500">
        <AlertTriangle size={12} className="mr-1" />
        {incident.place}
      </div>
    </div>
  );

  return (
    <div className="p-6 h-full flex flex-col">
      <h2 className="text-2xl font-bold text-white mb-6">Resource Allocation Status</h2>
      
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 flex-1 min-h-0">
        {/* Pending Column */}
        <div className="bg-[#182024] rounded-xl border border-[#2a343a]/50 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a] flex items-center gap-2">
            <Clock className="text-yellow-500" size={20} />
            <h3 className="font-semibold text-white">Pending ({pending.length})</h3>
          </div>
          <div className="p-4 flex-1 overflow-y-auto">
            {pending.length === 0 ? (
              <p className="text-sm text-gray-500 text-center mt-4">No pending incidents</p>
            ) : (
              pending.map(renderIncidentCard)
            )}
          </div>
        </div>

        {/* Assigned Column */}
        <div className="bg-[#182024] rounded-xl border border-[#2a343a]/50 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a] flex items-center gap-2">
            <Truck className="text-blue-500" size={20} />
            <h3 className="font-semibold text-white">Assigned ({assigned.length})</h3>
          </div>
          <div className="p-4 flex-1 overflow-y-auto">
            {assigned.length === 0 ? (
              <p className="text-sm text-gray-500 text-center mt-4">No assigned incidents</p>
            ) : (
              assigned.map(renderIncidentCard)
            )}
          </div>
        </div>

        {/* Completed Column */}
        <div className="bg-[#182024] rounded-xl border border-[#2a343a]/50 flex flex-col overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a] flex items-center gap-2">
            <CheckCircle className="text-green-500" size={20} />
            <h3 className="font-semibold text-white">Completed ({completed.length})</h3>
          </div>
          <div className="p-4 flex-1 overflow-y-auto">
            {completed.length === 0 ? (
              <p className="text-sm text-gray-500 text-center mt-4">No completed incidents</p>
            ) : (
              completed.map(renderIncidentCard)
            )}
          </div>
        </div>
      </div>
    </div>
  );
}
