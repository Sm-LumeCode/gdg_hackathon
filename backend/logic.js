let weights = {
  severity: 0.7,
  population: 0.2,
  distance: 0.1
};

function calculateDistance(a, b) {
  return Math.sqrt(
    (a.lat - b.lat) ** 2 +
    (a.lng - b.lng) ** 2
  );
}

function calculatePriority(zone, resource) {
  const distance = calculateDistance(zone, resource);

  return (
    weights.severity * zone.severity +
    weights.population * zone.population -
    weights.distance * distance
  );
}

export function allocateResources(zones, resources) {
  resources.forEach(resource => {
    // if manually assigned, skip auto override
    if (resource.manual) return;

    let bestZone = null;
    let bestScore = -Infinity;

    zones.forEach(zone => {
      const score = calculatePriority(zone, resource);

      if (score > bestScore) {
        bestScore = score;
        bestZone = zone;
      }
    });

    if (bestZone) {
      resource.assignedZone = bestZone.id;
    }
  });
}