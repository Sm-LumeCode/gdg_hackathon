import React from 'react';

export default function ZoneMonitoringDashboard({ zones, setZones }) {
  const handleUpdate = (id, field, value) => {
    const parsedValue = parseInt(value, 10);
    if (isNaN(parsedValue)) return;
    
    const newZones = zones.map(zone => 
      zone.id === id ? { ...zone, [field]: parsedValue } : zone
    );
    setZones(newZones);
  };

  return (
    <div className="bg-white border border-gray-200 p-6">
      <div className="mb-6 border-b border-gray-200 pb-4">
        <h2 className="text-xl font-bold text-black">Zone Monitoring Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Live overview and monitoring of all crisis zones.</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Zone Name</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Severity (1-10)</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">People Affected</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Distance (km)</th>
              <th className="px-6 py-4 font-semibold">Resources Present</th>
            </tr>
          </thead>
          <tbody>
            {zones.map((zone) => (
              <tr key={zone.id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="px-6 py-4 font-medium text-gray-900 border-r border-gray-200">
                  {zone.name}
                </td>
                <td className="px-6 py-4 border-r border-gray-200">
                  <input 
                    type="number" 
                    min="1" max="10" 
                    value={zone.severity}
                    onChange={(e) => handleUpdate(zone.id, 'severity', e.target.value)}
                    className="w-full bg-white border border-gray-300 text-gray-900 text-sm focus:ring-blue-500 focus:border-blue-500 block p-2"
                  />
                </td>
                <td className="px-6 py-4 border-r border-gray-200">
                  <input 
                    type="number" 
                    min="0"
                    value={zone.peopleAffected}
                    onChange={(e) => handleUpdate(zone.id, 'peopleAffected', e.target.value)}
                    className="w-full bg-white border border-gray-300 text-gray-900 text-sm focus:ring-blue-500 focus:border-blue-500 block p-2"
                  />
                </td>
                <td className="px-6 py-4 border-r border-gray-200">
                  {zone.distance}
                </td>
                <td className="px-6 py-4">
                  <input 
                    type="number" 
                    min="0"
                    value={zone.resourcesPresent}
                    onChange={(e) => handleUpdate(zone.id, 'resourcesPresent', e.target.value)}
                    className="w-full bg-white border border-gray-300 text-gray-900 text-sm focus:ring-blue-500 focus:border-blue-500 block p-2"
                  />
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
