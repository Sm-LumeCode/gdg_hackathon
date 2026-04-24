import React, { createContext, useContext, useState, useCallback } from 'react';
import { mockCrisisZones, availableResources, buildInitialGraph, Zone } from '../data';
import { allocateResources } from '../utils';

const CrisisContext = createContext(null);

export const CrisisProvider = ({ children }) => {
  const [zones, setZones] = useState(mockCrisisZones);
  const [graph, setGraph] = useState(buildInitialGraph());
  const [allocation, setAllocation] = useState(null);
  const [isAllocated, setIsAllocated] = useState(false);
  const [remainingResources, setRemainingResources] = useState(availableResources);
  const [searchQuery, setSearchQuery] = useState('');

  // Spandana's State Update Functions

  const addZone = useCallback((zoneData) => {
    setZones(prev => [...prev, new Zone(zoneData)]);
  }, []);

  const updateZoneField = useCallback((id, field, value) => {
    setZones(prev => prev.map(z => {
      if (z.id === id) {
        const updatedZone = new Zone({ ...z, [field]: value });
        return updatedZone;
      }
      return z;
    }));
  }, []);

  const runAllocation = useCallback(() => {
    const { allocation: newAllocation, sortedZones, remainingResources: rem } = allocateResources(zones, availableResources);
    setAllocation(newAllocation);
    setZones(sortedZones);
    setIsAllocated(true);
    setRemainingResources(rem);
  }, [zones]);

  const resetAllocation = useCallback(() => {
    setAllocation(null);
    setIsAllocated(false);
    setRemainingResources(availableResources);
  }, []);

  const filteredZones = React.useMemo(() => {
    if (!searchQuery.trim()) return zones;
    const q = searchQuery.toLowerCase();
    return zones.filter(z => 
      z.name.toLowerCase().includes(q) || 
      z.type.toLowerCase().includes(q)
    );
  }, [zones, searchQuery]);

  const value = {
    zones: filteredZones,
    rawZones: zones,
    searchQuery,
    setSearchQuery,
    graph,
    allocation,
    isAllocated,
    remainingResources,
    addZone,
    updateZoneField,
    runAllocation,
    resetAllocation,
    totalResources: availableResources
  };

  return (
    <CrisisContext.Provider value={value}>
      {children}
    </CrisisContext.Provider>
  );
};

export const useCrisisContext = () => {
  const context = useContext(CrisisContext);
  if (!context) {
    throw new Error('useCrisisContext must be used within a CrisisProvider');
  }
  return context;
};
