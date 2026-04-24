// ============================================================
// DATA MODELING — Spandana's Module
// Core data structures: Zone, Resource, Graph
// State has been moved to Context for React compatibility
// ============================================================

// ─── ZONE CLASS ─────────────────────────────────────────────
export class Zone {
  constructor({ id, name, severity, peopleAffected, distance, resourcesPresent, type, nodeId }) {
    this.id = id;
    this.name = name;
    this.severity = this._validateRange(severity, 1, 10, 'severity');
    this.peopleAffected = this._validatePositive(peopleAffected, 'peopleAffected');
    this.distance = this._validatePositive(distance, 'distance');
    this.resourcesPresent = this._validatePositive(resourcesPresent, 'resourcesPresent');
    this.type = this._validateType(type);
    this.nodeId = nodeId ?? id; // graph node this zone maps to
    this.status = 'active'; // active | resolved | escalated
    this.lastUpdated = Date.now();
  }

  _validateRange(value, min, max, field) {
    const n = Number(value);
    if (isNaN(n) || n < min || n > max) {
      console.warn(`Zone: ${field} must be between ${min}-${max}. Got ${value}. Clamping.`);
      return Math.min(max, Math.max(min, n || min));
    }
    return n;
  }

  _validatePositive(value, field) {
    const n = Number(value);
    if (isNaN(n) || n < 0) {
      console.warn(`Zone: ${field} must be >= 0. Got ${value}. Defaulting to 0.`);
      return 0;
    }
    return n;
  }

  _validateType(type) {
    const valid = ['fire', 'accident', 'explosion', 'collapse', 'hazmat', 'flood', 'medical', 'unknown'];
    if (!valid.includes(type)) {
      console.warn(`Zone: unknown type "${type}". Defaulting to "unknown".`);
      return 'unknown';
    }
    return type;
  }

  update(fields) {
    const allowed = ['severity', 'peopleAffected', 'resourcesPresent', 'status'];
    allowed.forEach(key => {
      if (fields[key] !== undefined) {
        if (key === 'severity') this.severity = this._validateRange(fields[key], 1, 10, key);
        else if (key === 'status') this.status = fields[key];
        else this[key] = this._validatePositive(fields[key], key);
      }
    });
    this.lastUpdated = Date.now();
    return this;
  }

  toPlain() {
    return { ...this };
  }
}

// ─── RESOURCE CLASS ─────────────────────────────────────────
export class Resource {
  constructor({ id, type, locationNodeId }) {
    this.id = id;
    this.type = this._validateResourceType(type);
    this.status = 'available'; // available | deployed | en-route | out-of-service
    this.assignedZoneId = null;
    this.locationNodeId = locationNodeId ?? 0; // HQ by default (node 0)
    this.lastUpdated = Date.now();
  }

  _validateResourceType(type) {
    const valid = ['ambulance', 'fireUnit', 'rescueTeam', 'hazmatTeam'];
    if (!valid.includes(type)) {
      console.warn(`Resource: unknown type "${type}". Defaulting to "ambulance".`);
      return 'ambulance';
    }
    return type;
  }

  deploy(zoneId) {
    this.status = 'en-route';
    this.assignedZoneId = zoneId;
    this.lastUpdated = Date.now();
  }

  markDeployed() {
    this.status = 'deployed';
    this.lastUpdated = Date.now();
  }

  recall() {
    this.status = 'available';
    this.assignedZoneId = null;
    this.locationNodeId = 0;
    this.lastUpdated = Date.now();
  }
}

// ─── GRAPH CLASS (Adjacency List) ───────────────────────────
// Represents road/path network between HQ and crisis zones.
export class Graph {
  constructor() {
    this.nodes = new Map();
    this.edges = new Map();
  }

  addNode(id, label, x = 0, y = 0) {
    if (this.nodes.has(id)) return;
    this.nodes.set(id, { label, x, y });
    this.edges.set(id, []);
  }

