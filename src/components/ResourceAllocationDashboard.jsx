import React from 'react';
import { useCrisisContext } from '../context/CrisisContext';
import { formatResourceAllocation } from '../utils';
import { Truck, Shield, Box } from 'lucide-react';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function ResourceAllocationDashboard() {
  const { zones, allocation, isAllocated, remainingResources, totalResources } = useCrisisContext();

  const totalAvailable = Object.values(totalResources).reduce((a, b) => a + b, 0);
  const totalRemaining = Object.values(remainingResources).reduce((a, b) => a + b, 0);
  const totalDeployed = totalAvailable - totalRemaining;

  const chartData = [
    { name: 'Deployed', value: totalDeployed },
    { name: 'Standby', value: totalRemaining }
  ];
  const COLORS = ['#00d68f', '#2a343a'];

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* Top Action Bar */}
      <div className="flex items-center justify-between shrink-0">
        <h1 className="text-xl font-semibold text-white tracking-wide">Resource Allocation</h1>
      </div>

      {/* Analytics Row */}
      <div className="flex gap-6 h-[220px]">
        {/* Stats Panel */}
        <div className="w-1/2 grid grid-cols-3 gap-4">
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col items-center justify-center text-center">
             <Box size={24} className="text-gray-400 mb-3" />
             <h3 className="text-3xl font-bold text-white">{totalAvailable}</h3>
             <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mt-1">Fleet Size</p>
          </div>
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col items-center justify-center text-center">
             <Truck size={24} className="text-[#00d68f] mb-3" />
             <h3 className="text-3xl font-bold text-[#00d68f]">{totalDeployed}</h3>
             <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mt-1">Units Deployed</p>
          </div>
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col items-center justify-center text-center">
             <Shield size={24} className="text-blue-400 mb-3" />
             <h3 className="text-3xl font-bold text-blue-400">{totalRemaining}</h3>
             <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mt-1">Units on Standby</p>
          </div>
        </div>

        {/* Chart Panel */}
        <div className="w-1/2 bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col items-center">
          <h3 className="text-white font-bold tracking-wide mb-4 text-lg w-full text-left">Fleet Utilization</h3>
          <div className="flex-1 w-full relative">
            <ResponsiveContainer width="100%" height="100%">
              <PieChart>
                <Pie
                  data={chartData}
                  cx="50%"
                  cy="50%"
                  innerRadius={50}
                  outerRadius={70}
                  paddingAngle={5}
                  dataKey="value"
                  stroke="none"
                >
                  {chartData.map((entry, index) => (
                    <Cell key={`cell-${index}`} fill={COLORS[index % COLORS.length]} />
                  ))}
                </Pie>
                <Legend verticalAlign="middle" align="right" layout="vertical" iconType="circle" wrapperStyle={{ fontSize: '11px', color: '#9ca3af' }} />
                <Tooltip contentStyle={{ backgroundColor: '#182024', border: '1px solid #2a343a', borderRadius: '8px', color: '#fff', fontSize: '12px' }} itemStyle={{ color: '#fff' }} />
              </PieChart>
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
                <th className="px-6 py-4 font-medium border-none uppercase text-xs tracking-wider">Zone Name</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Severity</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Assigned Resources</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              {!isAllocated ? (
                <tr>
                  <td colSpan="3" className="px-6 py-12 text-center border-none">
                    <div className="inline-flex flex-col items-center justify-center text-gray-500">
                      <Truck size={32} className="mb-3 opacity-50" />
                      <p>Engine pending execution.</p>
                      <p className="text-xs mt-1 opacity-70">Run the Priority Engine to generate resource allocations.</p>
                    </div>
                  </td>
                </tr>
              ) : (
                zones.map((zone, idx) => {
                  const hasAllocation = allocation && allocation[zone.id];
                  const resStr = hasAllocation ? formatResourceAllocation(allocation[zone.id]) : 'None';
                  
                  return (
                    <tr key={zone.id} className={`hover:bg-[#2a343a]/30 transition-colors ${idx !== zones.length - 1 ? 'border-b border-[#2a343a]' : 'border-none'}`}>
                      <td className="px-6 py-4 font-medium text-gray-200 border-none">{zone.name}</td>
                      <td className="px-4 py-4 border-none">
                        <span className={`px-2 py-1 rounded text-xs font-semibold ${
                          zone.severity >= 9 ? 'bg-red-500/10 text-red-400' :
                          zone.severity >= 7 ? 'bg-orange-500/10 text-orange-400' :
                          'bg-yellow-500/10 text-yellow-400'
                        }`}>
                          Score: {zone.severity}
                        </span>
                      </td>
                      <td className="px-4 py-4 text-[#00d68f] border-none">
                        {resStr}
                      </td>
                    </tr>
                  );
                })
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}