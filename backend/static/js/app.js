const API = "";
const map = L.map("map").setView([12.9716, 77.5946], 12);
const layers = { zones: L.layerGroup().addTo(map), routes: L.layerGroup().addTo(map), selected: null };
let selected = null;
let zoneType = "ambulance";
let zones = [];

L.tileLayer("https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png", {
  attribution: "&copy; OpenStreetMap contributors",
}).addTo(map);

const $ = (id) => document.getElementById(id);

function tickClock() {
  $("clock").textContent = new Date().toLocaleTimeString("en-IN", { hour12: false });
}

function sevClass(sev) {
  if (sev >= 5) return "tag-sev5";
  if (sev >= 3) return "tag-sev3";
  return "tag-sev1";
}

function markerHtml(zone) {
  const color = zone.type === "fire" ? "#ff5722" : "#00d4ff";
  return `<div style="width:18px;height:18px;border-radius:50%;background:${color};border:3px solid #e8f4ff;box-shadow:0 0 18px ${color};"></div>`;
}

function renderZones() {
  layers.zones.clearLayers();
  layers.routes.clearLayers();
  $("zone-count").textContent = zones.length;
  $("zones-list").innerHTML = zones.length ? "" : '<div class="empty">No active zones. Click the map to begin.</div>';

  zones.forEach((zone) => {
    const marker = L.marker([zone.lat, zone.lon], {
      icon: L.divIcon({ html: markerHtml(zone), className: "", iconSize: [18, 18] }),
    }).addTo(layers.zones);
    marker.bindPopup(`<strong>${zone.name}</strong><br>${zone.status.toUpperCase()}`);

    if (zone.resource_lat && zone.resource_lon) {
      L.marker([zone.resource_lat, zone.resource_lon]).addTo(layers.zones).bindPopup(zone.resource_name);
    }
    if (zone.route && zone.route.length) {
      L.polyline(zone.route, { color: zone.type === "fire" ? "#ff5722" : "#00d4ff", weight: 4, opacity: 0.75 }).addTo(layers.routes);
    }

    const card = document.createElement("div");
    card.className = `zone-card type-${zone.type}`;
    card.innerHTML = `
      <div class="zc-top"><span class="zc-name">${zone.name}</span><span class="zc-id">${zone.id}</span></div>
      <div class="zc-meta">
        <span class="tag tag-${zone.status}">${zone.status}</span>
        <span class="tag ${sevClass(zone.severity)}">SEV ${zone.severity}</span>
        <span class="tag">${zone.type}</span>
      </div>
      <div class="zc-info">${zone.resource_name || "Awaiting allocation"}${zone.distance_km ? ` | ${zone.distance_km} km | ETA ${zone.eta_minutes} min` : ""}</div>
    `;
    card.onclick = () => map.flyTo([zone.lat, zone.lon], 14);
    $("zones-list").appendChild(card);
  });
}

async function refresh() {
  const [zoneRes, resourceRes] = await Promise.all([fetch(`${API}/api/zones`), fetch(`${API}/api/resources`)]);
  zones = await zoneRes.json();
  const resources = await resourceRes.json();
  $("cnt-amb").textContent = resources.ambulances;
  $("cnt-fire").textContent = resources.fire_stations;
  renderZones();
}

map.on("click", (event) => {
  selected = event.latlng;
  $("coords-display").textContent = `${selected.lat.toFixed(5)}, ${selected.lng.toFixed(5)}`;
  $("btn-create").disabled = false;
  if (layers.selected) layers.selected.remove();
  layers.selected = L.circleMarker(selected, { radius: 8, color: "#ffc107", fillOpacity: 0.35 }).addTo(map);
});

document.querySelectorAll(".type-btn").forEach((button) => {
  button.onclick = () => {
    zoneType = button.dataset.type;
    document.querySelectorAll(".type-btn").forEach((btn) => btn.classList.remove("active"));
    button.classList.add("active");
  };
});

$("severity").oninput = (event) => {
  $("sev-val").textContent = event.target.value;
};

$("btn-create").onclick = async () => {
  if (!selected) return;
  await fetch(`${API}/api/zones`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      name: $("zone-name").value,
      lat: selected.lat,
      lon: selected.lng,
      type: zoneType,
      severity: $("severity").value,
    }),
  });
  $("zone-name").value = "";
  $("btn-create").disabled = true;
  if (layers.selected) layers.selected.remove();
  selected = null;
  await refresh();
};

$("btn-allocate-all").onclick = async () => {
  for (const zone of zones.filter((z) => z.status !== "assigned")) {
    await fetch(`${API}/api/allocate/${zone.id}`, { method: "POST" });
  }
  await refresh();
};

setInterval(tickClock, 1000);
tickClock();
refresh();
