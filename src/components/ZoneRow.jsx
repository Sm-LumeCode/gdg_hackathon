import { getSeverityColor, getSeverityLabel } from '../utils'

export default function ZoneRow({ zone, priority, allocation, index }) {
  const resourceString = allocation && Object.values(allocation).some(v => v > 0)
    ? `${allocation.ambulances > 0 ? allocation.ambulances + ' Amb' : ''}${allocation.fireUnits > 0 ? (allocation.ambulances > 0 ? ', ' : '') + allocation.fireUnits + ' Fire' : ''}${allocation.rescueTeams > 0 ? (allocation.ambulances > 0 || allocation.fireUnits > 0 ? ', ' : '') + allocation.rescueTeams + ' Rescue' : ''}${allocation.hazmatTeams > 0 ? (allocation.ambulances > 0 || allocation.fireUnits > 0 || allocation.rescueTeams > 0 ? ', ' : '') + allocation.hazmatTeams + ' Hazmat' : ''}`
    : 'No allocation'

  const severityColor = getSeverityColor(zone.severity)
  
  return (
    <tr style={{ borderBottom: '1px solid #e5e7eb' }}>
      <td style={{ padding: '12px', textAlign: 'center', fontSize: '14px', color: '#6b7280' }}>
        {index + 1}
      </td>
      <td style={{ padding: '12px', fontSize: '14px', fontWeight: '500', color: '#1f2937' }}>
        {zone.name}
      </td>
      <td style={{ padding: '12px', textAlign: 'center' }}>
        <div style={{
          display: 'inline-block',
          backgroundColor: severityColor,
          color: 'white',
          padding: '4px 12px',
          borderRadius: '4px',
          fontSize: '13px',
          fontWeight: '600'
        }}>
          {zone.severity} ({getSeverityLabel(zone.severity)})
        </div>
      </td>
      <td style={{ padding: '12px', textAlign: 'center', fontSize: '14px', color: '#1f2937' }}>
        {zone.peopleAffected}
      </td>
      <td style={{ padding: '12px', textAlign: 'center', fontSize: '14px', color: '#1f2937' }}>
        {zone.distance} km
      </td>
      <td style={{ padding: '12px', textAlign: 'center', fontSize: '14px', color: '#1f2937' }}>
        {zone.resourcesPresent}
      </td>
      <td style={{ padding: '12px', textAlign: 'center', fontSize: '14px', fontWeight: '600', color: '#2563eb' }}>
        {priority.toFixed(2)}
      </td>
      <td style={{ padding: '12px', fontSize: '13px', color: '#1f2937' }}>
        {resourceString}
      </td>
    </tr>
  )
}
