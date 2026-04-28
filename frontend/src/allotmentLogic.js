export const BANGALORE_CENTER = [12.9716, 77.5946];

export const RESPONDER_POOLS = {
  ambulance: [
    { id: 'AMB_001', name: 'Victoria Hospital Ambulance', lat: 12.9635, lon: 77.5739 },
    { id: 'AMB_002', name: 'Manipal Hospital Ambulance', lat: 12.9582, lon: 77.6484 },
    { id: 'AMB_003', name: "St. John's Medical Response", lat: 12.9294, lon: 77.6187 },
    { id: 'AMB_004', name: 'Aster CMI Ambulance', lat: 13.0545, lon: 77.5928 },
    { id: 'AMB_005', name: 'Fortis Bannerghatta Ambulance', lat: 12.8958, lon: 77.5996 },
  ],
  fire: [
    { id: 'FIRE_001', name: 'High Grounds Fire Engine', lat: 12.9866, lon: 77.5938 },
    { id: 'FIRE_002', name: 'Indiranagar Fire Engine', lat: 12.9784, lon: 77.6408 },
    { id: 'FIRE_003', name: 'Jayanagar Fire Engine', lat: 12.9257, lon: 77.5930 },
    { id: 'FIRE_004', name: 'Whitefield Fire Engine', lat: 12.9698, lon: 77.7500 },
    { id: 'FIRE_005', name: 'Yeshwanthpur Fire Engine', lat: 13.0285, lon: 77.5409 },
  ],
  rescue: [
    { id: 'RES_001', name: 'Central Rescue Team', lat: 12.9767, lon: 77.5993 },
    { id: 'RES_002', name: 'East Zone Rescue Team', lat: 12.9719, lon: 77.6412 },
    { id: 'RES_003', name: 'South Zone Rescue Team', lat: 12.9166, lon: 77.6101 },
    { id: 'RES_004', name: 'North Zone Rescue Team', lat: 13.0358, lon: 77.5970 },
  ],
};

const PLACE_COORDS = {
  pattanager: [12.9226, 77.4987],
  pattanagere: [12.9226, 77.4987],
  'mg road': [12.9756, 77.6068],
  indiranagar: [12.9784, 77.6408],
  koramangala: [12.9352, 77.6245],
  whitefield: [12.9698, 77.7500],
  jayanagar: [12.9250, 77.5938],
  majestic: [12.9767, 77.5713],
  hebbal: [13.0358, 77.5970],
  yeshwanthpur: [13.0285, 77.5409],
  electronic: [12.8452, 77.6602],
  bannerghatta: [12.8877, 77.5969],
};

export function classifyIncident(incident) {
  const text = `${incident.incidentType || ''} ${incident.description || ''}`.toLowerCase();
  if (/(fire|burn|smoke|flame|blast|explosion|gas leak)/.test(text)) {
    return { key: 'fire', responderType: 'Fire Engine' };
  }
  if (/(collapse|trapped|rescue|flood|drowning|stuck|earthquake|debris|building)/.test(text)) {
    return { key: 'rescue', responderType: 'Rescue Team' };
  }
  return { key: 'ambulance', responderType: 'Ambulance' };
}

export function resolveIncidentLocation(incident) {
  if (Number.isFinite(incident.lat) && Number.isFinite(incident.lon)) {
    return { lat: incident.lat, lon: incident.lon };
  }

  const place = String(incident.place || '').toLowerCase();
  const match = Object.entries(PLACE_COORDS).find(([name]) => place.includes(name));
  if (match) {
    const [lat, lon] = match[1];
    return { lat, lon };
  }

  const seed = [...place].reduce((sum, char) => sum + char.charCodeAt(0), 0);
  const latOffset = ((seed % 97) / 97 - 0.5) * 0.12;
  const lonOffset = (((seed * 7) % 97) / 97 - 0.5) * 0.12;
  return { lat: BANGALORE_CENTER[0] + latOffset, lon: BANGALORE_CENTER[1] + lonOffset };
}

export function haversineKm(lat1, lon1, lat2, lon2) {
  const radiusKm = 6371;
  const dlat = toRad(lat2 - lat1);
  const dlon = toRad(lon2 - lon1);
  const a = Math.sin(dlat / 2) ** 2
    + Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dlon / 2) ** 2;
  return radiusKm * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
}

export function createAssignment(incident, takenResourceIds = new Set()) {
  const category = classifyIncident(incident);
  const location = resolveIncidentLocation(incident);
  const pool = RESPONDER_POOLS[category.key];
  const ranked = pool
    .filter((resource) => !takenResourceIds.has(resource.id))
    .map((resource) => ({
      ...resource,
      distanceKm: haversineKm(location.lat, location.lon, resource.lat, resource.lon),
    }))
    .sort((a, b) => a.distanceKm - b.distanceKm);

  const resource = ranked[0] || pool[0];
  const distanceKm = Number(resource.distanceKm?.toFixed(2) || haversineKm(location.lat, location.lon, resource.lat, resource.lon).toFixed(2));
  const etaMinutes = Math.max(1, Math.round((distanceKm / 40) * 60));

  return {
    status: 'assigned',
    responderCategory: category.key,
    responderType: category.responderType,
    responderId: resource.id,
    responderName: resource.name,
    resourceLat: resource.lat,
    resourceLon: resource.lon,
    lat: location.lat,
    lon: location.lon,
    distanceKm,
    etaMinutes,
    etaSeconds: etaMinutes * 60,
    assignedAt: Date.now(),
    route: [[resource.lat, resource.lon], [location.lat, location.lon]],
  };
}

export function getRemainingSeconds(incident, now = Date.now()) {
  if (incident.status !== 'assigned') return 0;
  const etaSeconds = Number(incident.etaSeconds || 0);
  if (!incident.assignedAt || !etaSeconds) return etaSeconds;
  const elapsed = Math.floor((now - Number(incident.assignedAt)) / 1000);
  return Math.max(0, etaSeconds - elapsed);
}

function toRad(value) {
  return value * Math.PI / 180;
}
