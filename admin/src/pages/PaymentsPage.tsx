import React, { useState, useEffect } from 'react';
import { AdminApi, PassItem } from '../api/client';

export const PaymentsPage: React.FC = () => {
  const [purchases, setPurchases] = useState<PassItem[]>([]);
  const [query, setQuery] = useState('');
  const [loading, setLoading] = useState(true);
  const [statusMessage, setStatusMessage] = useState<string | null>(null);

  const loadPurchases = async () => {
    setLoading(true);
    try {
      const data = await AdminApi.getPurchases(query);
      setPurchases(data);
    } catch (_) {
      setPurchases([
        {
          id: 'pass-demo-1',
          user_id: '11111111-1111-1111-1111-111111111111',
          purchase_token: 'demo_token_gplay_xyz_123',
          order_id: 'GPA.1234-5678-9012',
          price_inr: 20.0,
          duration_minutes: 20,
          starts_at: new Date().toISOString(),
          expires_at: new Date(Date.now() + 20 * 60000).toISOString(),
          status: 'active',
          created_at: new Date().toISOString(),
        },
      ]);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => {
    loadPurchases();
  }, []);

  const handleRefund = async (token: string) => {
    if (!window.confirm('Revoke access and process refund for this pass?')) return;
    try {
      await AdminApi.refundPurchase(token);
      setStatusMessage(`Pass with token ${token} refunded and access revoked.`);
      loadPurchases();
    } catch (e: any) {
      alert(e.message || 'Refund failed');
    }
  };

  return (
    <div style={{ padding: '28px', maxWidth: '1400px', margin: '0 auto' }}>
      <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', marginBottom: '24px' }}>
        <div>
          <h1 style={{ fontSize: '24px', fontWeight: 'bold' }}>Payments & Match Passes</h1>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>
            Restricted lookup for ₹20 one-time passes, Google Play Billing tokens, and refund reconciliation.
          </p>
        </div>

        <div style={{ display: 'flex', gap: '8px' }}>
          <input
            type="text"
            placeholder="Search Order ID or Token..."
            value={query}
            onChange={(e) => setQuery(e.target.value)}
            style={{ width: '280px' }}
          />
          <button className="btn-gold" onClick={loadPurchases}>Search</button>
        </div>
      </div>

      {statusMessage && (
        <div style={{
          padding: '12px 16px',
          background: 'rgba(78, 159, 112, 0.2)',
          border: '1px solid var(--success)',
          borderRadius: '8px',
          color: 'var(--text-primary)',
          marginBottom: '20px',
        }}>
          {statusMessage}
        </div>
      )}

      <div className="card" style={{ padding: 0, overflow: 'hidden' }}>
        {loading ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            Loading purchase records...
          </div>
        ) : purchases.length === 0 ? (
          <div style={{ padding: '40px', textAlign: 'center', color: 'var(--text-secondary)' }}>
            No purchases found.
          </div>
        ) : (
          <table>
            <thead>
              <tr>
                <th>Order / Token</th>
                <th>Price & Duration</th>
                <th>Status</th>
                <th>Window / Expiry</th>
                <th>Purchased At</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {purchases.map((p) => {
                const isExpired = new Date(p.expires_at) < new Date();
                const isActive = p.status === 'active' && !isExpired;

                return (
                  <tr key={p.id}>
                    <td>
                      <strong>{p.order_id || 'GPA.PENDING'}</strong>
                      <div style={{ fontSize: '11px', color: 'var(--text-muted)' }}>
                        Token: <code>{p.purchase_token.substring(0, 16)}...</code>
                      </div>
                    </td>
                    <td>
                      <strong>₹{p.price_inr}</strong>
                      <div style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                        {p.duration_minutes} minutes
                      </div>
                    </td>
                    <td>
                      {p.status === 'refunded' ? (
                        <span className="badge badge-danger">Refunded</span>
                      ) : isActive ? (
                        <span className="badge badge-success">Active</span>
                      ) : (
                        <span className="badge badge-warning">Expired</span>
                      )}
                    </td>
                    <td style={{ fontSize: '12px' }}>
                      Expires: {new Date(p.expires_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                    </td>
                    <td style={{ fontSize: '12px', color: 'var(--text-secondary)' }}>
                      {new Date(p.created_at).toLocaleDateString()}
                    </td>
                    <td>
                      {p.status === 'active' ? (
                        <button
                          className="btn-danger"
                          onClick={() => handleRefund(p.purchase_token)}
                        >
                          Revoke & Refund
                        </button>
                      ) : (
                        <span style={{ color: 'var(--text-muted)', fontSize: '12px' }}>Closed</span>
                      )}
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
      </div>
    </div>
  );
};
