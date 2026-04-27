/**
 * simulator.js
 * ============
 * VEEKSHA's file — Scenario Generator
 *
 * Responsibility: Generate realistic test scenarios to stress-test
 * the entire system. Think of this as the "test harness" in C
 * where you feed inputs to your functions and verify outputs.
 *
 * MENTOR NOTE (for placements):
 * This is essentially a "fuzzer" or "scenario engine."
 * In industry: game engines, traffic simulators, network simulators,
 * financial risk models all use this exact pattern.
 * Key concept: Randomized-but-realistic test data generation.
 */

import { createZone } from "./interfaces.js";

// ── Scenario Templates ────────────────────────────────────────
// Like an enum in C: fixed set of named scenario types
export const SCENARIO_TYPES = {
  MASS_CASUALTY:    "MASS_CASUALTY",
  INDUSTRIAL_CHAIN: "INDUSTRIAL_CHAIN",
  MULTI_FIRE:       "MULTI_FIRE",
  CHEMICAL_LEAK:    "CHEMICAL_LEAK",
  TRANSPORT_PILE:   "TRANSPORT_PILE",
  RANDOM:           "RANDOM",
};

// Zone type pool — used for random generation
const ZONE_TYPES = ["fire", "collision", "explosion", "collapse", "hazmat"];

// Name templates per zone type — makes output readable
const ZONE_NAME_TEMPLATES = {
  fire:      ["Mall Fire", "Hospital Fire", "Warehouse Fire", "School Fire", "Market Fire"],
  collision: ["Highway Collision", "Intersection Crash", "Train Derailment", "Bus Accident", "Freeway Pileup"],
  explosion: ["Gas Pipeline Blast", "Factory Explosion", "Building Blast", "Boiler Explosion"],
  collapse:  ["Apartment Collapse", "Bridge Collapse", "Under-construction Collapse", "Parking Structure Collapse"],
  hazmat:    ["Chemical Spill", "Gas Leak", "Toxic Waste Dump", "Pesticide Leak"],
};

/**
 * randomBetween(min, max) → number
 * Utility: random integer in [min, max] inclusive.
 * Equivalent to: min + (rand() % (max - min + 1)) in C.
 */
function randomBetween(min, max) {
  return Math.floor(Math.random() * (max - min + 1)) + min;
}

function randomFloat(min, max) {
  return parseFloat((Math.random() * (max - min) + min).toFixed(1));
}

function randomFrom(arr) {
  return arr[Math.floor(Math.random() * arr.length)];
}

/**
 * generateRandomZone(idOffset) → Zone
 *
 * Creates one randomized crisis zone using Spandana's createZone factory.
 * All values are within realistic ranges.
 */
function generateRandomZone(idOffset = 0) {
  const type = randomFrom(ZONE_TYPES);
  const namePool = ZONE_NAME_TEMPLATES[type];
  return createZone({
    id: Date.now() + idOffset,
    name: randomFrom(namePool),
    type,
    severity:        randomBetween(4, 10),
    peopleAffected:  randomBetween(10, 600),
    distance:        randomFloat(0.5, 10.0),
    resourcesPresent: randomBetween(0, 2),
  });
}

// ── Scenario Generators ───────────────────────────────────────
// Each function returns: { name, description, zones, resourceOverride? }

/**
 * scenarioMassCasualty()
 * High-people, high-severity collision + fire combo.
 * Tests: does the priority engine correctly weight peopleAffected?
 */
function scenarioMassCasualty() {
  return {
    name: "Mass Casualty Event",
    description: "Stadium collapse + nearby fire. High people count, ambulance pressure.",
    zones: [
      createZone({ id: 101, name: "Stadium Collapse", type: "collapse", severity: 10, peopleAffected: 800, distance: 1.2, resourcesPresent: 0 }),
      createZone({ id: 102, name: "Parking Lot Fire", type: "fire",     severity: 7,  peopleAffected: 200, distance: 1.5, resourcesPresent: 1 }),
      createZone({ id: 103, name: "Access Road Crash", type: "collision", severity: 5, peopleAffected: 40,  distance: 0.8, resourcesPresent: 1 }),
    ],
  };
}

/**
 * scenarioIndustrialChain()
 * Chain-reaction: explosion triggers hazmat leak.
 * Tests: hazmat team scarcity + explosion routing.
 */
function scenarioIndustrialChain() {
  return {
    name: "Industrial Chain Reaction",
    description: "Factory explosion triggers chemical leak. Hazmat teams are critically scarce.",
    zones: [
      createZone({ id: 201, name: "Factory Core Explosion", type: "explosion", severity: 10, peopleAffected: 150, distance: 4.0, resourcesPresent: 0 }),
      createZone({ id: 202, name: "Storage Tank Hazmat",   type: "hazmat",    severity: 9,  peopleAffected: 500, distance: 4.5, resourcesPresent: 0 }),
      createZone({ id: 203, name: "Worker Shelter Fire",   type: "fire",      severity: 6,  peopleAffected: 60,  distance: 4.2, resourcesPresent: 0 }),
    ],
    resourceOverride: { ambulances: 6, fireUnits: 4, rescueTeams: 2, hazmatTeams: 1 }, // Scarce!
  };
}

