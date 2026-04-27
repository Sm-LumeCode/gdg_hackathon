import { useEffect, useState } from "react";
import { socket } from "./socket";
import Map from "./Map";

function App() {
  const [zones, setZones] = useState([]);
  const [resources, setResources] = useState([]);

  useEffect(() => {
    socket.on("update", (data) => {
      setZones(data.zones);
      setResources(data.resources);
    });
  }, []);

  async function searchPlace(place) {
    const res = await fetch(
      `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(place)}&limit=1`
    );
    const data = await res.json();

    if (data.length === 0) return;

    const loc = data[0];

    socket.emit("addZone", {
      id: Date.now(),
      lat: parseFloat(loc.lat),
      lng: parseFloat(loc.lon),
      severity: 5,
      population: 100,
      name: loc.display_name
    });
  }

  function updateSeverity(id, value) {
    socket.emit("updateSeverity", { id, value });
  }

  function addResource(type) {
    socket.emit("addResource", {
      id: Date.now(),
      lat: 12.96,
      lng: 77.58,
      type
    });
  }

  function manualAssign(zoneId, resourceId) {
    socket.emit("manualAssign", { zoneId, resourceId });
  }

  return (
    <div style={{ display: "flex", height: "100vh" }}>

      {/* MAP */}
      <div style={{ flex: 2 }}>
        <Map zones={zones} resources={resources} />
      </div>

      {/* CONTROL PANEL */}
      <div style={{
        flex: 1,
        padding: "15px",
        background: "#f4f4f4",
        overflowY: "scroll"
      }}>

        <h2>🚨 Control Panel</h2>

        <input
          placeholder="Search place..."
          onKeyDown={(e) => {
            if (e.key === "Enter") {
              searchPlace(e.target.value);
              e.target.value = "";
            }
          }}
        />

        <br /><br />

        <button onClick={() => addResource("ambulance")}>🚑</button>
        <button onClick={() => addResource("fire")}>🚒</button>
        <button onClick={() => addResource("rescue")}>🛟</button>

        <hr />

        {zones.map(z => (
          <div key={z.id}>
            <strong>{z.name}</strong>

            <br />

            Severity: {z.severity}

            <input
              type="range"
              min="1"
              max="10"
              value={z.severity}
              onChange={(e) =>
                updateSeverity(z.id, Number(e.target.value))
              }
            />

            <br />

            <select
              onChange={(e) =>
                manualAssign(z.id, Number(e.target.value))
              }
            >
              <option>Select Resource</option>
              {resources.map(r => (
                <option key={r.id} value={r.id}>
                  {r.type} {r.id}
                </option>
              ))}
            </select>

            <hr />
          </div>
        ))}

      </div>
    </div>
  );
}

export default App;