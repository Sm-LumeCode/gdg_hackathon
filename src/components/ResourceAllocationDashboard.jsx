import React from 'react';
import { formatResourceAllocation } from '../utils';

export default function ResourceAllocationDashboard({ zones, allocation, availableResources, remainingResources, isAllocated }) {
  return (
    <div className="bg-white border border-gray-200 p-6">
      <div className="mb-6 border-b border-gray-200 pb-4">
        <h2 className="text-xl font-bold text-black">Resource Allocation Dashboard</h2>
        <p className="text-gray-500 text-sm mt-1">Live tracking of distributed emergency resources.</p>
      </div>

      <div className="grid grid-cols-2 gap-6 mb-8">
        <div className="border border-gray-200 p-4">
          <h3 className="text-sm font-bold text-gray-700 uppercase mb-3 border-b border-gray-200 pb-2">Total Capacity</h3>
          <ul className="text-sm space-y-2">
            <li className="flex justify-between"><span>Ambulances:</span> <span className="font-mono font-medium">{availableResources.ambulances}</span></li>
            <li className="flex justify-between"><span>Fire Units:</span> <span className="font-mono font-medium">{availableResources.fireUnits}</span></li>
            <li className="flex justify-between"><span>Rescue Teams:</span> <span className="font-mono font-medium">{availableResources.rescueTeams}</span></li>
            <li className="flex justify-between"><span>Hazmat Teams:</span> <span className="font-mono font-medium">{availableResources.hazmatTeams}</span></li>
          </ul>
        </div>
        <div className="border border-gray-200 p-4 bg-gray-50">
          <h3 className="text-sm font-bold text-gray-700 uppercase mb-3 border-b border-gray-200 pb-2">Remaining Resources</h3>
          {isAllocated ? (
            <ul className="text-sm space-y-2">
              <li className="flex justify-between"><span>Ambulances:</span> <span className="font-mono font-medium text-blue-600">{remainingResources.ambulances}</span></li>
              <li className="flex justify-between"><span>Fire Units:</span> <span className="font-mono font-medium text-blue-600">{remainingResources.fireUnits}</span></li>
              <li className="flex justify-between"><span>Rescue Teams:</span> <span className="font-mono font-medium text-blue-600">{remainingResources.rescueTeams}</span></li>
              <li className="flex justify-between"><span>Hazmat Teams:</span> <span className="font-mono font-medium text-blue-600">{remainingResources.hazmatTeams}</span></li>
            </ul>
          ) : (
            <p className="text-sm text-gray-500 mt-4">Run allocation to see remaining resources.</p>
          )}
        </div>
      </div>

      <h3 className="font-bold text-black mb-4">Zone Assignments</h3>
      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Zone Name</th>
              <th className="px-6 py-4 font-semibold">Assigned Resources</th>
            </tr>
          </thead>
          <tbody>
            {zones.map((zone) => (
              <tr key={zone.id} className="border-b border-gray-200 hover:bg-gray-50">
                <td className="px-6 py-4 font-medium text-gray-900 border-r border-gray-200">
                  {zone.name}
                </td>
                <td className="px-6 py-4 text-gray-700">
                  {isAllocated && allocation && allocation[zone.id] ? (
                    <span className="font-mono text-blue-700">
                      {formatResourceAllocation(allocation[zone.id])}
                    </span>
                  ) : (
                    <span className="text-gray-400 italic">Pending allocation...</span>
                  )}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </div>
  );
}
