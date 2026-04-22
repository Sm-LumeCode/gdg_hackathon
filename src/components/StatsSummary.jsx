export default function StatsSummary({ zones, allocation, availableResources, remainingResources }) {
  const totalPeopleAffected = zones.reduce((sum, z) => sum + z.peopleAffected, 0)
  const avgSeverity = (zones.reduce((sum, z) => sum + z.severity, 0) / zones.length).toFixed(1)
  
  return (
    <div style={{
      display: 'grid',
      gridTemplateColumns: 'repeat(auto-fit, minmax(180px, 1fr))',
      gap: '16px',
      marginBottom: '24px'
    }}>
      <StatCard
        label="Total People Affected"
        value={totalPeopleAffected}
        color="#2563eb"
      />
      <StatCard
        label="Avg Severity"
        value={avgSeverity}
        color="#6b7280"
      />
      <StatCard
        label="Crisis Zones"
        value={zones.length}
        color="#1f2937"
      />
      <StatCard
        label="Ambulances Allocated"
        value={allocation ? Object.values(allocation).reduce((sum, a) => sum + a.ambulances, 0) : 0}
        available={availableResources?.ambulances}
        color="#10b981"
      />
      <StatCard
        label="Fire Units Allocated"
        value={allocation ? Object.values(allocation).reduce((sum, a) => sum + a.fireUnits, 0) : 0}
        available={availableResources?.fireUnits}
        color="#f59e0b"
      />
      <StatCard
        label="Rescue Teams Allocated"
        value={allocation ? Object.values(allocation).reduce((sum, a) => sum + a.rescueTeams, 0) : 0}
        available={availableResources?.rescueTeams}
        color="#ef4444"
      />
    </div>
  )
}

function StatCard({ label, value, available, color }) {
  return (
    <div style={{
      padding: '16px',
      backgroundColor: 'white',
      border: `2px solid ${color}`,
      borderRadius: '6px',
      textAlign: 'center'
    }}>
      <div style={{
        fontSize: '12px',
        color: '#6b7280',
        marginBottom: '8px',
        textTransform: 'uppercase',
        letterSpacing: '0.5px',
        fontWeight: '600'
      }}>
        {label}
      </div>
      <div style={{
        fontSize: '28px',
        fontWeight: '700',
        color: color
      }}>
        {value}
      </div>
      {available !== undefined && (
        <div style={{
          fontSize: '11px',
          color: '#9ca3af',
          marginTop: '6px'
        }}>
          of {available} available
        </div>
      )}
    </div>
  )
}
