import React, { useState, useMemo } from 'react';
import { getSeverityLabel, getTypeIconComponent } from '../utils';
import { useCrisisContext } from '../context/CrisisContext';
import { Activity, Users, AlertTriangle, ShieldCheck, MapPin } from 'lucide-react';
import { PieChart, Pie, Cell, Tooltip, Legend, ResponsiveContainer } from 'recharts';

export default function ZoneMonitoringDashboard() {
  const { zones, updateZoneField, addZone } = useCrisisContext();
  const [addingZone, setAddingZone] = useState(false);
  const [newZone, setNewZone] = useState({ name: '', severity: 5, peopleAffected: 0, distance: 1.0, resourcesPresent: 0, type: 'unknown' });

  const handleUpdate = (id, field, value) => {
    const parsed = field === 'distance' ? parseFloat(value) : parseInt(value, 10);
    if (isNaN(parsed)) return;
    updateZoneField(id, field, parsed);
  };

  const handleAddZone = () => {
    if (!newZone.name.trim()) return;
    const nextId = Math.max(0, ...zones.map(z => z.id)) + 1;
    addZone({ ...newZone, id: nextId, nodeId: nextId });
    setNewZone({ name: '', severity: 5, peopleAffected: 0, distance: 1.0, resourcesPresent: 0, type: 'unknown' });
    setAddingZone(false);
  };

  const typeOptions = ['fire', 'accident', 'explosion', 'collapse', 'hazmat', 'flood', 'medical', 'unknown'];

  // Calculate Statistics
  const totalZones = zones.length;
  const totalAffected = zones.reduce((sum, z) => sum + z.peopleAffected, 0);
  const criticalCases = zones.filter(z => z.severity >= 8).length;
  const avgSeverity = totalZones > 0 ? (zones.reduce((sum, z) => sum + z.severity, 0) / totalZones).toFixed(1) : 0;

  // Calculate Chart Data
  const chartData = useMemo(() => {
    const counts = {};
    zones.forEach(z => {
      counts[z.type] = (counts[z.type] || 0) + 1;
    });
    return Object.entries(counts).map(([name, count]) => ({
      name: name.charAt(0).toUpperCase() + name.slice(1),
      value: count
    }));
  }, [zones]);

  const COLORS = ['#00d68f', '#3b82f6', '#f43f5e', '#eab308', '#a855f7', '#14b8a6', '#f97316'];

  return (
    <div className="flex flex-col space-y-6 pb-12">
      {/* Top Action Bar */}
      <div className="flex items-center justify-between">
        <h1 className="text-xl font-semibold text-white tracking-wide">Dashboard</h1>
        
        <div className="flex items-center gap-4">
          <button 
            onClick={() => setAddingZone(!addingZone)}
            className="px-4 py-2 text-sm font-semibold bg-[#00d68f] text-[#182024] rounded-md hover:bg-[#00b579] transition-colors"
          >
            {addingZone ? 'Cancel' : 'Add Zone'}
          </button>
        </div>
      </div>

      {/* Analytics Row */}
      <div className="flex gap-6 h-[220px]">
        
        {/* Stats Panel (2x2 Grid) */}
        <div className="w-1/2 grid grid-cols-2 gap-4">
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex items-center justify-between">
             <div>
               <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mb-1">Total Active Zones</p>
               <h3 className="text-3xl font-bold text-[#00d68f]">{totalZones}</h3>
             </div>
             <div className="w-10 h-10 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Activity size={18} className="text-[#00d68f]" />
             </div>
          </div>
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex items-center justify-between">
             <div>
               <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mb-1">Total People Affected</p>
               <h3 className="text-3xl font-bold text-blue-400">{totalAffected}</h3>
             </div>
             <div className="w-10 h-10 rounded-full bg-[#182024] border border-[#2a343a] flex items-center justify-center shrink-0">
               <Users size={18} className="text-blue-400" />
             </div>
          </div>
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex items-center justify-between">
             <div>
               <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mb-1">Critical Incidents</p>
               <h3 className="text-3xl font-bold text-red-400">{criticalCases}</h3>
             </div>
             <div className="w-10 h-10 rounded-full bg-red-500/10 border border-red-500/20 flex items-center justify-center shrink-0">
               <AlertTriangle size={18} className="text-red-400" />
             </div>
          </div>
          <div className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex items-center justify-between">
             <div>
               <p className="text-gray-400 text-[10px] font-bold tracking-widest uppercase mb-1">Average Severity</p>
               <h3 className="text-3xl font-bold text-yellow-400">{avgSeverity}</h3>
             </div>
             <div className="w-10 h-10 rounded-full bg-yellow-500/10 border border-yellow-500/20 flex items-center justify-center shrink-0">
               <ShieldCheck size={18} className="text-yellow-400" />
             </div>
          </div>
        </div>

        {/* Chart Panel (Pie Chart) */}
        <div className="w-1/2 bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg p-5 flex flex-col items-center">
          <h3 className="text-white font-semibold tracking-wide text-sm w-full text-left">Incident Distribution</h3>
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
                <Legend 
                  verticalAlign="middle" 
                  align="right" 
                  layout="vertical" 
                  iconType="circle"
                  wrapperStyle={{ fontSize: '11px', color: '#9ca3af' }}
                />
                <Tooltip 
                  contentStyle={{ backgroundColor: '#182024', border: '1px solid #2a343a', borderRadius: '8px', color: '#fff', fontSize: '12px' }} 
                  itemStyle={{ color: '#fff' }}
                />
              </PieChart>
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
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Zone Title</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Category</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Affected</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Distance</th>
                <th className="px-4 py-4 font-medium border-none uppercase text-xs tracking-wider">Resources</th>
                <th className="px-6 py-4 font-medium border-none uppercase text-xs tracking-wider">Severity</th>
              </tr>
            </thead>
            <tbody className="text-gray-300">
              {zones.map((zone, idx) => {
                const Icon = getTypeIconComponent(zone.type);
                const isCritical = zone.severity >= 9;
                const isLast = idx === zones.length - 1 && !addingZone;
                
                return (
                  <tr key={zone.id} className={`hover:bg-[#2a343a]/30 transition-colors ${!isLast ? 'border-b border-[#2a343a]' : 'border-none'}`}>
                    <td className="px-6 py-4 text-gray-400 border-none">
                      <div className="w-10 h-10 bg-[#182024] rounded border border-[#2a343a] flex items-center justify-center">
                        <Icon size={18} />
                      </div>
                    </td>
                    
                    <td className="px-4 py-4 border-none">
                      <div className={`font-medium ${isCritical ? 'text-red-400' : 'text-[#00d68f]'}`}>
                        {zone.name}
                      </div>
                      <div className="text-[10px] text-gray-500 mt-0.5 uppercase tracking-wider">{zone.type}</div>
                    </td>
                    
                    <td className="px-4 py-4 text-gray-400 capitalize border-none">
                      {zone.type}
                    </td>

                    <td className="px-4 py-4 border-none">
                      <input type="number" min="0" value={zone.peopleAffected}
                        onChange={e => handleUpdate(zone.id, 'peopleAffected', e.target.value)}
                        className="w-16 bg-transparent border border-transparent hover:border-gray-600 focus:border-[#00d68f] rounded px-2 py-1 text-gray-300 outline-none transition-colors"
                      />
                    </td>

                    <td className="px-4 py-4 font-medium border-none">
                      <div className="flex items-center gap-1.5 text-gray-400">
                        <MapPin size={14} className="text-[#00d68f]" />
                        <input type="number" step="0.1" min="0" value={zone.distance}
                          onChange={e => handleUpdate(zone.id, 'distance', e.target.value)}
                          className="w-14 bg-transparent border border-transparent hover:border-gray-600 focus:border-[#00d68f] rounded px-1 py-1 text-gray-300 outline-none transition-colors"
                        />
                        <span className="text-xs">km</span>
                      </div>
                    </td>

                    <td className="px-4 py-4 border-none">
                      <input type="number" min="0" value={zone.resourcesPresent}
                        onChange={e => handleUpdate(zone.id, 'resourcesPresent', e.target.value)}
                        className="w-16 bg-transparent border border-transparent hover:border-gray-600 focus:border-[#00d68f] rounded px-2 py-1 text-gray-300 outline-none transition-colors"
                      />
                    </td>

                    <td className="px-6 py-4 border-none">
                      <div className="flex items-center gap-3">
                        <span className="text-sm w-16">{getSeverityLabel(zone.severity)}</span>
                        <input 
                          type="number" min="1" max="10" value={zone.severity}
                          onChange={e => handleUpdate(zone.id, 'severity', e.target.value)}
                          className="w-12 bg-[#182024] border border-[#2a343a] rounded px-2 py-1 text-gray-300 focus:border-[#00d68f] outline-none text-center"
                        />
                      </div>
                    </td>
                  </tr>
                );
              })}

              {/* Add Zone Row */}
              {addingZone && (
                <tr className="bg-[#182024]/50 border-t border-[#2a343a]">
                  <td className="px-6 py-4 border-none">
                    <select value={newZone.type} onChange={e => setNewZone({ ...newZone, type: e.target.value })}
                      className="w-full bg-[#182024] border border-[#2a343a] text-gray-300 px-2 py-1.5 rounded outline-none focus:border-[#00d68f]">
                      {typeOptions.map(t => <option key={t} value={t}>{t}</option>)}
                    </select>
                  </td>
                  <td className="px-4 py-4 border-none">
                    <input placeholder="New Zone Name" value={newZone.name}
                      onChange={e => setNewZone({ ...newZone, name: e.target.value })}
                      className="w-full bg-[#182024] border border-[#2a343a] text-gray-300 px-3 py-1.5 rounded outline-none focus:border-[#00d68f]"
                    />
                  </td>
                  <td className="px-4 py-4 text-gray-500 border-none">Auto</td>
                  <td className="px-4 py-4 border-none">
                    <input type="number" min="0" value={newZone.peopleAffected}
                      onChange={e => setNewZone({ ...newZone, peopleAffected: parseInt(e.target.value) || 0 })}
                      className="w-16 bg-[#182024] border border-[#2a343a] text-gray-300 px-2 py-1.5 rounded outline-none focus:border-[#00d68f]"
                    />
                  </td>
                  <td className="px-4 py-4 border-none">
                    <input type="number" step="0.1" min="0.1" value={newZone.distance}
                      onChange={e => setNewZone({ ...newZone, distance: parseFloat(e.target.value) || 0.1 })}
                      className="w-16 bg-[#182024] border border-[#2a343a] text-gray-300 px-2 py-1.5 rounded outline-none focus:border-[#00d68f]"
                    />
                  </td>
                  <td className="px-4 py-4 border-none">
                    <input type="number" min="0" value={newZone.resourcesPresent}
                      onChange={e => setNewZone({ ...newZone, resourcesPresent: parseInt(e.target.value) || 0 })}
                      className="w-16 bg-[#182024] border border-[#2a343a] text-gray-300 px-2 py-1.5 rounded outline-none focus:border-[#00d68f]"
                    />
                  </td>
                  <td className="px-6 py-4 flex gap-2 items-center border-none h-[72px]">
                    <span className="w-16 text-xs text-gray-500">New</span>
                    <input type="number" min="1" max="10" value={newZone.severity}
                      onChange={e => setNewZone({ ...newZone, severity: parseInt(e.target.value) || 1 })}
                      className="w-12 bg-[#182024] border border-[#2a343a] text-gray-300 px-2 py-1.5 rounded outline-none focus:border-[#00d68f] text-center"
                    />
                    <button onClick={handleAddZone}
                      className="bg-[#00d68f] text-[#182024] font-semibold px-3 py-1.5 rounded hover:bg-[#00b579] transition-colors ml-2">
                      Save
                    </button>
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