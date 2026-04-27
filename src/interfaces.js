/**
 * interfaces.js
 * =============
 * VEEKSHA's responsibility: Define the contracts (interfaces) that each
 * teammate must fulfill. These are STUB implementations — real logic
 * will come from Surabhi, Lekhya, and Spandana when they push.
 *
 * MENTOR NOTE (for placements):
 * This pattern is called "programming to an interface."
 * In C, you'd do this with .h header files declaring function signatures.
 * In Java/TypeScript, you'd use actual interface/abstract class keywords.
 * In JS, we document and stub it manually.
 *
 * Why does this matter?
 * → Your controller can be written TODAY without waiting for teammates.
 * → When they push, you just swap the stub with the real implementation.
 * → This is exactly how large codebases (Linux kernel, Chrome) are built.
 */

// ============================================================
// SURABHI's module — Priority Engine
// When Surabhi pushes, replace this entire block with:
//   import { calculatePriority, updatePriorities, getTopZones }
//   from './priorityEngine.js'
// ============================================================

/**
 * calculatePriority(zone) → number
 *
 * Formula: (severity × peopleAffected) / (distance × (resourcesPresent + 1))
 * Returns a floating point priority score.
 *
 * @param {Object} zone - A zone object from Spandana's data model
 * @returns {number} priority score (higher = more urgent)
 */
export function calculatePriority(zone) {
  // STUB: Basic formula. Surabhi will replace with adaptive version.
  const numerator = zone.severity * zone.peopleAffected;
  const denominator = zone.distance * (zone.resourcesPresent + 1);
  return parseFloat((numerator / denominator).toFixed(2));
}

/**
 * updatePriorities(zones) → Zone[]
 *
 * Recalculates priority scores for all zones.
 * Called after any state change (new incident, severity change, etc.)
 *
 * @param {Zone[]} zones - Array of zone objects
 * @returns {Zone[]} Same zones with updated priorityScore field
 */
export function updatePriorities(zones) {
  // STUB: Surabhi will implement adaptive recalculation (time decay, etc.)
  return zones.map((zone) => ({
    ...zone,
    priorityScore: calculatePriority(zone),
  }));
}

/**
 * getTopZones(zones, n) → Zone[]
 *
 * Returns the top N zones sorted by priority (descending).
 * Think of this as extracting from a max-heap.
 *
 * @param {Zone[]} zones - Array of zones (with priorityScore set)
 * @param {number} n - How many top zones to return
 * @returns {Zone[]} Top N zones sorted by priority
 */
export function getTopZones(zones, n = 3) {
  // STUB: Surabhi will implement with an actual heap data structure.
  return [...zones]
    .sort((a, b) => (b.priorityScore || 0) - (a.priorityScore || 0))
    .slice(0, n);
}

// ============================================================
// LEKHYA's module — Resource Allocation + Routing Engine
// When Lekhya pushes, replace this block with:
//   import { shortestPath, allocateBestResource, updateResourceStatus }
//   from './allocationEngine.js'
// ============================================================

/**
 * shortestPath(graph, sourceId, zoneId) → { path, distance }
 *
 * Dijkstra's algorithm on the road graph.
 * Returns the shortest path and total distance from source to zone.
 *
 * @param {Graph} graph - Spandana's Graph data structure
 * @param {string} sourceId - Resource depot node ID
 * @param {string} zoneId - Target crisis zone node ID
 * @returns {{ path: string[], distance: number }}
 */
export function shortestPath(graph, sourceId, zoneId) {
  // STUB: Lekhya will implement Dijkstra's here.
  // For now, return a mock result using the zone's distance field.
  if (!graph || !graph.nodes) {
    return { path: [sourceId, zoneId], distance: 5.0 };
  }
  const zone = graph.nodes[zoneId];
  return {
    path: [sourceId, zoneId],
    distance: zone ? zone.distance : 5.0,
  };
}

