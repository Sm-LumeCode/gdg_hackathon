// ============================================================
// UTILS — Priority Engine (Surabhi) + Routing (Lekhya) helpers
// ============================================================

import { Flame, Car, Bomb, Building2, Biohazard, Waves, Activity, AlertTriangle } from 'lucide-react';

// ─── PRIORITY ENGINE ─────────────────────────────────────────
//
// Formula: Priority = (severity × peopleAffected) / (distance × (resourcesPresent + 1))
//
// Rationale:
//   • severity × peopleAffected  — urgency amplified by scale of impact
//   • distance                   — farther zones are harder to reach quickly
//   • resourcesPresent + 1       — existing resources reduce marginal need;
//                                  +1 prevents division-by-zero when no units present

// Step 2 — Core formula
export const calculatePriority = (zone) => {
  const { severity, peopleAffected, distance, resourcesPresent } = zone;
  if (distance <= 0) return 0;
  return (severity * peopleAffected) / (distance * (resourcesPresent + 1));
};

// Step 3a — Calculate priority for all zones (returns array of { zone, score })
export const updatePriorities = (zones) => {
  return zones.map(zone => ({
    zone,
    score: parseFloat(calculatePriority(zone).toFixed(2)),
  }));
};

// Step 3b — Rank zones using a max-heap (priority queue) in descending priority
// Uses a MinHeap class internally; we negate scores to simulate a max-heap.
class MinHeap {
  constructor() { this._data = []; }

  push(item) {
    this._data.push(item);
    this._bubbleUp(this._data.length - 1);
  }

  pop() {
    const top = this._data[0];
    const last = this._data.pop();
    if (this._data.length > 0) {
      this._data[0] = last;
      this._sinkDown(0);
    }
    return top;
  }

  get size() { return this._data.length; }

  _bubbleUp(i) {
    while (i > 0) {
      const parent = Math.floor((i - 1) / 2);
      if (this._data[parent].key <= this._data[i].key) break;
      [this._data[parent], this._data[i]] = [this._data[i], this._data[parent]];
      i = parent;
    }
  }

  _sinkDown(i) {
    const n = this._data.length;
    while (true) {
      let smallest = i;
      const l = 2 * i + 1, r = 2 * i + 2;
      if (l < n && this._data[l].key < this._data[smallest].key) smallest = l;
      if (r < n && this._data[r].key < this._data[smallest].key) smallest = r;
      if (smallest === i) break;
      [this._data[smallest], this._data[i]] = [this._data[i], this._data[smallest]];
      i = smallest;
    }
  }
}

// Step 4 — rankZones: returns zones sorted descending by priority (max-heap)
export const rankZones = (zones) => {
  const heap = new MinHeap();
  zones.forEach(zone => {
    const score = calculatePriority(zone);
    heap.push({ key: -score, zone }); // negate = max-heap behaviour
  });
  const ranked = [];
  while (heap.size > 0) ranked.push(heap.pop().zone);
  return ranked;
};

// Alias used throughout the app
export const sortZonesByPriority = rankZones;

// Step 3c — explainPriority: human-readable reasoning for a zone's score
export const explainPriority = (zone) => {
  const { severity, peopleAffected, distance, resourcesPresent } = zone;
  const score     = calculatePriority(zone);
  const numerator = severity * peopleAffected;
  const denominator = distance * (resourcesPresent + 1);

  const sevLabel  = severity >= 9 ? 'CRITICAL' : severity >= 7 ? 'HIGH' : severity >= 5 ? 'MODERATE' : 'LOW';
  const distLabel = distance <= 2 ? 'very close' : distance <= 5 ? 'moderate distance' : 'far';
  const resLabel  = resourcesPresent === 0 ? 'no on-site support' : resourcesPresent <= 2 ? 'minimal coverage' : 'partial coverage';

  let verdict;
  if      (score >= 200) verdict = 'IMMEDIATE DISPATCH — extreme impact, scarce coverage.';
  else if (score >= 80)  verdict = 'HIGH URGENCY — significant threat, prioritise quickly.';
  else if (score >= 30)  verdict = 'MODERATE PRIORITY — manageable but monitor closely.';
  else                   verdict = 'LOW PRIORITY — situation appears contained.';

  return {
    score:       parseFloat(score.toFixed(2)),
    formula:     `(${severity} × ${peopleAffected}) / (${distance} × ${resourcesPresent + 1}) = ${numerator} / ${denominator.toFixed(2)}`,
    severityInfo: `${severity}/10 — ${sevLabel}`,
    peopleInfo:   `${peopleAffected} affected`,
    distanceInfo:  `${distance} km (${distLabel})`,
    resourceInfo:  `${resourcesPresent} unit(s) on-site — ${resLabel}`,
    verdict,
  };
};

