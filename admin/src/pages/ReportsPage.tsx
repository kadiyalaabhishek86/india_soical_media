import React, { useState, useEffect } from 'react';
import { AdminApi, ReportItem, FeedbackItem } from '../api/client';

export const ReportsPage: React.FC = () => {
  const [activeSubTab, setActiveSubTab] = useState<'reports' | 'feedback'>('reports');
  const [reports, setReports] = useState<ReportItem[]>([]);
  const [feedbacks, setFeedbacks] = useState<FeedbackItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [filter, setFilter] = useState<string>('all');
  const [suspendModal, setSuspendModal] = useState<{ open: boolean; user: ReportItem | null }>({
    open: false,
    user: null,
  });
  const [suspensionReason, setSuspensionReason] = useState('Violation of Community Guidelines');
  const [actionMessage, setActionMessage] = useState<string | null>(null);

  const loadData = async () => {
    setLoading(true);
    try {
      const [reportsData, feedbackData] = await Promise.all([
        AdminApi.getReports().catch(() => []),
        AdminApi.getFeedback().catch(() => []),
      ]);
      setReports(reportsData);
      setFeedbacks(feedbackData);
    } catch (_) {
      // Fallback
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadData();
  }, []);

  const handleSuspend = async () => {
    if (!suspendModal.user) return;
    try {
      await AdminApi.suspendUser(suspendModal.user.reported_user_id, suspensionReason);
      setActionMessage(`Account for ${suspendModal.user.reported_display_name} has been suspended.`);
      setSuspendModal({ open: false, user: null });
      loadData();
    } catch (e: any) {
      alert(e.message || 'Suspension failed');
    }
  };

  const handleResolveFeedback = async (id: string) => {
    try {
      await AdminApi.resolveFeedback(id);
      setActionMessage('Feedback ticket marked as resolved.');
      loadData();
    } catch (e: any) {
      alert(e.message || 'Failed to update feedback');
    }
  };

  const filteredReports = reports.filter((r) => {
    if (filter === 'all') return true;
    return r.reason === filter;
  });

  return (
    <div style={{ padding: '28px', maxWidth: '1400px', margin: '0 auto' }}>
      {/* Top Header & Main Sub-tab Switcher */}
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '20px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>Safety & User Feedback Center</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>
            Monitor reported accounts and review in-app user feedback and support tickets.
          </p>
        </div>

        <button className="btn-secondary" onClick={loadData}>
          ↻ Refresh
        </button>
      </div>

      {/* Tab Navigation: Reports vs Feedback */}
      <div style={{
        display: 'flex',
        gap: '12px',
        borderBottom: '1px solid var(--border-color)',
        paddingBottom: '12px',
        marginBottom: '24px',
      }}>
        <button
          className={activeSubTab === 'reports' ? 'btn-gold' : 'btn-secondary'}
          onClick={() => setActiveSubTab('reports')}
          style={{ fontSize: '13px', display: 'flex', alignItems: 'center', gap: '8px' }}
        >
          <span>Safety Reports</span>
          <span style={{
            background: activeSubTab === 'reports' ? '#0D0D11' : 'var(--bg-secondary)',
            color: activeSubTab === 'reports' ? 'var(--gold-primary)' : 'var(--text-secondary)',
            padding: '2px 8px',
            borderRadius: '10px',
            fontSize: '11px',
            fontWeight: 'bold',
          }}>
            {reports.length}
          </span>
        </button>

        <button
          className={activeSubTab === 'feedback' ? 'btn-gold' : 'btn-secondary'}
          onClick={() => setActiveSubTab('feedback')}
          style={{ fontSize: '13px', display: 'flex', alignItems: 'center', gap: '8px' }}
        >
          <span>User Feedback & Support</span>
          <span style={{
            background: activeSubTab === 'feedback' ? '#0D0D11' : 'var(--bg-secondary)',
            color: activeSubTab === 'feedback' ? 'var(--gold-primary)' : 'var(--text-secondary)',
            padding: '2px 8px',
            borderRadius: '10px',
            fontSize: '11px',
            fontWeight: 'bold',
          }}>
            {feedbacks.length}
          </span>
        </button>
      </div>

      {actionMessage && (
        <div style={{
          padding: '12px 16px',
          background: 'rgba(78, 159, 112, 0.2)',
          border: '1px solid var(--success)',
          borderRadius: '8px',
          color: 'var(--text-primary)',
          marginBottom: '20px',
        }}>
          {actionMessage}
        </div>
      )}

      {/* TAB 1: SAFETY REPORTS */}
      {activeSubTab === 'reports' && (
        <>
          <div style={{ display: 'flex', gap: '8px', marginBottom: '16px' }}>
            {['all', 'underage', 'threats', 'harassment', 'scam'].map((cat) => (
              <button
                key={cat}
                className={filter === cat ? 'btn-gold' : 'btn-secondary'}
                onClick={() => setFilter(cat)}
                style={{ textTransform: 'capitalize', fontSize: '12px' }}
              >
                {cat}
              </button>
            ))}
          </div>

          <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
            {loading ? (
              <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
                Loading moderation reports...
              </div>
            ) : filteredReports.length === 0 ? (
              <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
                No reports matching this filter.
              </div>
            ) : (
              <table>
                <thead>
                  <tr>
                    <th>Priority / Category</th>
                    <th>Reported User</th>
                    <th>Age / Status</th>
                    <th>Case Details</th>
                    <th>Created</th>
                    <th>Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {filteredReports.map((r) => {
                    const isUrgent = r.reason === 'threats' || r.reason === 'underage';
                    return (
                      <tr key={r.id}>
                        <td>
                          <span className={isUrgent ? 'badge badge-danger' : 'badge badge-warning'}>
                            {r.reason}
                          </span>
                        </td>
                        <td>
                          <strong>{r.reported_display_name}</strong>
                          <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>{r.reported_phone}</div>
                        </td>
                        <td>
                          {r.reported_is_adult ? (
                            <span className="badge badge-success">Adult (18+)</span>
                          ) : (
                            <span className="badge badge-danger">UNDERAGE (&lt;18)</span>
                          )}
                          {r.reported_is_suspended && (
                            <span className="badge badge-danger" style={{ marginLeft: '4px' }}>SUSPENDED</span>
                          )}
                        </td>
                        <td style={{ maxWidth: '320px' }}>
                          <div style={{ color: 'var(--text-primary)', fontSize: '13px' }}>
                            {r.details || 'No additional details provided by reporter.'}
                          </div>
                          {r.call_id && (
                            <div style={{ fontSize: '11px', color: 'var(--text-muted)', marginTop: '2px' }}>
                              Call Session: <code>{r.call_id.substring(0, 12)}...</code>
                            </div>
                          )}
                        </td>
                        <td style={{ color: 'var(--text-secondary)', fontSize: '12px' }}>
                          {new Date(r.created_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                        </td>
                        <td>
                          {!r.reported_is_suspended ? (
                            <button
                              className="btn-danger"
                              onClick={() => setSuspendModal({ open: true, user: r })}
                            >
                              Suspend Account
                            </button>
                          ) : (
                            <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>Actioned</span>
                          )}
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
          </div>
        </>
      )}

      {/* TAB 2: USER FEEDBACK & SUPPORT TICKETS */}
      {activeSubTab === 'feedback' && (
        <div className="card" style={{ padding: '0', overflow: 'hidden' }}>
          {loading ? (
            <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
              Loading user feedback...
            </div>
          ) : feedbacks.length === 0 ? (
            <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
              No user feedback or support tickets submitted yet. When users submit feedback from their Profile screen, it appears here in real-time.
            </div>
          ) : (
            <table>
              <thead>
                <tr>
                  <th>Status</th>
                  <th>Member Name</th>
                  <th>Phone Number</th>
                  <th>Subject</th>
                  <th>Feedback Message</th>
                  <th>Submitted At</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {feedbacks.map((f) => {
                  const isResolved = f.status === 'resolved';
                  return (
                    <tr key={f.id}>
                      <td>
                        <span className={isResolved ? 'badge badge-success' : 'badge badge-warning'}>
                          {f.status.toUpperCase()}
                        </span>
                      </td>
                      <td>
                        <strong>{f.user_display_name}</strong>
                      </td>
                      <td style={{ color: 'var(--text-secondary)', fontSize: '13px' }}>
                        {f.user_phone}
                      </td>
                      <td>
                        <span style={{ color: 'var(--gold-primary)', fontWeight: 'bold', fontSize: '13px' }}>
                          {f.subject}
                        </span>
                      </td>
                      <td style={{ maxWidth: '400px' }}>
                        <div style={{
                          color: 'var(--text-primary)',
                          fontSize: '13px',
                          whiteSpace: 'pre-wrap',
                          background: 'rgba(255, 255, 255, 0.03)',
                          padding: '8px 12px',
                          borderRadius: '6px',
                          border: '1px solid var(--border-color)',
                        }}>
                          {f.message}
                        </div>
                      </td>
                      <td style={{ color: 'var(--text-secondary)', fontSize: '12px', whiteSpace: 'nowrap' }}>
                        {new Date(f.created_at).toLocaleString([], { dateStyle: 'short', timeStyle: 'short' })}
                      </td>
                      <td>
                        {!isResolved ? (
                          <button
                            className="btn-secondary"
                            onClick={() => handleResolveFeedback(f.id)}
                            style={{ fontSize: '12px' }}
                          >
                            Mark Resolved
                          </button>
                        ) : (
                          <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>✓ Resolved</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          )}
        </div>
      )}

      {/* Suspend Confirmation Modal */}
      {suspendModal.open && suspendModal.user && (
        <div style={{
          position: 'fixed',
          top: 0, left: 0, right: 0, bottom: 0,
          background: 'rgba(0, 0, 0, 0.75)',
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          padding: '20px',
          zIndex: 1000,
        }}>
          <div className="card" style={{ maxWidth: '480px', width: '100%', padding: '28px' }}>
            <h3 style={{ fontSize: '18px', color: 'var(--danger)', marginBottom: '12px' }}>
              Suspend Account: {suspendModal.user.reported_display_name}
            </h3>
            <p style={{ fontSize: '13px', color: 'var(--text-secondary)', marginBottom: '16px' }}>
              Suspending this account immediately cancels all active calls, removes queue entries, and logs a staff action audit record.
            </p>

            <label style={{ display: 'block', fontSize: '12px', marginBottom: '6px' }}>
              Recorded Reason for Staff Audit Log:
            </label>
            <textarea
              style={{ width: '100%', minHeight: '80px', marginBottom: '20px' }}
              value={suspensionReason}
              onChange={(e) => setSuspensionReason(e.target.value)}
            />

            <div style={{ display: 'flex', justifyContent: 'flex-end', gap: '10px' }}>
              <button
                className="btn-secondary"
                onClick={() => setSuspendModal({ open: false, user: null })}
              >
                Cancel
              </button>
              <button className="btn-danger" onClick={handleSuspend}>
                Confirm Suspension
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};
