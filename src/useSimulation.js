/**
 * useSimulation.js
 * ================
 * VEEKSHA's React hook — Bridge between controller and UI
 *
 * This is the "adapter" layer. The controller knows nothing about React.
 * The UI knows nothing about the allocation algorithm.
 * This hook is the translator between them.
 *
 * MENTOR NOTE (for placements):
 * This is the Adapter Pattern + Observer Pattern combined.
 * - Adapter: converts controller output → React state
 * - Observer: React re-renders whenever state changes
 * In C terms: think of this as the ISR (Interrupt Service Routine)
 * that takes hardware events and updates a shared data structure
 * that the main loop reads.
 *
 * React hooks are just functions that:
 * 1. Hold state (useState) — like a persistent local variable
 * 2. Run side effects (useEffect) — like callbacks/interrupts
 * 3. Return values the component can render
 */

import { useState, useCallback } from "react";
import { runController } from "./controller.js";
import { generateScenario, generateSeverityChange, generateNewIncident, SCENARIO_TYPES } from "./simulator.js";
import { availableResources } from "./data.js";

/**
 * useSimulation() → SimulationAPI
 *
 * Custom hook that encapsulates ALL simulation state and logic.
 * Components just call this hook and get clean, typed data back.
 *
 * Returns:
 *   state         → current system state (zones, resources, log, stats)
 *   isRunning     → boolean: pipeline currently executing
 *   runScenario   → fn(scenarioType): load + run a scenario
 *   injectEvent   → fn(eventType): inject a live event mid-simulation
 *   reset         → fn(): clear everything back to initial state
 *   scenarioTypes → the SCENARIO_TYPES enum for UI dropdowns
 */
export function useSimulation() {
  // ── State ─────────────────────────────────────────────────
  const [result, setResult] = useState(null);
  const [isRunning, setIsRunning] = useState(false);
  const [currentScenario, setCurrentScenario] = useState(null);
  const [eventLog, setEventLog] = useState([]);

  // ── Actions ───────────────────────────────────────────────

  /**
   * runScenario(scenarioType)
   *
   * Full pipeline: generate scenario → run controller → update UI state.
   * Uses useCallback to memoize — avoids re-creating this function on
   * every render (performance optimization).
   */
  const runScenario = useCallback((scenarioType = SCENARIO_TYPES.RANDOM) => {
    setIsRunning(true);

    // Small timeout gives React time to re-render the "running" state
    // before the synchronous controller blocks the thread.
    // In a real app, the controller would be async / Web Worker.
    setTimeout(() => {
      try {
        const scenario = generateScenario(scenarioType);
        setCurrentScenario(scenario);

        const controllerResult = runController(scenario);
        setResult(controllerResult);

        setEventLog((prev) => [
          ...prev,
          {
            type: "SCENARIO_RUN",
            message: `▶ Ran scenario: "${scenario.name}"`,
            timestamp: Date.now(),
          },
        ]);
      } catch (err) {
        console.error("[useSimulation] runScenario error:", err);
        setResult({ success: false, error: [err.message] });
      } finally {
        setIsRunning(false);
      }
    }, 50);
  }, []);

  /**
   * injectEvent(eventType)
   *
   * Inject a live event into the current scenario and re-run the controller.
   * This is the "dynamic" simulation feature — reality changes, system adapts.
   *
   * @param {"SEVERITY_CHANGE"|"NEW_INCIDENT"} eventType
   */
  const injectEvent = useCallback((eventType) => {
    if (!currentScenario) return;
    setIsRunning(true);

    setTimeout(() => {
      try {
        let updatedScenario = { ...currentScenario };

        if (eventType === "SEVERITY_CHANGE") {
          const change = generateSeverityChange(currentScenario.zones);
          if (change && change.zoneId) {
            updatedScenario = {
              ...currentScenario,
              zones: currentScenario.zones.map((z) =>
                z.id === change.zoneId ? { ...z, severity: change.newSeverity } : z
              ),
            };
            setEventLog((prev) => [
              ...prev,
              {
                type: "SEVERITY_CHANGE",
                message: `⚡ Severity change: zone updated (${change.oldSeverity}→${change.newSeverity} — ${change.change})`,
                timestamp: Date.now(),
              },
            ]);
          }
        } else if (eventType === "NEW_INCIDENT") {
          const newZone = generateNewIncident();
          updatedScenario = {
            ...currentScenario,
            zones: [...currentScenario.zones, newZone],
          };
          setEventLog((prev) => [
            ...prev,
            {
              type: "NEW_INCIDENT",
              message: `🆕 New incident added: "${newZone.name}" (sev ${newZone.severity})`,
              timestamp: Date.now(),
            },
          ]);
        }

        setCurrentScenario(updatedScenario);
        const controllerResult = runController(updatedScenario);
        setResult(controllerResult);
      } catch (err) {
        console.error("[useSimulation] injectEvent error:", err);
      } finally {
        setIsRunning(false);
      }
    }, 50);
  }, [currentScenario]);

  /**
   * reset()
   * Clear all state back to initial. Like a system reboot.
   */
  const reset = useCallback(() => {
    setResult(null);
    setCurrentScenario(null);
    setIsRunning(false);
    setEventLog([]);
  }, []);

  // ── Derived values (computed from state, not stored) ──────
  // These are like computed properties — recalculated on every render.
  // No useState needed — derived values should never be stored in state.
  const zones            = result?.zones            || [];
  const remainingRes     = result?.remainingResources || availableResources;
  const stats            = result?.stats            || null;
  const controllerLog    = result?.log              || [];
  const scenarioName     = result?.scenario         || currentScenario?.name || null;
  const isComplete       = result?.success === true;
  const hasError         = result?.success === false;

  return {
    // State
    zones,
    remainingResources: remainingRes,
    stats,
    controllerLog,
    eventLog,
    scenarioName,
    isRunning,
    isComplete,
    hasError,
    errorMessages: result?.error || [],

    // Actions
    runScenario,
    injectEvent,
    reset,

    // Constants (for UI dropdowns etc.)
    scenarioTypes: SCENARIO_TYPES,
    totalResources: availableResources,
  };
}
