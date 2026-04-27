import { MapContainer, TileLayer, Marker, Popup } from "react-leaflet";
import "leaflet/dist/leaflet.css";

export default function Map({ zones, resources }) {
  return (
    <MapContainer
      center={[12.97, 77.59]}
      zoom={7}
      style={{ height: "100%", width: "100%" }}
    >
      <TileLayer url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png" />

      {zones.map(z => (
        <Marker key={z.id} position={[z.lat, z.lng]}>
          <Popup>
            📍 {z.name} <br />
            Severity: {z.severity}
          </Popup>
        </Marker>
      ))}

      {resources.map(r => (
        <Marker key={r.id} position={[r.lat, r.lng]}>
          <Popup>
            🚑 {r.type} <br />
            To Zone {r.assignedZone}
          </Popup>
        </Marker>
      ))}
    </MapContainer>
  );
}