// ─── DIJKSTRA'S ALGORITHM (Lekhya's logic) ──────────────────
// Returns { distances, previous } maps from sourceNodeId to all nodes.

export const dijkstra = (graph, sourceNodeId) => {
  const allNodes = graph.getAllNodes();

  const distances = new Map();
  const previous  = new Map();
  const visited   = new Set();

  allNodes.forEach(n => { distances.set(n, Infinity); previous.set(n, null); });
  distances.set(sourceNodeId, 0);

  const pq = [{ node: sourceNodeId, dist: 0 }];

  while (pq.length > 0) {
    pq.sort((a, b) => a.dist - b.dist);
    const { node: u, dist: uDist } = pq.shift();

    if (visited.has(u)) continue;
    visited.add(u);

    for (const { to: v, weight } of graph.getNeighbors(u)) {
      if (visited.has(v)) continue;
      const alt = uDist + weight;
      if (alt < distances.get(v)) {
        distances.set(v, alt);
        previous.set(v, u);
        pq.push({ node: v, dist: alt });
      }
    }
  }

  return { distances, previous };
};

// Reconstruct full path from source to target using `previous` map
export const reconstructPath = (graph, previous, sourceNodeId, targetNodeId) => {
  const path = [];
  let current = targetNodeId;

  while (current !== null) {
    path.unshift(graph.getNodeLabel(current));
    current = previous.get(current);
    if (current === sourceNodeId) {
      path.unshift(graph.getNodeLabel(sourceNodeId));
      break;
    }
  }

  if (path.length === 0) return ['HQ', graph.getNodeLabel(targetNodeId)];
  return path;
};

// Main routing function — returns { distance, path[] } from HQ (node 0) to zone's nodeId
export const calculateShortestPath = (graph, zone) => {
  const targetNodeId = zone.nodeId ?? zone.id;
  const { distances, previous } = dijkstra(graph, 0);

  const dist = distances.get(targetNodeId);
  if (dist === undefined || dist === Infinity) {
    return { distance: zone.distance, path: ['HQ', zone.name] };
  }

  const path = reconstructPath(graph, previous, 0, targetNodeId);
  return { distance: parseFloat(dist.toFixed(2)), path };
};

// ─── RESOURCE ALLOCATION (Lekhya's logic) ───────────────────

export const allocateResources = (zones, availableResources) => {
  const sortedZones = rankZones(zones);
  const allocation = {};
  let remainingResources = { ...availableResources };

  sortedZones.forEach(zone => {
    allocation[zone.id] = { ambulances: 0, fireUnits: 0, rescueTeams: 0, hazmatTeams: 0 };

    const needsAmbulances  = zone.peopleAffected > 0;
    const needsFireUnits   = zone.type === 'fire' || zone.type === 'explosion';
    const needsRescueTeams = zone.type === 'collapse' || zone.type === 'explosion';
    const needsHazmatTeams = zone.type === 'hazmat';

    if (needsAmbulances && remainingResources.ambulances > 0) {
      const needed = Math.min(Math.ceil(zone.peopleAffected / 10), remainingResources.ambulances, 5);
      allocation[zone.id].ambulances = needed;
      remainingResources.ambulances -= needed;
    }
    if (needsFireUnits && remainingResources.fireUnits > 0) {
      const needed = Math.min(2, remainingResources.fireUnits);
      allocation[zone.id].fireUnits = needed;
      remainingResources.fireUnits -= needed;
    }
    if (needsRescueTeams && remainingResources.rescueTeams > 0) {
      const needed = Math.min(2, remainingResources.rescueTeams);
      allocation[zone.id].rescueTeams = needed;
      remainingResources.rescueTeams -= needed;
    }
    if (needsHazmatTeams && remainingResources.hazmatTeams > 0) {
      allocation[zone.id].hazmatTeams = remainingResources.hazmatTeams;
      remainingResources.hazmatTeams = 0;
    }
  });

  return { allocation, sortedZones, remainingResources };
};

// ─── DISPLAY HELPERS ────────────────────────────────────────