  addEdge(fromId, toId, weight) {
    if (!this.nodes.has(fromId) || !this.nodes.has(toId)) return;
    if (weight <= 0) return;
    this.edges.get(fromId).push({ to: toId, weight });
    this.edges.get(toId).push({ to: fromId, weight });
  }

  getNeighbors(nodeId) {
    return this.edges.get(nodeId) ?? [];
  }

  hasNode(nodeId) {
    return this.nodes.has(nodeId);
  }

  getNodeLabel(nodeId) {
    return this.nodes.get(nodeId)?.label ?? `Node ${nodeId}`;
  }

  getAllNodes() {
    return [...this.nodes.keys()];
  }
}

// ─── INITIAL DATA SETUP ─────────────────────────────────────
export const buildInitialGraph = () => {
  const g = new Graph();
  g.addNode(0, 'HQ',                  0,   0);
  g.addNode(1, 'Downtown Hospital',   2,   1);
  g.addNode(2, 'Highway Collision',   5,   4);
  g.addNode(3, 'Industrial Explosion',7,   6);
  g.addNode(4, 'Residential Collapse',3,   2);
  g.addNode(5, 'Public Transport',    1,   1);
  g.addNode(6, 'Hazmat Spill',        6,   5);
  g.addNode(7, 'Warehouse Fire',      4,   3);
  g.addNode(8, 'Waypoint Alpha',      3,   2);
  g.addNode(9, 'Waypoint Beta',       6,   4);

  g.addEdge(0, 1, 2.3);
  g.addEdge(0, 5, 1.2);
  g.addEdge(0, 8, 2.0);
  g.addEdge(1, 4, 1.5);
  g.addEdge(1, 8, 1.8);
  g.addEdge(5, 4, 2.5);
  g.addEdge(8, 4, 1.0);
  g.addEdge(8, 7, 2.2);
  g.addEdge(8, 2, 4.0);
  g.addEdge(7, 2, 3.1);
  g.addEdge(2, 9, 2.5);
  g.addEdge(9, 6, 1.8);
  g.addEdge(9, 3, 2.0);
  g.addEdge(6, 3, 2.1);
  return g;
};

// ─── EXPORTED PLAIN DATA ────────────────────────────────────
export const mockCrisisZones = [
  new Zone({ id: 1, name: "Downtown Hospital Fire",        severity: 9,  peopleAffected: 450, distance: 2.3, resourcesPresent: 1, type: "fire",      nodeId: 1 }),
  new Zone({ id: 2, name: "Highway Multi-vehicle Collision",severity: 8,  peopleAffected: 35,  distance: 5.8, resourcesPresent: 2, type: "accident",  nodeId: 2 }),
  new Zone({ id: 3, name: "Industrial Building Explosion",  severity: 10, peopleAffected: 200, distance: 8.2, resourcesPresent: 0, type: "explosion", nodeId: 3 }),
  new Zone({ id: 4, name: "Residential Building Collapse",  severity: 9,  peopleAffected: 150, distance: 3.5, resourcesPresent: 1, type: "collapse",  nodeId: 4 }),
  new Zone({ id: 5, name: "Public Transport Accident",      severity: 7,  peopleAffected: 75,  distance: 1.2, resourcesPresent: 3, type: "accident",  nodeId: 5 }),
  new Zone({ id: 6, name: "Hazmat Chemical Spill",          severity: 8,  peopleAffected: 300, distance: 6.5, resourcesPresent: 0, type: "hazmat",    nodeId: 6 }),
  new Zone({ id: 7, name: "Warehouse Fire",                 severity: 6,  peopleAffected: 20,  distance: 4.1, resourcesPresent: 2, type: "fire",      nodeId: 7 }),
];

export const availableResources = {
  ambulances: 12,
  fireUnits: 8,
  rescueTeams: 5,
  hazmatTeams: 2,
};