import React, { useEffect, useMemo, useRef, useState } from 'react';
import { useAuth } from '../context/AuthContext';
import { Ambulance, Briefcase, Flame, LocateFixed, Route, ShieldCheck, Truck, Zap } from 'lucide-react';
import {
  BANGALORE_CENTER,
  RESPONDER_POOLS,
  classifyIncident,
  createAssignment,
  getRemainingSeconds,
  resolveIncidentLocation,
} from '../allotmentLogic';

export default function VolunteerAllotment() {
  const { getAllIncidents, updateIncident } = useAuth();
  const allIncidents = getAllIncidents();
  const pendingIncidents = allIncidents.filter((inc) => inc.status === 'pending');
  const assignedIncidents = allIncidents.filter((inc) => inc.status === 'assigned');
  const completedIncidents = allIncidents.filter((inc) => inc.status === 'completed');
  const [isRunning, setIsRunning] = useState(false);
  const [now, setNow] = useState(Date.now());

  const mapRef = useRef(null);
  const leafletRef = useRef(null);
  const layersRef = useRef({ incidents: null, resources: null, routes: null });

  const responderCounts = useMemo(() => ({
    ambulance: RESPONDER_POOLS.ambulance.length,
    fire: RESPONDER_POOLS.fire.length,
    rescue: RESPONDER_POOLS.rescue.length,
  }), []);

  useEffect(() => {
    const timer = setInterval(() => setNow(Date.now()), 1000);
    return () => clearInterval(timer);
  }, []);

  useEffect(() => {
    const L = window.L;
    if (!L || mapRef.current || !leafletRef.current) return;

    const map = L.map(leafletRef.current, { zoomControl: true }).setView(BANGALORE_CENTER, 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    layersRef.current.incidents = L.layerGroup().addTo(map);
    layersRef.current.resources = L.layerGroup().addTo(map);
    layersRef.current.routes = L.layerGroup().addTo(map);
    mapRef.current = map;
    setTimeout(() => map.invalidateSize(), 150);
  }, []);

  useEffect(() => {
    const L = window.L;
    const incidentLayer = layersRef.current.incidents;
    const resourceLayer = layersRef.current.resources;
    const routeLayer = layersRef.current.routes;
    if (!L || !incidentLayer || !resourceLayer || !routeLayer) return;

    incidentLayer.clearLayers();
    resourceLayer.clearLayers();
    routeLayer.clearLayers();

    allIncidents
      .filter((inc) => inc.status !== 'completed')
      .forEach((inc) => {
        const location = resolveIncidentLocation(inc);
        const category = classifyIncident(inc);
        const color = category.key === 'fire' ? '#ff5722' : category.key === 'rescue' ? '#a78bfa' : '#00d4ff';

        L.circleMarker([location.lat, location.lon], {
          radius: inc.status === 'assigned' ? 9 : 7,
          color,
          fillColor: color,
          fillOpacity: inc.status === 'assigned' ? 0.65 : 0.35,
          weight: 2,
        }).addTo(incidentLayer).bindPopup(`<b>${inc.status.toUpperCase()}</b><br>${inc.incidentType || 'Emergency'}<br>${inc.place || ''}`);

        if (inc.status === 'assigned' && inc.resourceLat && inc.resourceLon) {
          L.circleMarker([inc.resourceLat, inc.resourceLon], {
            radius: 7,
            color,
            fillColor: '#182024',
            fillOpacity: 1,
            weight: 3,
          }).addTo(resourceLayer).bindPopup(`<b>${inc.responderName}</b><br>${inc.responderType}`);

          const route = inc.route || [[inc.resourceLat, inc.resourceLon], [location.lat, location.lon]];
          L.polyline(route, { color, weight: 4, opacity: 0.75, dashArray: '8, 8' }).addTo(routeLayer);
        }
      });
  }, [allIncidents]);

  const runAllotment = () => {
    if (pendingIncidents.length === 0) return;
    setIsRunning(true);

    setTimeout(() => {
      const taken = new Set(assignedIncidents.map((inc) => inc.responderId).filter(Boolean));
      pendingIncidents.forEach((incident) => {
        const assignment = createAssignment(incident, taken);
        taken.add(assignment.responderId);
        updateIncident(incident.id, incident.userId, assignment);
      });
      setIsRunning(false);
    }, 900);
  };

  return (
    <div className="p-6 h-full flex flex-col">
      <div className="flex flex-wrap justify-between items-center gap-4 mb-6">
        <div>
          <h2 className="text-2xl font-bold text-white mb-1">Resource Allotment</h2>
          <p className="text-gray-400">One-click dispatch categorizes incidents and assigns the nearest available unit.</p>
        </div>
        <button
          onClick={runAllotment}
          disabled={isRunning || pendingIncidents.length === 0}
          className={`flex items-center gap-2 px-6 py-3 rounded-lg font-bold transition-all ${
            isRunning || pendingIncidents.length === 0
              ? 'bg-[#2a343a] text-gray-500 cursor-not-allowed'
              : 'bg-blue-500 text-white hover:bg-blue-600 shadow-[0_0_15px_rgba(59,130,246,0.3)]'
          }`}
        >
          {isRunning ? <Truck className="animate-bounce" size={20} /> : <Zap size={20} />}
          {isRunning ? 'Running allotment...' : 'Run Allotment'}
        </button>
      </div>

      <div className="grid grid-cols-2 lg:grid-cols-5 gap-4 mb-6">
        <Metric icon={Briefcase} label="Pending" value={pendingIncidents.length} tone="yellow" />
        <Metric icon={Truck} label="Assigned" value={assignedIncidents.length} tone="blue" />
        <Metric icon={ShieldCheck} label="Completed" value={completedIncidents.length} tone="green" />
        <Metric icon={Ambulance} label="Ambulances" value={responderCounts.ambulance} tone="cyan" />
        <Metric icon={Flame} label="Fire Units" value={responderCounts.fire + responderCounts.rescue} tone="orange" />
      </div>

      <div className="flex-1 min-h-0 grid grid-cols-1 lg:grid-cols-[420px_minmax(0,1fr)] gap-6">
        <div className="flex flex-col bg-[#182024] rounded-2xl border border-[#2a343a]/50 overflow-hidden">
          <div className="p-4 border-b border-[#2a343a]/50 bg-[#1c252a]">
            <h3 className="font-semibold text-white">Dispatch Queue</h3>
            <p className="text-xs text-gray-500 mt-1">Pending requests are auto-classified during allotment.</p>
          </div>
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {allIncidents.filter((inc) => inc.status !== 'completed').length === 0 ? (
              <div className="flex flex-col items-center justify-center h-full text-gray-500">
                <Briefcase size={32} className="mb-2 opacity-50" />
                <p>No active incidents to allocate.</p>
              </div>
            ) : (
              allIncidents
                .filter((inc) => inc.status !== 'completed')
                .map((inc) => <IncidentCard key={`${inc.userId}-${inc.id}`} incident={inc} now={now} />)
            )}
          </div>
        </div>

        <div className="relative overflow-hidden rounded-2xl border border-[#2a343a]/50 shadow-lg bg-[#10171b]">
          <div ref={leafletRef} className="allocation-map h-full w-full min-h-[500px]" />
          <div className="absolute top-4 left-4 z-[400] bg-[#182024]/90 backdrop-blur border border-[#2a343a] rounded-lg p-3 shadow-lg pointer-events-none">
            <div className="flex items-center gap-2 text-xs font-bold text-[#00d68f] uppercase tracking-wider mb-2">
              <LocateFixed size={14} /> Live Tracker
            </div>
            <div className="flex flex-wrap gap-3 text-xs text-gray-300">
              <Legend color="#fbbf24" label="Pending" />
              <Legend color="#00d4ff" label="Ambulance" />
              <Legend color="#ff5722" label="Fire" />
              <Legend color="#a78bfa" label="Rescue" />
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}

function IncidentCard({ incident, now }) {
  const category = classifyIncident(incident);
  const isAssigned = incident.status === 'assigned';
  const remaining = getRemainingSeconds(incident, now);
  const minutes = Math.floor(remaining / 60);
  const seconds = remaining % 60;
  const categoryStyles = {
    ambulance: 'bg-cyan-500/10 text-cyan-300',
    fire: 'bg-orange-500/10 text-orange-300',
    rescue: 'bg-violet-500/10 text-violet-300',
  };

  return (
    <div className="bg-[#1c252a] border border-[#2a343a] rounded-xl p-4">
      <div className="flex justify-between items-start mb-2">
        <h4 className="font-bold text-white">{incident.incidentType || 'Emergency'}</h4>
        <span className={`px-2 py-1 rounded text-xs font-bold uppercase tracking-wider ${isAssigned ? 'bg-blue-500/20 text-blue-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
          {isAssigned ? 'Assigned' : 'Pending'}
        </span>
      </div>
      <p className="text-sm text-gray-400 mb-3">{incident.description}</p>
      <div className="text-xs text-gray-500 mb-1">User: {incident.userName || 'Unknown user'}</div>
      <div className="text-xs text-gray-500 mb-3">Location: {incident.place}</div>

      <div className="flex flex-wrap gap-2">
        <span className={`px-2 py-1 rounded text-xs font-bold ${categoryStyles[category.key]}`}>
          {isAssigned ? incident.responderType : category.responderType}
        </span>
        {isAssigned && (
          <>
            <span className="px-2 py-1 rounded text-xs font-bold bg-[#2a343a] text-gray-300">{incident.responderName}</span>
            <span className="px-2 py-1 rounded text-xs font-bold bg-[#00d68f]/10 text-[#00d68f]">
              ETA {minutes}:{String(seconds).padStart(2, '0')}
            </span>
          </>
        )}
      </div>

      {isAssigned && (
        <div className="mt-3 flex items-center gap-2 text-xs text-gray-400">
          <Route size={14} />
          <span>{incident.distanceKm} km route assigned</span>
        </div>
      )}
    </div>
  );
}

function Metric({ icon: Icon, label, value, tone }) {
  const colors = {
    yellow: 'text-yellow-300',
    blue: 'text-blue-400',
    green: 'text-[#00d68f]',
    cyan: 'text-cyan-300',
    orange: 'text-orange-400',
  };
  return (
    <div className="bg-[#182024] rounded-xl border border-[#2a343a]/50 p-4 flex items-center gap-3">
      <Icon size={20} className={colors[tone]} />
      <div>
        <div className="text-xl font-bold text-white leading-none">{value}</div>
        <div className="text-[10px] uppercase tracking-widest text-gray-500 mt-1">{label}</div>
      </div>
    </div>
  );
}

function Legend({ color, label }) {
  return (
    <div className="flex items-center gap-1">
      <span className="w-2 h-2 rounded-full" style={{ backgroundColor: color }} />
      {label}
    </div>
  );
}
