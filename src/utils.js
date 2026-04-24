// ============================================================
// UTILS — Priority Engine (Surabhi) + Routing (Lekhya) helpers
// ============================================================

import { Flame, Car, Bomb, Building2, Biohazard, Waves, Activity, AlertTriangle } from 'lucide-react';

// ─── PRIORITY ENGINE (Surabhi's logic) ──────────────────────

export const calculatePriority = (zone) => {
  const { severity, peopleAffected, distance, resourcesPresent } = zone;
  if (distance <= 0) return 0;
  return (severity * peopleAffected) / (distance * (resourcesPresent + 1));
};

export const sortZonesByPriority = (zones) => {
  return [...zones].sort((a, b) => calculatePriority(b) - calculatePriority(a));
};

// ─── DIJKSTRA'S ALGORITHM (Lekhya's logic) ──────────────────
// Returns { distances, previous } maps from sourceNodeId to all nodes.

export const dijkstra = (graph, sourceNodeId) => {
  const allNodes = graph.getAllNodes();

  const distances = new Map();
  const previous = new Map();
  const visited = new Set();

  allNodes.forEach(n => { distances.set(n, Infinity); previous.set(n, null); });
  distances.set(sourceNodeId, 0);

  // Simple min-priority queue using array (good enough for small graphs)
  const pq = [{ node: sourceNodeId, dist: 0 }];

  while (pq.length > 0) {
    // Extract min
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

  // If path reconstruction failed (disconnected graph) return fallback
  if (path.length === 0) return [`HQ`, graph.getNodeLabel(targetNodeId)];
  return path;
};

// Main routing function — returns { distance, path[] } from HQ (node 0) to zone's nodeId
export const calculateShortestPath = (graph, zone) => {
  const targetNodeId = zone.nodeId ?? zone.id;
  const { distances, previous } = dijkstra(graph, 0);

  const dist = distances.get(targetNodeId);
  if (dist === undefined || dist === Infinity) {
    // Fallback: graph doesn't reach this node
    return { distance: zone.distance, path: ['HQ', zone.name] };
  }

  const path = reconstructPath(graph, previous, 0, targetNodeId);
  return { distance: parseFloat(dist.toFixed(2)), path };
};

// ─── RESOURCE ALLOCATION (Lekhya's logic) ───────────────────

export const allocateResources = (zones, availableResources) => {
  const sortedZones = sortZonesByPriority(zones);
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
    fire: Flame,
    accident: Car,
    explosion: Bomb,
    collapse: Building2,
    hazmat: Biohazard,
    flood: Waves,
    medical: Activity,
    unknown: AlertTriangle,
  };
  return icons[type] ?? AlertTriangle;
};