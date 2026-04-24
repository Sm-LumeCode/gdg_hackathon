import React, { useMemo } from 'react';
import { calculatePriority, sortZonesByPriority, getTypeIconComponent } from '../utils';
import { useCrisisContext } from '../context/CrisisContext';
import { Activity, Server, Crosshair } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function PriorityDecisionDashboard() {
  const { zones, isAllocated, runAllocation } = useCrisisContext();
  
  const sortedZones = useMemo(() => sortZonesByPriority(zones), [zones]);

  const topPriorityZone = sortedZones.length > 0 ? sortedZones[0] : null;
  const engineStatus = isAllocated ? "Executed" : "Pending";
  
  const chartData = useMemo(() => {
    return sortedZones.map(z => ({
      name: z.name,
      score: parseFloat(calculatePriority(z).toFixed(2))
    })).slice(0, 7);
  }, [sortedZones]);

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* Top Action Bar */}
      <div className="flex items-center justify-between shrink-0">
        <h1 className="text-xl font-semibold text-white tracking-wide">Priority Engine</h1>
        
        <div className="flex items-center gap-4">
          <button 
            onClick={runAllocation}
            className="px-6 py-2 font-semibold bg-[#00d68f] text-[#182024] rounded-md hover:bg-[#00b579] transition-colors"
          >
            Execute Engine
          </button>
        </div>
      </div>

      {/* Analytics Row */}
      <div className="flex gap-6 h-[220px]">
        {/* Stats Panel */}
        <div className="w-1/3 flex flex-col gap-4">
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className={`text-[10px] font-bold tracking-widest uppercase mb-1 ${isAllocated ? 'text-[#00d68f]' : 'text-yellow-400'}`}>Engine Status</p>
               <h3 className={`text-2xl font-bold ${isAllocated ? 'text-[#00d68f]' : 'text-yellow-400'}`}>{engineStatus}</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Server size={20} className={isAllocated ? 'text-[#00d68f]' : 'text-yellow-400'} />
             </div>
          </div>
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className="text-red-400 text-[10px] font-bold tracking-widest uppercase mb-1">Highest Priority</p>
               <h3 className="text-xl font-bold text-red-400 truncate max-w-[150px]">{topPriorityZone ? topPriorityZone.name : 'None'}</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-red-500/10 border border-red-500/20 flex items-center justify-center shrink-0">
               <Crosshair size={20} className="text-red-400" />
             </div>
          </div>
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className="text-[#00d68f] text-[10px] font-bold tracking-widest uppercase mb-1">Zones Ranked</p>
               <h3 className="text-3xl font-bold text-white">{sortedZones.length}</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Activity size={20} className="text-[#00d68f]" />
             </div>
          </div>
        </div>

        {/* Chart Panel */}
        <div className="w-2/3 bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col">
          <h3 className="text-white font-bold tracking-wide mb-4 text-lg">Top Priority Scores (Calculated)</h3>
          <div className="flex-1 min-h-0 relative -ml-4">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 20, left: 0, bottom: 0 }} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#2a343a" horizontal={true} vertical={false} />
                <XAxis type="number" stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} hide />
                <YAxis dataKey="name" type="category" stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} width={180} />
                <Tooltip 
                  cursor={{fill: '#2a343a', opacity: 0.4}}
                  contentStyle={{ backgroundColor: '#182024', border: '1px solid #2a343a', borderRadius: '8px', color: '#fff', fontSize: '12px' }} 
                  itemStyle={{ color: '#ef4444' }}
                />
                <Bar dataKey="score" fill="#ef4444" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Main Table */}
      <div className="bg-[#212b31] rounded-xl overflow-hidden border border-[#2a343a] shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm whitespace-nowrap border-none">
            <thead>
              <tr className="bg-[#2a343a] text-gray-300">
                <th className="px-6 py-4 font-medium border-none uppercase text-xs tracking-wider">Rank</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Type</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Zone Name</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider text-right">Score</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              {sortedZones.map((zone, idx) => {
                const Icon = getTypeIconComponent(zone.type);
                const score = calculatePriority(zone);
                
                return (
                  <tr key={zone.id} className={`hover:bg-[#2a343a]/30 transition-colors ${idx !== sortedZones.length - 1 ? 'border-b border-[#2a343a]' : 'border-none'}`}>
                    <td className="px-6 py-4 border-none">
                      <span className={`inline-flex items-center justify-center w-6 h-6 rounded-full text-xs font-bold ${idx === 0 ? 'bg-red-500/20 text-red-400' : 'bg-[#182024] text-gray-400'}`}>
                        {idx + 1}
                      </span>
                    </td>
                    <td className="px-4 py-4 text-gray-400 border-none">
                      <div className="w-8 h-8 bg-[#182024] rounded border border-[#2a343a] flex items-center justify-center">
                        <Icon size={14} />
                      </div>
                    </td>
                    <td className="px-4 py-4 border-none">
                      <div className="font-medium text-gray-200">{zone.name}</div>
                      <div className="text-[10px] text-gray-500 uppercase tracking-wider">{zone.type}</div>
                    </td>
                    <td className="px-4 py-4 text-right font-mono text-[#00d68f] border-none">
                      {score.toFixed(2)}
                    </td>
                  </tr>
                );
              })}
              {sortedZones.length === 0 && (
                <tr>
                  <td colSpan="4" className="px-6 py-8 text-center text-gray-500 border-none">
                    No active zones.
                  </td>
                </tr>
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}