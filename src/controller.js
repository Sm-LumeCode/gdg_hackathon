/**
 * controller.js
 * =============
 * VEEKSHA's main file — The Orchestrator / Execution Pipeline
 *
 * This is your main() equivalent. It:
 * 1. Loads data (from simulator or real input)
 * 2. Calls Surabhi's priority engine
 * 3. Calls Lekhya's allocation + routing
 * 4. Updates Spandana's state
 * 5. Returns a complete SystemResult for the UI
 *
 * MENTOR NOTE (for placements):
 * This pattern is called the "Pipeline" or "Chain of Responsibility."
 * Think of Unix pipes: cat data.txt | sort | grep "fire" | head -5
 * Each stage transforms the data and passes it forward.
 * In C, you'd have main() calling functions sequentially,
 * each returning a struct that the next function consumes.
 *
 * Data flow:
 *   Raw Scenario
 *       ↓
 *   [Surabhi] Calculate & sort priorities
 *       ↓
 *   [Lekhya]  Allocate resources + shortest path
 *       ↓
 *   [Spandana] Validate & persist state
 *       ↓
 *   SystemResult (for React UI)
 */

import {
  updatePriorities,
  getTopZones,
  allocateBestResource,
  updateResourceStatus,
  shortestPath,
  validateState,
} from "./interfaces.js";

import { availableResources } from "./data.js";

// ── System State ──────────────────────────────────────────────
/**
 * SystemState is the single source of truth.
 * Like a global struct in C that holds everything.
 *
 * @typedef {Object} SystemState
 * @property {Zone[]}   zones           - All active crisis zones
 * @property {Object}   resources       - Current resource pool
 * @property {Object[]} log             - Audit trail of all actions
 * @property {string}   phase           - idle | running | complete | error
 * @property {number}   tick            - Simulation step counter
 * @property {Object}   graph           - Road network (from Spandana)
 */
function createInitialState(zones, resourceOverride = null) {
  return {
    zones,
    resources: resourceOverride ? { ...resourceOverride } : { ...availableResources },
    log: [],
    phase: "idle",
    tick: 0,
    graph: null, // Spandana will populate this
  };
}

// ── Pipeline Stages ───────────────────────────────────────────

/**
 * STAGE 1: loadData(scenario) → SystemState
 *
 * Initialize system state from a scenario.
 * Validates input using Spandana's validateState.
 */
function loadData(scenario) {
  const state = createInitialState(scenario.zones, scenario.resourceOverride);
  state.phase = "loading";

  const { valid, errors } = validateState(state);
  if (!valid) {
    console.error("[Controller] State validation failed:", errors);
    return { ...state, phase: "error", errors };
  }

  state.log.push({
    tick: 0,
    stage: "LOAD",
    message: `Loaded ${scenario.zones.length} zones. Scenario: "${scenario.name}"`,
    timestamp: Date.now(),
  });

  state.phase = "loaded";
  return state;
}

/**
 * STAGE 2: runPriorityEngine(state) → SystemState
 *
 * Calls Surabhi's module to score and rank all zones.
 * Output: state.zones now has priorityScore, sorted descending.
 */
function runPriorityEngine(state) {
  state.phase = "prioritizing";

  // Surabhi's functions
  const scoredZones = updatePriorities(state.zones);
  const sortedZones = [...scoredZones].sort(
    (a, b) => (b.priorityScore || 0) - (a.priorityScore || 0)
  );

  const top = getTopZones(sortedZones, 3);

  state.log.push({
    tick: state.tick,
    stage: "PRIORITY",
    message: `Priority engine complete. Top zone: "${top[0]?.name}" (score: ${top[0]?.priorityScore})`,
    topZones: top.map((z) => ({ name: z.name, score: z.priorityScore })),
    timestamp: Date.now(),
  });

  return { ...state, zones: sortedZones, phase: "prioritized" };
}

/**
 * STAGE 3: runAllocationEngine(state) → SystemState
 *
 * Calls Lekhya's module to allocate resources zone-by-zone (greedy).
 * Uses shortest path for each allocation.
 *
 * MENTOR NOTE: This is the classic greedy algorithm.
 * We process zones in priority order (highest first).
 * Each zone gets what it needs from what's left in the pool.
 * Time complexity: O(n) allocation × O(V + E log V) Dijkstra = O(n × V log V)
 */
function runAllocationEngine(state) {
  state.phase = "allocating";

  let resourcePool = { ...state.resources };
  const allocatedZones = [];

  for (let i = 0; i < state.zones.length; i++) {
    const zone = state.zones[i];

    // Lekhya's routing: find shortest path from depot to this zone
    const route = shortestPath(state.graph, "depot_central", String(zone.id));

    // Lekhya's allocation: pick best resources considering type + distance
    const allocated = allocateBestResource(zone, resourcePool, state.graph);

    // Lekhya's state update: deduct from pool
    resourcePool = updateResourceStatus(resourcePool, allocated);

    const totalAllocated =
      allocated.ambulances + allocated.fireUnits +
      allocated.rescueTeams + allocated.hazmatTeams;

    allocatedZones.push({
      ...zone,
      rank: i + 1,
      allocated,
      route,
      receivedResources: totalAllocated > 0,
    });

    state.log.push({
      tick: state.tick,
      stage: "ALLOCATE",
      message: `[#${i + 1}] "${zone.name}" → 🚑${allocated.ambulances} 🚒${allocated.fireUnits} 🪖${allocated.rescueTeams} ☣️${allocated.hazmatTeams} | via ${route.distance}km`,
      zoneId: zone.id,
      allocated,
      routeDistance: route.distance,
      timestamp: Date.now(),
    });
  }

  return {
    ...state,
    zones: allocatedZones,
    resources: resourcePool,
    phase: "allocated",
  };
}

