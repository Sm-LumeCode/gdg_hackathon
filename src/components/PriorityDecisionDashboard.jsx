import React, { useMemo } from 'react';
import { calculatePriority, sortZonesByPriority } from '../utils';

export default function PriorityDecisionDashboard({ zones, onRunAllocation, isAllocated }) {
  const sortedZones = useMemo(() => sortZonesByPriority(zones), [zones]);

  return (
    <div className="bg-white border border-gray-200 p-6">
      <div className="flex justify-between items-center mb-6 border-b border-gray-200 pb-4">
        <div>
          <h2 className="text-xl font-bold text-black">Priority & Decision Dashboard</h2>
          <p className="text-gray-500 text-sm mt-1">Algorithmic ranking of zones based on severity and needs.</p>
        </div>
        <button
          onClick={onRunAllocation}
          className="bg-blue-600 hover:bg-blue-700 text-white font-medium py-2 px-6 border border-blue-700 transition-colors"
        >
          {isAllocated ? 'Re-run Allocation' : 'Run Allocation'}
        </button>
      </div>

      <div className="mb-6 bg-gray-50 border border-gray-200 p-4 text-sm text-gray-700">
        <h3 className="font-bold text-black mb-2">Priority Scoring Logic</h3>
        <p className="mb-1 font-mono bg-white p-2 border border-gray-200 inline-block">
          Priority = (Severity × People Affected) / (Distance × (Resources Present + 1))
        </p>
        <p className="mt-2">
          Zones are ranked higher if they have high severity and affect many people, while being relatively close and having fewer existing resources.
        </p>
      </div>

      <div className="overflow-x-auto">
        <table className="w-full text-sm text-left">
          <thead className="text-xs text-gray-700 uppercase bg-gray-50 border-b border-gray-200">
            <tr>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Rank</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Zone Name</th>
              <th className="px-6 py-4 font-semibold border-r border-gray-200">Priority Score</th>
              <th className="px-6 py-4 font-semibold">Decision Explanation</th>
            </tr>
          </thead>
          <tbody>
            {sortedZones.map((zone, index) => {
              const score = calculatePriority(zone).toFixed(2);
              return (
                <tr key={zone.id} className="border-b border-gray-200 hover:bg-gray-50">
                  <td className="px-6 py-4 font-bold text-gray-900 border-r border-gray-200">
                    #{index + 1}
                  </td>
                  <td className="px-6 py-4 font-medium text-gray-900 border-r border-gray-200">
                    {zone.name}
                  </td>
                  <td className="px-6 py-4 font-mono font-bold text-blue-600 border-r border-gray-200">
                    {score}
                  </td>
                  <td className="px-6 py-4 text-gray-600">
                    {index === 0 ? (
                      <span className="text-black font-medium">Highest priority due to severe conditions.</span>
                    ) : (
                      <span>Ranked #{index + 1} based on {zone.severity} severity and {zone.peopleAffected} people affected.</span>
                    )}
                  </td>
                </tr>
              );
            })}
          </tbody>
        </table>
      </div>
    </div>
  );
}
