import React, { useCallback, useEffect, useMemo, useRef, useState } from 'react';
import { AlertCircle, Ambulance, Flame, LocateFixed, MapPin, Radio, Route, Trash2, Zap } from 'lucide-react';

const API_BASE = import.meta.env.VITE_ALLOCATION_API_URL || 'http://localhost:5000';
const BANGALORE_CENTER = [12.9716, 77.5946];

export default function ResourceAllocationDashboard() {
  const mapRef = useRef(null);
  const leafletRef = useRef(null);
  const layersRef = useRef({ zones: null, routes: null, selected: null });
  const [zones, setZones] = useState([]);
  const [resources, setResources] = useState({ ambulances: 0, fire_stations: 0 });
  const [selectedPoint, setSelectedPoint] = useState(null);
  const [zoneName, setZoneName] = useState('');
  const [zoneType, setZoneType] = useState('ambulance');
  const [severity, setSeverity] = useState(3);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  const pendingCount = useMemo(() => zones.filter((zone) => zone.status !== 'assigned').length, [zones]);
  const assignedCount = zones.length - pendingCount;

  const request = useCallback(async (path, options) => {
    const response = await fetch(`${API_BASE}${path}`, {
      headers: { 'Content-Type': 'application/json', ...(options?.headers || {}) },
      ...options,
    });
    if (!response.ok) {
      const body = await response.json().catch(() => ({}));
      throw new Error(body.error || `Request failed: ${response.status}`);
    }
    return response.json();
  }, []);

  const refresh = useCallback(async () => {
    try {
      setError('');
      const [zoneData, resourceData] = await Promise.all([
        request('/api/zones'),
        request('/api/resources'),
      ]);
      setZones(zoneData);
      setResources(resourceData);
    } catch (err) {
      setError(err.message || 'Allocation backend is unavailable.');
    }
  }, [request]);

  useEffect(() => {
    const L = window.L;
    if (!L || mapRef.current || !leafletRef.current) return;

    const map = L.map(leafletRef.current, { zoomControl: true }).setView(BANGALORE_CENTER, 12);
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '&copy; OpenStreetMap contributors',
    }).addTo(map);

    layersRef.current.zones = L.layerGroup().addTo(map);
    layersRef.current.routes = L.layerGroup().addTo(map);

    map.on('click', (event) => {
      const point = { lat: event.latlng.lat, lon: event.latlng.lng };
      setSelectedPoint(point);
      if (layersRef.current.selected) layersRef.current.selected.remove();
      layersRef.current.selected = L.circleMarker([point.lat, point.lon], {
        radius: 8,
        color: '#fbbf24',
        fillColor: '#fbbf24',
        fillOpacity: 0.35,
        weight: 2,
      }).addTo(map);
    });

    mapRef.current = map;
    setTimeout(() => map.invalidateSize(), 150);
  }, []);

  useEffect(() => {
    refresh();
  }, [refresh]);

  useEffect(() => {
    const L = window.L;
    const map = mapRef.current;
    const zoneLayer = layersRef.current.zones;
    const routeLayer = layersRef.current.routes;
    if (!L || !map || !zoneLayer || !routeLayer) return;

    zoneLayer.clearLayers();
    routeLayer.clearLayers();

    zones.forEach((zone) => {
      const color = zone.type === 'fire' ? '#ff5722' : '#00d4ff';
      const marker = L.marker([zone.lat, zone.lon], {
        icon: L.divIcon({
          className: 'allocation-marker-wrap',
          html: `<div class="allocation-marker" style="--marker-color:${color}"></div>`,
          iconSize: [22, 22],
          iconAnchor: [11, 11],
        }),
      }).addTo(zoneLayer);
      marker.bindPopup(`<strong>${zone.name}</strong><br>${zone.status.toUpperCase()}`);

      if (zone.resource_lat && zone.resource_lon) {
        L.circleMarker([zone.resource_lat, zone.resource_lon], {
          radius: 7,
          color,
          fillColor: '#182024',
          fillOpacity: 1,
          weight: 3,
        }).addTo(zoneLayer).bindPopup(zone.resource_name || zone.resource);
      }

      if (zone.route?.length) {
        L.polyline(zone.route, { color, weight: 4, opacity: 0.75 }).addTo(routeLayer);
      }
    });
  }, [zones]);

  const createZone = async () => {
    if (!selectedPoint) return;
    setLoading(true);
    try {
      await request('/api/zones', {
        method: 'POST',
        body: JSON.stringify({
          name: zoneName || undefined,
          lat: selectedPoint.lat,
          lon: selectedPoint.lon,
          type: zoneType,
          severity,
        }),
      });
      setZoneName('');
      setSelectedPoint(null);
      if (layersRef.current.selected) layersRef.current.selected.remove();
      await refresh();
    } catch (err) {
      setError(err.message || 'Could not create zone.');
    } finally {
      setLoading(false);
    }
  };

  const allocateZone = async (zoneId) => {
    setLoading(true);
    try {
      await request(`/api/allocate/${zoneId}`, { method: 'POST' });
      await refresh();
    } catch (err) {
      setError(err.message || 'Could not allocate resource.');
    } finally {
      setLoading(false);
    }
  };

  const allocateAll = async () => {
    setLoading(true);
    try {
      for (const zone of zones.filter((item) => item.status !== 'assigned')) {
        await request(`/api/allocate/${zone.id}`, { method: 'POST' });
      }
      await refresh();
    } catch (err) {
      setError(err.message || 'Could not allocate all pending zones.');
    } finally {
      setLoading(false);
    }
  };

  const deleteZone = async (zoneId) => {
    setLoading(true);
    try {
      await request(`/api/zones/${zoneId}`, { method: 'DELETE' });
      await refresh();
    } catch (err) {
      setError(err.message || 'Could not delete zone.');
    } finally {
      setLoading(false);
    }
  };

  const focusZone = (zone) => {
    mapRef.current?.flyTo([zone.lat, zone.lon], 14, { duration: 0.8 });
  };

  return (
    <div className="flex flex-col gap-5 pb-12">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-xl font-semibold text-white tracking-wide">Resource Allocation</h1>
          <p className="text-xs text-gray-500 mt-1">Bangalore emergency dispatch with nearest-resource assignment</p>
        </div>
        <div className="flex items-center gap-3">
          <Metric icon={Ambulance} label="Hospitals" value={resources.ambulances} tone="cyan" />
          <Metric icon={Flame} label="Fire Stns" value={resources.fire_stations} tone="orange" />
          <Metric icon={Radio} label="Assigned" value={assignedCount} tone="green" />
        </div>
      </div>

      {error && (
        <div className="flex items-center gap-2 rounded-lg border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300">
          <AlertCircle size={16} />
          <span>{error}</span>
        </div>
      )}

      <div className="grid grid-cols-1 xl:grid-cols-[360px_minmax(0,1fr)] gap-5 min-h-[680px]">
        <aside className="flex flex-col gap-4">
          <section className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg overflow-hidden">
            <PanelHeader title="New Emergency Zone" badge={selectedPoint ? 'Pinned' : 'Map click'} />
            <div className="p-4 space-y-4">
              <div className="rounded-lg border border-[#2a343a] bg-[#182024] px-3 py-2 font-mono text-xs text-[#00d4ff]">
                {selectedPoint ? `${selectedPoint.lat.toFixed(5)}, ${selectedPoint.lon.toFixed(5)}` : 'No location selected'}
              </div>

              <Field label="Zone Name">
                <input
                  value={zoneName}
                  onChange={(event) => setZoneName(event.target.value)}
                  placeholder="e.g. MG Road Fire"
                  className="w-full rounded-lg border border-[#2a343a] bg-[#182024] px-3 py-2 text-sm text-gray-100 outline-none transition-colors focus:border-[#00d68f]"
                />
              </Field>

              <Field label="Type">
                <div className="grid grid-cols-2 gap-2">
                  <TypeButton active={zoneType === 'ambulance'} onClick={() => setZoneType('ambulance')} icon={Ambulance} label="Ambulance" />
                  <TypeButton active={zoneType === 'fire'} onClick={() => setZoneType('fire')} icon={Flame} label="Fire" fire />
                </div>
              </Field>

              <Field label={`Severity: ${severity}`}>
                <input
                  type="range"
                  min="1"
                  max="5"
                  value={severity}
                  onChange={(event) => setSeverity(Number(event.target.value))}
                  className="w-full accent-[#00d68f]"
                />
                <div className="flex justify-between text-[10px] font-bold uppercase tracking-widest text-gray-500">
                  <span>Low</span><span>Critical</span>
                </div>
              </Field>

              <button
                disabled={!selectedPoint || loading}
                onClick={createZone}
                className="w-full rounded-lg bg-[#00d68f] px-4 py-3 text-sm font-bold uppercase tracking-wider text-[#182024] transition-opacity hover:opacity-90 disabled:cursor-not-allowed disabled:opacity-40"
              >
                Create Zone
              </button>
            </div>
          </section>

          <button
            disabled={pendingCount === 0 || loading}
            onClick={allocateAll}
            className="flex items-center justify-center gap-2 rounded-lg border border-yellow-400/50 bg-yellow-400/10 px-4 py-3 text-sm font-bold uppercase tracking-wider text-yellow-300 transition-colors hover:bg-yellow-400/20 disabled:cursor-not-allowed disabled:opacity-40"
          >
            <Zap size={16} />
            Allocate All Pending
          </button>

          <section className="bg-[#212b31] rounded-xl border border-[#2a343a] shadow-lg overflow-hidden flex-1">
            <PanelHeader title="Active Zones" badge={zones.length} />
            <div className="p-4 space-y-3 max-h-[410px] overflow-y-auto">
              {zones.length === 0 ? (
                <div className="flex flex-col items-center justify-center py-10 text-center text-gray-500">
                  <MapPin size={30} className="mb-3 opacity-50" />
                  <p className="text-sm">No active zones.</p>
                  <p className="text-xs mt-1">Click the map to begin.</p>
                </div>
              ) : zones.map((zone) => (
                <ZoneCard
                  key={zone.id}
                  zone={zone}
                  onFocus={() => focusZone(zone)}
                  onAllocate={() => allocateZone(zone.id)}
                  onDelete={() => deleteZone(zone.id)}
                  loading={loading}
                />
              ))}
            </div>
          </section>
        </aside>

        <main className="relative overflow-hidden rounded-xl border border-[#2a343a] bg-[#10171b] shadow-lg">
          <div ref={leafletRef} className="allocation-map h-full min-h-[680px] w-full" />
          <div className="pointer-events-none absolute left-4 top-4 rounded-lg border border-[#2a343a] bg-[#182024]/90 px-4 py-3 backdrop-blur">
            <div className="flex items-center gap-2 text-xs font-bold uppercase tracking-widest text-[#00d68f]">
              <LocateFixed size={14} />
              Live Allocation Map
            </div>
            <p className="mt-1 text-xs text-gray-400">{pendingCount} pending | {assignedCount} assigned</p>
          </div>
        </main>
      </div>
    </div>
  );
}