/**
 * scenarioMultiFire()
 * 4 simultaneous fires. Fire units spread thin.
 * Tests: can the greedy allocator handle resource starvation?
 */
function scenarioMultiFire() {
  return {
    name: "Multi-Zone Fire Outbreak",
    description: "4 fires break out simultaneously. Fire units are exhausted.",
    zones: [
      createZone({ id: 301, name: "Downtown Mall Fire",   type: "fire", severity: 9, peopleAffected: 320, distance: 1.0, resourcesPresent: 0 }),
      createZone({ id: 302, name: "Hospital Wing Fire",   type: "fire", severity: 8, peopleAffected: 200, distance: 2.5, resourcesPresent: 1 }),
      createZone({ id: 303, name: "School Building Fire", type: "fire", severity: 7, peopleAffected: 180, distance: 3.0, resourcesPresent: 0 }),
      createZone({ id: 304, name: "Market Complex Fire",  type: "fire", severity: 5, peopleAffected: 80,  distance: 5.0, resourcesPresent: 1 }),
    ],
    resourceOverride: { ambulances: 12, fireUnits: 4, rescueTeams: 5, hazmatTeams: 2 }, // Fire units intentionally low
  };
}

/**
 * scenarioChemicalLeak()
 * Single massive hazmat + overwhelmed medical.
 * Tests: does distance penalization work at scale?
 */
function scenarioChemicalLeak() {
  return {
    name: "Chemical Plant Leak",
    description: "Toxic gas leak affecting 3 zones at varying distances. Distance matters here.",
    zones: [
      createZone({ id: 401, name: "Plant Epicentre",    type: "hazmat",    severity: 10, peopleAffected: 50,  distance: 8.0, resourcesPresent: 0 }),
      createZone({ id: 402, name: "Residential Downwind", type: "hazmat",  severity: 7,  peopleAffected: 400, distance: 3.0, resourcesPresent: 0 }),
      createZone({ id: 403, name: "Highway Evacuation Crash", type: "collision", severity: 5, peopleAffected: 30, distance: 3.5, resourcesPresent: 0 }),
    ],
  };
}

/**
 * scenarioRandom(count)
 * Fully randomized scenario. count zones, random everything.
 * Tests: system robustness under unpredictable input.
 */
function scenarioRandom(count = 5) {
  const zones = Array.from({ length: count }, (_, i) => generateRandomZone(i * 100));
  return {
    name: `Random Scenario (${count} zones)`,
    description: "Fully randomized crisis zones. Tests general system robustness.",
    zones,
  };
}

// ── Public API ────────────────────────────────────────────────

/**
 * generateScenario(type) → Scenario
 *
 * Main entry point for the controller.
 * Given a scenario type, returns the full scenario object.
 *
 * MENTOR NOTE: This is the Factory Pattern.
 * Like a switch-case in C that returns different structs.
 *
 * @param {string} type - One of SCENARIO_TYPES
 * @returns {{ name, description, zones, resourceOverride? }}
 */
export function generateScenario(type = SCENARIO_TYPES.RANDOM) {
  switch (type) {
    case SCENARIO_TYPES.MASS_CASUALTY:    return scenarioMassCasualty();
    case SCENARIO_TYPES.INDUSTRIAL_CHAIN: return scenarioIndustrialChain();
    case SCENARIO_TYPES.MULTI_FIRE:       return scenarioMultiFire();
    case SCENARIO_TYPES.CHEMICAL_LEAK:    return scenarioChemicalLeak();
    case SCENARIO_TYPES.TRANSPORT_PILE:
    case SCENARIO_TYPES.RANDOM:
    default:                               return scenarioRandom(randomBetween(4, 7));
  }
}

/**
 * generateSeverityChange(zones) → { zoneId, oldSeverity, newSeverity }
 *
 * Simulates a real-time severity update for a random zone.
 * Called during the simulation loop to test dynamic reprioritization.
 *
 * Real-world analogy: A field officer radios in that a fire has spread.
 * The system must recalculate priorities immediately.
 */
export function generateSeverityChange(zones) {
  if (!zones || zones.length === 0) return null;
  const target = zones[Math.floor(Math.random() * zones.length)];
  const delta = randomBetween(-2, 3); // Can worsen OR improve
  const newSeverity = Math.max(1, Math.min(10, target.severity + delta));
  return {
    zoneId: target.id,
    oldSeverity: target.severity,
    newSeverity,
    change: newSeverity > target.severity ? "ESCALATED" : newSeverity < target.severity ? "IMPROVED" : "UNCHANGED",
  };
}

/**
 * generateNewIncident() → Zone
 *
 * Simulates a brand-new crisis zone appearing mid-simulation.
 * Tests whether the priority engine handles dynamic insertion.
 */
export function generateNewIncident() {
  return generateRandomZone(Math.floor(Math.random() * 10000));
}
