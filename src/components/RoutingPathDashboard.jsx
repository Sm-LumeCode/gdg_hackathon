import React, { useMemo } from 'react';
import { calculateShortestPath } from '../utils';

export default function RoutingPathDashboard({ zones }) {
  // Simulate routing from a central HQ to each zone
  const hqZone = { id: 'hq', name: 'Central Command HQ', distance: 0 };

  const routingData = useMemo(() => {
    return zones.map(zone => {
      // Use our mock shortest path util
      const optimalPathDistance = calculateShortestPath(hqZone, zone);
      // Simulate intermediate nodes
      const nodes = ['HQ'];
      if (zone.distance > 2) nodes.push('Waypoint Alpha');
      if (zone.distance > 5) nodes.push('Waypoint Beta');
      nodes.push(zone.name);

      return {
        ...zone,
        optimalPathDistance,
        pathRoute: nodes.join(' → ')
      };
    });
  }, [zones]);

  return (
    <div className="bg-white border border-gray-200 p-6">
      <div className="mb-6 border-b border-gray-200 pb-4">
        <h2 className="text-xl font-bold text-black">Routing & Path Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Shortest path calculations from HQ to crisis zones (Dijkstra simulation).</p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Destination Zone</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Direct Distance</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Calculated Path Distance</th>
              <th className="px-6 py-4 font-semibold">Suggested Route</th>
            </tr>
          </thead>
          <tbody>
            {routingData.map((data) => (
              <tr key={data.id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="px-6 py-4 font-medium text-gray-900 border-r border-gray-200">
                  {data.name}
                </td>
                <td className="px-6 py-4 text-gray-600 border-r border-gray-200">
                  {data.distance} km
                </td>
                <td className="px-6 py-4 font-mono font-bold text-blue-600 border-r border-gray-200">
                  {data.optimalPathDistance} km
                </td>
                <td className="px-6 py-4 text-gray-600 font-mono text-xs">
                  {data.pathRoute}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
