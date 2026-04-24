import React, { useMemo } from 'react';
import { calculateShortestPath, sortZonesByPriority, getTypeIconComponent } from '../utils';
import { useCrisisContext } from '../context/CrisisContext';
import { Route, Navigation, Map } from 'lucide-react';
import { BarChart, Bar, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer } from 'recharts';

export default function RoutingPathDashboard() {
  const { zones, graph } = useCrisisContext();

  const routingData = useMemo(() => {
    return sortZonesByPriority(zones).map(zone => {
      const { distance, path } = calculateShortestPath(graph, zone);
      return { ...zone, optimalDistance: distance, pathNodes: path };
    });
  }, [zones, graph]);

  // Statistics
  const totalRoutes = routingData.length;
  const avgDistance = totalRoutes > 0 ? (routingData.reduce((sum, d) => sum + d.optimalDistance, 0) / totalRoutes).toFixed(1) : 0;
  const maxDistance = totalRoutes > 0 ? Math.max(...routingData.map(d => d.optimalDistance)).toFixed(1) : 0;

  // Chart Data
  const chartData = useMemo(() => {
    return routingData.map(d => ({
      name: d.name,
      distance: d.optimalDistance
    })).slice(0, 7); // Show top 7 longest/shortest, wait let's just slice 0,7
  }, [routingData]);

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* Top Action Bar */}
      <div className="flex items-center justify-between shrink-0">
        <h1 className="text-xl font-semibold text-white tracking-wide">Routing Analysis</h1>
      </div>

      {/* Analytics Row */}
      <div className="flex gap-6 h-[220px]">
        {/* Stats Panel */}
        <div className="w-1/3 flex flex-col gap-4">
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className="text-[#00d68f] text-[10px] font-bold tracking-widest uppercase mb-1">Total Routes Calculated</p>
               <h3 className="text-3xl font-bold text-white">{totalRoutes}</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Route size={20} className="text-[#00d68f]" />
             </div>
          </div>
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className="text-blue-400 text-[10px] font-bold tracking-widest uppercase mb-1">Avg Route Distance</p>
               <h3 className="text-xl font-bold text-blue-400">{avgDistance} km</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Map size={20} className="text-blue-400" />
             </div>
          </div>
          <div className="bg-[#212b31] flex-1 rounded-xl border border-[#2a343a] shadow-lg px-6 flex items-center justify-between">
             <div>
               <p className="text-red-400 text-[10px] font-bold tracking-widest uppercase mb-1">Longest Active Route</p>
               <h3 className="text-xl font-bold text-red-400">{maxDistance} km</h3>
             </div>
             <div className="w-12 h-12 rounded-full bg-red-500/10 border border-red-500/20 flex items-center justify-center shrink-0">
               <Navigation size={20} className="text-red-400" />
             </div>
          </div>
        </div>

        {/* Chart Panel */}
        <div className="w-2/3 bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col">
          <h3 className="text-white font-bold tracking-wide mb-4 text-lg">Optimal Route Distances (km)</h3>
          <div className="flex-1 min-h-0 relative -ml-4">
            <ResponsiveContainer width="100%" height="100%">
              <BarChart data={chartData} margin={{ top: 10, right: 20, left: 0, bottom: 0 }} layout="vertical">
                <CartesianGrid strokeDasharray="3 3" stroke="#2a343a" horizontal={true} vertical={false} />
                <XAxis type="number" stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} hide />
                <YAxis dataKey="name" type="category" stroke="#6b7280" fontSize={11} tickLine={false} axisLine={false} width={180} />
                <Tooltip 
                  cursor={{fill: '#2a343a', opacity: 0.4}}
                  contentStyle={{ backgroundColor: '#182024', border: '1px solid #2a343a', borderRadius: '8px', color: '#fff', fontSize: '12px' }} 
                  itemStyle={{ color: '#00d68f' }}
                />
                <Bar dataKey="distance" fill="#00d68f" radius={[0, 4, 4, 0]} />
              </BarChart>
            </ResponsiveContainer>
          </div>
        </div>
      </div>

      {/* Main Table Card */}
      <div className="bg-[#212b31] rounded-xl overflow-hidden border border-[#2a343a] shadow-lg">
        <div className="overflow-x-auto">
          <table className="w-full text-left text-sm whitespace-nowrap border-none">
            <thead>
              <tr className="bg-[#2a343a] text-gray-300">
                <th className="px-6 py-4 font-medium border-none uppercase text-xs tracking-wider">Type</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Destination</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Optimal Distance</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Direct Distance</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Path Nodes</th>
                <th className="px-6 py-4 font-medium border-none uppercase text-xs tracking-wider">Status</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              {routingData.map((data, idx) => {
                const Icon = getTypeIconComponent(data.type);
                const isShorter = data.optimalDistance < data.distance;
                const isLast = idx === routingData.length - 1;

                return (
                  <tr key={data.id} className={`hover:bg-[#2a343a]/30 transition-colors ${!isLast ? 'border-b border-[#2a343a]' : 'border-none'}`}>
                    <td className="px-6 py-4 text-gray-400 border-none">
                      <div className="w-10 h-10 bg-[#182024] rounded border border-[#2a343a] flex items-center justify-center">
                        <Icon size={18} />
                      </div>
                    </td>
                    
                    <td className="px-4 py-4 border-none">
                      <div className="font-medium text-[#00d68f]">
                        {data.name}
                      </div>
                      <div className="text-[10px] text-gray-500 mt-0.5 uppercase tracking-wider">{data.pathNodes.length - 1} HOPS</div>
                    </td>
                    
                    <td className="px-4 py-4 font-medium text-[#00d68f] border-none">
                      {data.optimalDistance} km
                    </td>

                    <td className="px-4 py-4 text-gray-400 border-none">
                      {data.distance} km
                    </td>

                    <td className="px-4 py-4 text-gray-400 border-none">
                      {data.pathNodes.join(' → ')}
                    </td>

                    <td className="px-6 py-4 border-none">
                      {isShorter ? (
                        <span className="text-xs text-emerald-400 font-bold tracking-widest bg-emerald-500/10 border border-emerald-500/20 px-2 py-1 rounded">OPTIMIZED</span>
                      ) : (
                        <span className="text-xs text-gray-500 font-bold tracking-widest bg-gray-900 border border-gray-700 px-2 py-1 rounded">DIRECT</span>
                      )}
                    </td>
                  </tr>
                );
              })}
              {routingData.length === 0 && (
                <tr>
                  <td colSpan="6" className="px-6 py-8 text-center text-gray-500 border-none">
                    No active routes.
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