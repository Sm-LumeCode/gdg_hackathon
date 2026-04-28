import React from 'react';
import { useAuth } from '../context/AuthContext';
import { CheckCircle, BarChart2, PieChart } from 'lucide-react';

export default function VolunteerHistory() {
  const { getAllIncidents } = useAuth();
  const allIncidents = getAllIncidents();
  const completed = allIncidents.filter(i => i.status === 'completed');

  // Calculate simple mock stats for charts
  const fireCount = completed.filter(i => i.incidentType?.toLowerCase().includes('fire')).length || 1;
  const medicalCount = completed.filter(i => i.incidentType?.toLowerCase().includes('medical') || i.incidentType?.toLowerCase().includes('accident')).length || 2;
  const otherCount = Math.max(0, completed.length - fireCount - medicalCount) || 1;
  
  const total = fireCount + medicalCount + otherCount;
  
  const firePct = Math.round((fireCount / total) * 100);
  const medicalPct = Math.round((medicalCount / total) * 100);
  const otherPct = Math.round((otherCount / total) * 100);

  return (
    <div className="p-6 pb-12">
      <div className="mb-8">
        <h2 className="text-2xl font-bold text-white mb-1">Rescue History & Analytics</h2>
        <p className="text-gray-400">Review completed rescues and historical data analytics.</p>
      </div>

      {/* Analytics Charts */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6 mb-8">
        <div className="bg-[#182024] p-6 rounded-2xl border border-[#2a343a]/50">
          <div className="flex items-center gap-2 mb-6">
            <BarChart2 className="text-[#00d68f]" />
            <h3 className="font-semibold text-white text-lg">Incident Breakdown</h3>
          </div>
          <div className="space-y-4">
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-300">Medical / Accidents</span>
                <span className="text-[#00d68f] font-bold">{medicalPct}%</span>
              </div>
              <div className="h-2 bg-[#1c252a] rounded-full overflow-hidden">
                <div className="h-full bg-[#00d68f] rounded-full" style={{ width: `${medicalPct}%` }}></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-300">Fire Emergencies</span>
                <span className="text-orange-500 font-bold">{firePct}%</span>
              </div>
              <div className="h-2 bg-[#1c252a] rounded-full overflow-hidden">
                <div className="h-full bg-orange-500 rounded-full" style={{ width: `${firePct}%` }}></div>
              </div>
            </div>
            <div>
              <div className="flex justify-between text-sm mb-1">
                <span className="text-gray-300">Other</span>
                <span className="text-blue-500 font-bold">{otherPct}%</span>
              </div>
              <div className="h-2 bg-[#1c252a] rounded-full overflow-hidden">
                <div className="h-full bg-blue-500 rounded-full" style={{ width: `${otherPct}%` }}></div>
              </div>
            </div>
          </div>
        </div>

        <div className="bg-[#182024] p-6 rounded-2xl border border-[#2a343a]/50">
          <div className="flex items-center gap-2 mb-6">
            <PieChart className="text-[#00d68f]" />
            <h3 className="font-semibold text-white text-lg">Response Efficiency</h3>
          </div>
          <div className="flex items-center justify-center h-32">
            <div className="text-center">
              <div className="text-4xl font-black text-white mb-2">94%</div>
              <p className="text-sm text-gray-400">Success rate of rescues<br/>under targeted ETA.</p>
            </div>
          </div>
        </div>
      </div>

      <h3 className="font-bold text-white text-xl mb-4">Completed Rescue Logs</h3>
      <div className="bg-[#182024] rounded-2xl border border-[#2a343a]/50">
        {completed.length === 0 ? (
          <div className="p-8 text-center text-gray-500">No completed rescues yet.</div>
        ) : (
          <div className="divide-y divide-[#2a343a]/50">
            {completed.map(inc => (
              <div key={inc.id} className="p-4 hover:bg-[#1c252a] transition-colors flex items-center gap-4">
                <div className="p-3 bg-green-500/10 text-green-500 rounded-full">
                  <CheckCircle size={20} />
                </div>
                <div className="flex-1">
                  <div className="flex justify-between items-start">
                    <h4 className="font-semibold text-white">{inc.incidentType || 'Emergency'}</h4>
                    <span className="text-xs text-gray-500">{new Date(inc.date).toLocaleDateString()}</span>
                  </div>
                  <p className="text-sm text-gray-400">{inc.description}</p>
                  <div className="mt-2 flex gap-4 text-xs font-medium text-gray-500">
                    <span>Reported by: <span className="text-gray-300">{inc.userName}</span></span>
                    <span>Location: <span className="text-gray-300">{inc.place}</span></span>
                    <span>Responder: <span className="text-gray-300">{inc.responderType}</span></span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