/**
 * allocateBestResource(zone, availableResources, graph) → AllocationResult
 *
 * Given a zone and available resources, picks the optimal resource
 * considering type match AND shortest path distance.
 *
 * @param {Zone} zone
 * @param {Resource[]} availableResources
 * @param {Graph} graph
 * @returns {{ ambulances, fireUnits, rescueTeams, hazmatTeams }}
 */
export function allocateBestResource(zone, availableResources, graph) {
  // STUB: Lekhya will implement distance-aware allocation.
  const result = {
    ambulances: 0,
    fireUnits: 0,
    rescueTeams: 0,
    hazmatTeams: 0,
  };

  if (availableResources.ambulances > 0) {
    const needed = Math.max(1, Math.ceil(zone.peopleAffected / 30));
    result.ambulances = Math.min(needed, availableResources.ambulances);
  }
  if (["fire", "explosion"].includes(zone.type) && availableResources.fireUnits > 0) {
    result.fireUnits = Math.min(Math.ceil(zone.severity / 3), availableResources.fireUnits);
  }
  if (["collapse", "explosion"].includes(zone.type) && availableResources.rescueTeams > 0) {
    result.rescueTeams = Math.min(zone.severity >= 8 ? 2 : 1, availableResources.rescueTeams);
  }
  if (zone.type === "hazmat" && availableResources.hazmatTeams > 0) {
    result.hazmatTeams = Math.min(1, availableResources.hazmatTeams);
  }
  return result;
}

/**
 * updateResourceStatus(resources, allocated) → Resources
 *
 * Deducts allocated resources from the pool.
 *
 * @param {Object} resources - Current resource pool
 * @param {Object} allocated - What was just allocated to one zone
 * @returns {Object} Updated resource pool
 */
export function updateResourceStatus(resources, allocated) {
  // STUB: Lekhya will handle more complex status tracking (en-route, busy, etc.)
  return {
    ambulances: Math.max(0, resources.ambulances - (allocated.ambulances || 0)),
    fireUnits: Math.max(0, resources.fireUnits - (allocated.fireUnits || 0)),
    rescueTeams: Math.max(0, resources.rescueTeams - (allocated.rescueTeams || 0)),
    hazmatTeams: Math.max(0, resources.hazmatTeams - (allocated.hazmatTeams || 0)),
  };
}

// ============================================================
// SPANDANA's module — Data Modeling & State Management
// When Spandana pushes, replace this block with:
//   import { createZone, createResource, createGraph, validateState }
//   from './dataModel.js'
// ============================================================

/**
 * createZone(overrides) → Zone
 *
 * Factory function for creating a Zone object with defaults.
 * Ensures all zones have the same shape (data consistency).
 *
 * @param {Partial<Zone>} overrides
 * @returns {Zone}
 */
export function createZone(overrides = {}) {
  // STUB: Spandana will implement with full validation.
  return {
    id: overrides.id || `zone_${Date.now()}`,
    name: overrides.name || "Unknown Zone",
    type: overrides.type || "collision",
    severity: overrides.severity || 5,
    peopleAffected: overrides.peopleAffected || 50,
    distance: overrides.distance || 3.0,
    resourcesPresent: overrides.resourcesPresent || 0,
    priorityScore: 0,
    status: overrides.status || "active", // active | resolved | escalated
    timestamp: overrides.timestamp || Date.now(),
    ...overrides,
  };
}

/**
 * validateState(state) → { valid: boolean, errors: string[] }
 *
 * Checks system state for consistency.
 * E.g., resources allocated can't exceed resources available.
 *
 * @param {SystemState} state
 * @returns {{ valid: boolean, errors: string[] }}
 */
export function validateState(state) {
  // STUB: Spandana will implement comprehensive validation.
  const errors = [];
  if (!state.zones || !Array.isArray(state.zones)) {
    errors.push("State must have a zones array");
  }
  if (!state.resources) {
    errors.push("State must have a resources object");
  }
  return { valid: errors.length === 0, errors };
}
