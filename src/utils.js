// Calculate priority score for each zone
export const calculatePriority = (zone) => {
  const { severity, peopleAffected, distance, resourcesPresent } = zone
  return (severity * peopleAffected) / (distance * (resourcesPresent + 1))
}

// Sort zones by priority
export const sortZonesByPriority = (zones) => {
  return [...zones].sort((a, b) => {
    const priorityA = calculatePriority(a)
    const priorityB = calculatePriority(b)
    return priorityB - priorityA
  })
}

// Allocate resources to zones
export const allocateResources = (zones, availableResources) => {
  const sortedZones = sortZonesByPriority(zones)
  const allocation = {}
  let remainingResources = { ...availableResources }

  sortedZones.forEach(zone => {
    allocation[zone.id] = {
      ambulances: 0,
      fireUnits: 0,
      rescueTeams: 0,
      hazmatTeams: 0
    }

    // Allocate based on zone type and priority
    const needsAmbulances = zone.peopleAffected > 0
    const needsFireUnits = zone.type === 'fire' || zone.type === 'explosion'
    const needsRescueTeams = zone.type === 'collapse' || zone.type === 'explosion'
    const needsHazmatTeams = zone.type === 'hazmat'

    // Ambulances allocation (priority for all zones)
    if (needsAmbulances && remainingResources.ambulances > 0) {
      const needed = Math.min(Math.ceil(zone.peopleAffected / 10), remainingResources.ambulances)
      allocation[zone.id].ambulances = needed
      remainingResources.ambulances -= needed
    }

    // Fire units allocation
    if (needsFireUnits && remainingResources.fireUnits > 0) {
      const needed = Math.min(2, remainingResources.fireUnits)
      allocation[zone.id].fireUnits = needed
      remainingResources.fireUnits -= needed
    }

    // Rescue teams allocation
    if (needsRescueTeams && remainingResources.rescueTeams > 0) {
      const needed = Math.min(2, remainingResources.rescueTeams)
      allocation[zone.id].rescueTeams = needed
      remainingResources.rescueTeams -= needed
    }

    // Hazmat teams allocation
    if (needsHazmatTeams && remainingResources.hazmatTeams > 0) {
      allocation[zone.id].hazmatTeams = remainingResources.hazmatTeams
      remainingResources.hazmatTeams = 0
    }
  })

  return { allocation, sortedZones }
}

// Mock Dijkstra-like shortest path (simulated)
export const calculateShortestPath = (startZone, endZone) => {
  // Simulated shortest path calculation
  // In real scenario, this would use actual map coordinates and Dijkstra's algorithm
  const basePath = Math.abs(endZone.distance - startZone.distance)
  const variationFactor = Math.random() * 0.3 + 0.9
  return (basePath * variationFactor).toFixed(2)
}

// Format resource display string
export const formatResourceAllocation = (allocation) => {
  const parts = []
  if (allocation.ambulances > 0) parts.push(`${allocation.ambulances} Ambulance${allocation.ambulances > 1 ? 's' : ''}`)
  if (allocation.fireUnits > 0) parts.push(`${allocation.fireUnits} Fire Unit${allocation.fireUnits > 1 ? 's' : ''}`)
  if (allocation.rescueTeams > 0) parts.push(`${allocation.rescueTeams} Rescue Team${allocation.rescueTeams > 1 ? 's' : ''}`)
  if (allocation.hazmatTeams > 0) parts.push(`${allocation.hazmatTeams} Hazmat Team${allocation.hazmatTeams > 1 ? 's' : ''}`)
  
  return parts.length > 0 ? parts.join(', ') : 'No resources'
}

// Get severity color
export const getSeverityColor = (severity) => {
  if (severity >= 9) return '#dc2626'
  if (severity >= 7) return '#f59e0b'
  return '#10b981'
}

// Get severity label
export const getSeverityLabel = (severity) => {
  if (severity >= 9) return 'Critical'
  if (severity >= 7) return 'High'
  return 'Medium'
}
