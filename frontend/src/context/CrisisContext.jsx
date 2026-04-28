import React, { createContext, useContext, useState, useCallback, useRef, useEffect } from 'react';
import { mockCrisisZones, availableResources, buildInitialGraph, Zone } from '../data';
import { allocateResources, adaptiveRecalculate, createAdaptiveRecalculationThrottle } from '../utils';

const CrisisContext = createContext(null);

export const CrisisProvider = ({ children }) => {
  const [zones, setZones] = useState(mockCrisisZones);
  const [graph, setGraph] = useState(buildInitialGraph());
  const [allocation, setAllocation] = useState(null);
  const [isAllocated, setIsAllocated] = useState(false);
  const [remainingResources, setRemainingResources] = useState(availableResources);
  const [searchQuery, setSearchQuery] = useState('');
  const [lastRecalculationTime, setLastRecalculationTime] = useState(null);
  const [recalculationChanges, setRecalculationChanges] = useState({});
  
  // Throttle rapid updates (e.g., slider changes)
  const throttleRef = useRef(createAdaptiveRecalculationThrottle(300));

  // Spandana's State Update Functions

  const addZone = useCallback((zoneData) => {
    setZones(prev => [...prev, new Zone(zoneData)]);
  }, []);

  const updateZoneField = useCallback((id, field, value) => {
    setZones(prev => {
      const updated = prev.map(z => {
        if (z.id === id) {
          const updatedZone = new Zone({ ...z, [field]: value });
          return updatedZone;
        }
        return z;
      });

      // Trigger adaptive recalculation if already allocated
      if (isAllocated && ['severity', 'peopleAffected', 'resourcesPresent'].includes(field)) {
        throttleRef.current.trigger(
          updated,
          availableResources,
          allocation,
          (result) => {
            setAllocation(result.allocation);
            setZones(result.sortedZones);
            setRemainingResources(result.remainingResources);
            setLastRecalculationTime(result.recalculatedAt);
            setRecalculationChanges(result.changes);
          }
        );
      }

      return updated;
    });
  }, [isAllocated, allocation]);

  const runAllocation = useCallback(() => {
    const { allocation: newAllocation, sortedZones, remainingResources: rem } = allocateResources(zones, availableResources);
    
    // Initialize last values for adaptive recalculation tracking
    sortedZones.forEach(zone => {
      zone._lastSeverity = zone.severity;
      zone._lastPeopleAffected = zone.peopleAffected;
      zone._lastResourcesPresent = zone.resourcesPresent;
    });
    
    setAllocation(newAllocation);
    setZones(sortedZones);
    setIsAllocated(true);
    setRemainingResources(rem);
    setLastRecalculationTime(Date.now());
    setRecalculationChanges({});
  }, [zones]);

  const resetAllocation = useCallback(() => {
    throttleRef.current.cancel();
    setAllocation(null);
    setIsAllocated(false);
    setRemainingResources(availableResources);
    setLastRecalculationTime(null);
    setRecalculationChanges({});
  }, []);

  const filteredZones = React.useMemo(() => {
    if (!searchQuery.trim()) return zones;
    const q = searchQuery.toLowerCase();
    return zones.filter(z => 
      z.name.toLowerCase().includes(q) || 
      z.type.toLowerCase().includes(q)
    );
  }, [zones, searchQuery]);

  // Cleanup throttle on unmount
  useEffect(() => {
    return () => {
      throttleRef.current.cancel();
    };
  }, []);

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
    totalResources: availableResources,
    // Adaptive recalculation info
    lastRecalculationTime,
    recalculationChanges,
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