/**
 * STAGE 4: applyStateChanges(state, event) → SystemState
 *
 * Handles DYNAMIC events mid-simulation:
 * - Severity change: recalculate priorities
 * - New incident: insert zone, re-run priority engine
 *
 * MENTOR NOTE: This is what separates a "static" system from a
 * "reactive" system. Real emergency response is never a one-shot
 * batch job — it's a continuous loop reacting to new information.
 */
export function applyStateChange(state, event) {
  let updatedZones = [...state.zones];

  if (event.type === "SEVERITY_CHANGE") {
    // Update the specific zone's severity
    updatedZones = updatedZones.map((z) =>
      z.id === event.zoneId ? { ...z, severity: event.newSeverity } : z
    );

    state.log.push({
      tick: state.tick,
      stage: "EVENT",
      message: `⚡ Severity change at zone ${event.zoneId}: ${event.oldSeverity} → ${event.newSeverity} (${event.change})`,
      timestamp: Date.now(),
    });

    // Re-run priority engine after severity change (Surabhi's adaptive recalc)
    const reprioritized = runPriorityEngine({ ...state, zones: updatedZones });
    return reprioritized;
  }

  if (event.type === "NEW_INCIDENT") {
    updatedZones.push(event.zone);

    state.log.push({
      tick: state.tick,
      stage: "EVENT",
      message: `🆕 New incident: "${event.zone.name}" (severity ${event.zone.severity})`,
      timestamp: Date.now(),
    });

    const reprioritized = runPriorityEngine({ ...state, zones: updatedZones });
    return reprioritized;
  }

  return state;
}

// ── Main Controller ───────────────────────────────────────────

/**
 * runController(scenario) → SystemResult
 *
 * THE MAIN FUNCTION. Executes the full pipeline.
 * Called by the React hook (useSimulation.js) on button click.
 *
 * Pipeline:
 *   loadData → runPriorityEngine → runAllocationEngine → return result
 *
 * @param {Object} scenario - Output of generateScenario()
 * @returns {SystemResult}
 */
export function runController(scenario) {
  console.group(`[Controller] Running: "${scenario.name}"`);
  const start = performance.now();

  // ── Pipeline execution ──────────────────────────────
  let state = loadData(scenario);
  if (state.phase === "error") {
    console.error("[Controller] Aborted at load stage.", state.errors);
    console.groupEnd();
    return { success: false, error: state.errors, state };
  }

  state = runPriorityEngine(state);
  state = runAllocationEngine(state);

  // ── Final summary ───────────────────────────────────
  const elapsed = (performance.now() - start).toFixed(2);
  const totalDeployed =
    (availableResources.ambulances - state.resources.ambulances) +
    (availableResources.fireUnits - state.resources.fireUnits) +
    (availableResources.rescueTeams - state.resources.rescueTeams) +
    (availableResources.hazmatTeams - state.resources.hazmatTeams);

  const zonesWithNoHelp = state.zones.filter((z) => !z.receivedResources).length;

  state.log.push({
    tick: state.tick,
    stage: "COMPLETE",
    message: `✅ Pipeline complete in ${elapsed}ms. ${totalDeployed} units deployed. ${zonesWithNoHelp} zones unserved.`,
    elapsed,
    timestamp: Date.now(),
  });

  state.phase = "complete";

  console.log("[Controller] Done.", state.log);
  console.groupEnd();

  return {
    success: true,
    scenario: scenario.name,
    zones: state.zones,
    remainingResources: state.resources,
    log: state.log,
    stats: {
      totalZones: state.zones.length,
      zonesServed: state.zones.length - zonesWithNoHelp,
      zonesUnserved: zonesWithNoHelp,
      totalDeployed,
      elapsed,
    },
  };
}

/**
 * runSimulationLoop(scenario, onTick, ticks) → void
 *
 * Runs the controller across multiple ticks, injecting random events.
 * Calls onTick(result) after each tick so the UI can update live.
 *
 * MENTOR NOTE: This is an EVENT LOOP — same concept as Node.js's
 * event loop, or an RTOS scheduler in embedded C.
 * Each "tick" = one cycle of: sense → plan → act → update.
 *
 * @param {Object} scenario   - Initial scenario
 * @param {Function} onTick   - Callback called with result each tick
 * @param {number} ticks      - Number of simulation steps
 * @param {number} intervalMs - Delay between ticks in milliseconds
 */
export function runSimulationLoop(scenario, onTick, ticks = 3, intervalMs = 2000) {
  // Lazy import to avoid circular deps
  const { generateSeverityChange, generateNewIncident } = require("./simulator.js");

  let currentScenario = { ...scenario };
  let tick = 0;

  const interval = setInterval(() => {
    if (tick >= ticks) {
      clearInterval(interval);
      return;
    }

    // Every other tick, inject a random event
    if (tick > 0 && tick % 2 === 0) {
      const event = Math.random() > 0.5
        ? { type: "SEVERITY_CHANGE", ...generateSeverityChange(currentScenario.zones) }
        : { type: "NEW_INCIDENT", zone: generateNewIncident() };

      if (event.type === "NEW_INCIDENT") {
        currentScenario = {
          ...currentScenario,
          zones: [...currentScenario.zones, event.zone],
        };
      } else if (event.type === "SEVERITY_CHANGE" && event.zoneId) {
        currentScenario = {
          ...currentScenario,
          zones: currentScenario.zones.map((z) =>
            z.id === event.zoneId ? { ...z, severity: event.newSeverity } : z
          ),
        };
      }
    }

    const result = runController(currentScenario);
    result.tick = tick;
    onTick(result);
    tick++;
  }, intervalMs);

  return () => clearInterval(interval); // cleanup function
}