function Metric({ icon: Icon, label, value, tone }) {
  const colors = {
    cyan: 'text-cyan-300',
    orange: 'text-orange-400',
    green: 'text-[#00d68f]',
  };
  return (
    <div className="flex items-center gap-3 rounded-lg border border-[#2a343a] bg-[#212b31] px-4 py-3">
      <Icon size={18} className={colors[tone]} />
      <div>
        <div className="text-lg font-bold text-white leading-none">{value ?? '-'}</div>
        <div className="mt-1 text-[10px] font-bold uppercase tracking-widest text-gray-500">{label}</div>
      </div>
    </div>
  );
}

function PanelHeader({ title, badge }) {
  return (
    <div className="flex items-center justify-between border-b border-[#2a343a] bg-[#182024] px-4 py-3">
      <h2 className="text-xs font-bold uppercase tracking-widest text-[#00d68f]">{title}</h2>
      <span className="rounded-full bg-[#2a343a] px-2 py-1 text-[10px] font-bold text-gray-300">{badge}</span>
    </div>
  );
}

function Field({ label, children }) {
  return (
    <label className="block">
      <span className="mb-2 block text-[11px] font-bold uppercase tracking-widest text-gray-500">{label}</span>
      {children}
    </label>
  );
}

function TypeButton({ active, onClick, icon: Icon, label, fire = false }) {
  const activeClass = fire
    ? 'border-orange-500/70 bg-orange-500/15 text-orange-300'
    : 'border-cyan-400/70 bg-cyan-400/15 text-cyan-200';

  return (
    <button
      type="button"
      onClick={onClick}
      className={`flex items-center justify-center gap-2 rounded-lg border px-3 py-2 text-xs font-bold uppercase tracking-wider transition-colors ${
        active ? activeClass : 'border-[#2a343a] bg-[#182024] text-gray-500 hover:text-gray-300'
      }`}
    >
      <Icon size={15} />
      {label}
    </button>
  );
}