export const formatResourceAllocation = (allocation) => {
  const parts = [];
  if (allocation.ambulances  > 0) parts.push(`${allocation.ambulances} Ambulance${allocation.ambulances  > 1 ? 's' : ''}`);
  if (allocation.fireUnits   > 0) parts.push(`${allocation.fireUnits} Fire Unit${allocation.fireUnits    > 1 ? 's' : ''}`);
  if (allocation.rescueTeams > 0) parts.push(`${allocation.rescueTeams} Rescue Team${allocation.rescueTeams > 1 ? 's' : ''}`);
  if (allocation.hazmatTeams > 0) parts.push(`${allocation.hazmatTeams} Hazmat Team${allocation.hazmatTeams > 1 ? 's' : ''}`);
  return parts.length > 0 ? parts.join(', ') : 'No resources';
};

export const getSeverityColor = (severity) => {
  if (severity >= 9) return '#ef4444';
  if (severity >= 7) return '#f97316';
  if (severity >= 5) return '#eab308';
  return '#22c55e';
};

export const getSeverityLabel = (severity) => {
  if (severity >= 9) return 'Critical';
  if (severity >= 7) return 'High';
  if (severity >= 5) return 'Medium';
  return 'Low';
};

export const getTypeIconComponent = (type) => {
  const icons = {
    fire:     Flame,
    accident: Car,
    explosion:Bomb,
    collapse: Building2,
    hazmat:   Biohazard,
    flood:    Waves,
    medical:  Activity,
    unknown:  AlertTriangle,
  };
  return icons[type] ?? AlertTriangle;
};

// ─── ADAPTIVE RECALCULATION (Auto-update when zones change) ───

/**
 * Adaptively recalculates priorities and resource allocation when zone conditions change.
 * This function is called whenever a zone is updated (severity, people affected, etc.)
 * 
 * @param {Zone[]} zones - Current zones with updated values
 * @param {Object} availableResources - Total available resources
 * @param {Object} currentAllocation - Current allocation state (can be null)
 * @returns {Object} { allocation, sortedZones, remainingResources, changes }
 */
export const adaptiveRecalculate = (zones, availableResources, currentAllocation = null) => {
  // Step 1: Recalculate priorities for all zones based on current state
  const priorityScores = zones.map(zone => ({
    zone,
    score: calculatePriority(zone),
  }));

  // Step 2: Identify zones with changed priorities (if previous allocation exists)
  const changes = {};
  if (currentAllocation) {
    priorityScores.forEach(({ zone, score }) => {
      const oldAllocation = currentAllocation[zone.id];
      if (oldAllocation) {
        const hasResourceChange = 
          zone.severity !== zone._lastSeverity ||
          zone.peopleAffected !== zone._lastPeopleAffected ||
          zone.resourcesPresent !== zone._lastResourcesPresent;
        
        if (hasResourceChange) {
          changes[zone.id] = {
            zone,
            oldScore: calculatePriority({ ...zone, severity: zone._lastSeverity, peopleAffected: zone._lastPeopleAffected, resourcesPresent: zone._lastResourcesPresent }),
            newScore: score,
            scoreChanged: true,
          };
        }
      }
    });
  }

  // Step 3: Re-allocate resources based on new priorities
  const { allocation, sortedZones, remainingResources } = allocateResources(zones, availableResources);

  // Step 4: Store current values for next comparison
  zones.forEach(zone => {
    zone._lastSeverity = zone.severity;
    zone._lastPeopleAffected = zone.peopleAffected;
    zone._lastResourcesPresent = zone.resourcesPresent;
  });

  return {
    allocation,
    sortedZones,
    remainingResources,
    changes,
    recalculatedAt: Date.now(),
  };
};

/**
 * Batch recalculate: called when multiple zone updates happen in quick succession.
 * Debounces rapid updates to avoid excessive recalculations.
 * 
 * @param {Zone[]} zones - Updated zones
 * @param {Object} availableResources - Available resources
 * @param {Function} onRecalculate - Callback function when recalculation is ready
 * @param {number} debounceMs - Debounce delay in milliseconds (default: 300ms)
 * @returns {Function} Cancel function to stop pending recalculation
 */
export const createAdaptiveRecalculationThrottle = (debounceMs = 300) => {
  let timeoutId = null;
  
  return {
    trigger: (zones, availableResources, currentAllocation, onRecalculate) => {
      // Cancel previous pending recalculation
      if (timeoutId) clearTimeout(timeoutId);
      
      // Schedule new recalculation
      timeoutId = setTimeout(() => {
        const result = adaptiveRecalculate(zones, availableResources, currentAllocation);
        onRecalculate(result);
      }, debounceMs);
    },
    cancel: () => {
      if (timeoutId) clearTimeout(timeoutId);
    },
  };
};