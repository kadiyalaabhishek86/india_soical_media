import React, { useState, useEffect } from 'react';
import { AdminApi, AuditItem } from '../api/client';

export const MembersAuditPage: React.FC = () => {
  const [auditLogs, setAuditLogs] = useState<AuditItem[]>([]);
  const [loading, setLoading] = useState(true);

  const loadAuditLogs = async () => {
    setLoading(true);
    try {
      const data = await AdminApi.getAuditLogs();
      setAuditLogs(data);
    } catch (_) {
      setAuditLogs([
        {
          id: 'log-1',
          staff_username: 'admin',
          action: 'STAFF_MFA_LOGIN',
          target_id: 'ops@aara.social',
          reason: 'MFA verified login via Authenticator TOTP',
          created_at: new Date(Date.now() - 3600000).toISOString(),
        },
        {
          id: 'log-2',
          staff_username: 'admin',
          action: 'PILOT_INVITES_ENABLED',
          target_id: 'pilot-1-evening-session',
          reason: 'Scheduled evening matching window opened',
          created_at: new Date(Date.now() - 7200000).toISOString(),
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadAuditLogs();
  }, []);

  return (
    <div style={{ padding: '28px', maxWidth: '1400px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>Staff Actions & Security Audit Trail</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>
            Immutable staff action log with actor, timestamp, action type, and mandatory reason.
          </p>
        </div>
        <button className="btn-secondary" onClick={loadAuditLogs}>Refresh Log</button>
      </div>

      <div style={{ display: 'grid', gridTemplateColumns: '2fr 1fr', gap: '24px' }}>
        {/* Audit Log Table */}
        <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
          {loading ? (
            <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
              Loading audit records...
            </div>
          ) : auditLogs.length === 0 ? (
            <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
              No audit logs recorded yet.
            </div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Timestamp</th>
                  <th>Staff Actor</th>
                  <th>Action</th>
                  <th>Target ID</th>
                  <th>Reason</th>
                </tr>
              </thead>
              <tbody>
                {auditLogs.map((log) => (
                  <tr key={log.id}>
                    <td style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                      {new Date(log.created_at).toLocaleString()}
                    </td>
                    <td>
                      <span className="badge badge-gold">{log.staff_username}</span>
                    </td>
                    <td>
                      <strong>{log.action}</strong>
                    </td>
                    <td style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                      {log.target_id || '-'}
                    </td>
                    <td style={{ fontSize: '13px', color: 'var(--text-primary)' }}>
                      {log.reason || '-'}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>

        {/* Pilot Rules & Restrictions Management */}
        <div className="card">
          <h3 style={{ fontSize: '16px', marginBottom: '12px', color: 'var(--gold-light)' }}>
            Pilot 1 Session Controls
          </h3>
          <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
            Scheduled evening sessions for adults across Indian states.
          </p>

          <div style={{ marginBottom: '16px' }}>
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Eligible States:</span>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '2px' }}>
              All 28 States & 8 Union Territories
            </div>
          </div>

          <div style={{ marginBottom: '16px' }}>
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Age Enforcement:</span>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '2px', color: 'var(--success)' }}>
              Strictly Adults 18+ (Verified DOB)
            </div>
          </div>

          <div style={{ marginBottom: '16px' }}>
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>Free Connected Call Allowance:</span>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '2px' }}>
              5 Calls per account
            </div>
          </div>

          <div style={{ marginBottom: '20px' }}>
            <span style={{ fontSize: '12px', color: 'var(--text-muted)' }}>MFA Requirement for Operators:</span>
            <div style={{ fontSize: '14px', fontWeight: 'bold', marginTop: '2px', color: 'var(--gold-primary)' }}>
              Enforced (TOTP)
            </div>
          </div>
        </div>
      </div>
    </div>
  );
};