function ZoneCard({ zone, onFocus, onAllocate, onDelete, loading }) {
  const isFire = zone.type === 'fire';
  const assigned = zone.status === 'assigned';
  const severityTone = Number(zone.severity) >= 5 ? 'text-red-300 bg-red-500/10' : Number(zone.severity) >= 3 ? 'text-yellow-300 bg-yellow-500/10' : 'text-emerald-300 bg-emerald-500/10';

  return (
    <div className={`rounded-lg border bg-[#182024] p-3 transition-colors hover:border-[#00d68f]/60 ${isFire ? 'border-l-orange-500' : 'border-l-cyan-400'} border-[#2a343a] border-l-4`}>
      <button onClick={onFocus} className="w-full text-left">
        <div className="flex items-start justify-between gap-3">
          <div>
            <h3 className="text-sm font-semibold text-gray-100">{zone.name}</h3>
            <p className="mt-1 font-mono text-[10px] uppercase tracking-wider text-gray-500">{zone.id}</p>
          </div>
          <span className={`rounded px-2 py-1 text-[10px] font-bold uppercase tracking-wider ${assigned ? 'bg-[#00d68f]/10 text-[#00d68f]' : 'bg-yellow-500/10 text-yellow-300'}`}>
            {zone.status}
          </span>
        </div>
        <div className="mt-3 flex flex-wrap gap-2">
          <span className={`rounded px-2 py-1 text-[10px] font-bold uppercase tracking-wider ${severityTone}`}>Sev {zone.severity}</span>
          <span className={`rounded px-2 py-1 text-[10px] font-bold uppercase tracking-wider ${isFire ? 'bg-orange-500/10 text-orange-300' : 'bg-cyan-500/10 text-cyan-200'}`}>{zone.type}</span>
        </div>
        <div className="mt-3 flex items-center gap-2 text-xs text-gray-400">
          <Route size={13} />
          <span>{zone.resource_name || 'Awaiting allocation'}</span>
        </div>
        {zone.distance_km && (
          <p className="mt-1 font-mono text-[11px] text-gray-500">{zone.distance_km} km | ETA {zone.eta_minutes} min</p>
        )}
      </button>
      <div className="mt-3 flex gap-2">
        <button
          disabled={assigned || loading}
          onClick={onAllocate}
          className="flex flex-1 items-center justify-center gap-2 rounded-md border border-[#00d68f]/40 bg-[#00d68f]/10 px-3 py-2 text-xs font-bold uppercase tracking-wider text-[#00d68f] disabled:cursor-not-allowed disabled:opacity-40"
        >
          <Zap size={13} />
          Allocate
        </button>
        <button
          disabled={loading}
          onClick={onDelete}
          className="flex h-9 w-9 items-center justify-center rounded-md border border-red-500/30 bg-red-500/10 text-red-300 disabled:cursor-not-allowed disabled:opacity-40"
          aria-label={`Delete ${zone.name}`}
        >
          <Trash2 size={14} />
        </button>
      </div>
    </div>
  );
}
