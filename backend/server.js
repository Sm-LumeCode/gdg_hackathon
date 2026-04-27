import express from "express";
import http from "http";
import { Server } from "socket.io";
import cors from "cors";

import { zones, resources } from "./data.js";
import { allocateResources } from "./logic.js";

const app = express();
app.use(cors());

const server = http.createServer(app);
const io = new Server(server, {
  cors: { origin: "*" }
});

io.on("connection", (socket) => {
  console.log("⚡ Client connected");

  socket.on("addZone", (zone) => {
    zones.push(zone);
  });

  socket.on("updateSeverity", ({ id, value }) => {
    const z = zones.find(z => z.id === id);
    if (z) z.severity = value;
  });

  socket.on("addResource", (resource) => {
    resources.push({
      ...resource,
      assignedZone: null,
      manual: false
    });
  });

  socket.on("manualAssign", ({ zoneId, resourceId }) => {
    const r = resources.find(r => r.id === resourceId);
    if (r) {
      r.assignedZone = zoneId;
      r.manual = true;
    }
  });
});

// 🔄 LOOP
setInterval(() => {
  allocateResources(zones, resources);

  resources.forEach(r => {
    const target = zones.find(z => z.id === r.assignedZone);

    if (target) {
      const dx = target.lat - r.lat;
      const dy = target.lng - r.lng;

      r.lat += dx * 0.2;
      r.lng += dy * 0.2;

      // reached
      if (Math.abs(dx) < 0.001 && Math.abs(dy) < 0.001) {
        console.log(`✅ Resource ${r.id} reached ${target.name}`);

        target.severity = Math.max(1, target.severity - 5);

        r.assignedZone = null;
        r.manual = false;
      }
    }
  });

  io.emit("update", { zones, resources });

}, 3000);

server.listen(5001, () => console.log("Server running on 5001"));