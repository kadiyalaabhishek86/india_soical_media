import React, { useState } from 'react';
import { AdminApi, StaffAuth } from '../api/client';

interface LoginPageProps {
  onLoginSuccess: (auth: StaffAuth) => void;
}

export const LoginPage: React.FC<LoginPageProps> = ({ onLoginSuccess }) => {
  const [username, setUsername] = useState('admin');
  const [password, setPassword] = useState('Admin@12345');
  const [tempToken, setTempToken] = useState<string | null>(null);
  const [otpCode, setOtpCode] = useState('123456');
  const [error, setError] = useState<string | null>(null);
  const [loading, setLoading] = useState(false);

  const handleInitialLogin = async (e: React.FormEvent) => {
    e.preventDefault();
    setError(null);
    setLoading(true);
    try {
      const res = await AdminApi.login(username, password);
      if (res.requires_mfa) {
        setTempToken(res.token);
      } else {
        const staffData: StaffAuth = { token: res.token, username, role: 'admin' };
        onLoginSuccess(staffData);
      }
    } catch (err: any) {
      setError(err.message || 'Login failed');
    } finally {
      setLoading(false);
    }
  };

  const handleVerifyMfa = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!tempToken) return;
    setError(null);
    setLoading(true);
    try {
      const staffAuth = await AdminApi.verifyMfa(tempToken, otpCode);
      onLoginSuccess(staffAuth);
    } catch (err: any) {
      setError(err.message || 'Invalid MFA code');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div style={{
      minHeight: '100vh',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'center',
      background: 'radial-gradient(circle at center, #1C1C26 0%, #0D0D11 100%)',
      padding: '20px',
    }}>
      <div className="card" style={{ width: '100%', maxWidth: '420px', padding: '32px' }}>
        <div style={{ textAlign: 'center', marginBottom: '28px' }}>
          <div style={{
            width: '48px',
            height: '48px',
            borderRadius: '50%',
            background: 'var(--gold-primary)',
            color: '#0D0D11',
            display: 'inline-flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '24px',
            marginBottom: '12px',
          }}>आ</div>
          <h2 style={{ fontSize: '22px', fontWeight: 'bold' }}>Aara Operations Console</h2>
          <p style={{ color: 'var(--text-secondary)', fontSize: '13px', marginTop: '4px' }}>
            Restricted Staff & Moderation Portal
          </p>
        </div>

        {error && (
          <div style={{
            background: 'rgba(229, 115, 115, 0.15)',
            border: '1px solid rgba(229, 115, 115, 0.4)',
            color: '#FF9E9B',
            padding: '10px 14px',
            borderRadius: '8px',
            fontSize: '13px',
            marginBottom: '20px',
          }}>
            {error}
          </div>
        )}

        {!tempToken ? (
          <form onSubmit={handleInitialLogin}>
            <div style={{ marginBottom: '16px' }}>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>
                Staff Username
              </label>
              <input
                type="text"
                style={{ width: '100%' }}
                value={username}
                onChange={(e) => setUsername(e.target.value)}
                required
              />
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>
                Password
              </label>
              <input
                type="password"
                style={{ width: '100%' }}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
              />
            </div>

            <button type="submit" className="btn-gold" style={{ width: '100%' }} disabled={loading}>
              {loading ? 'Authenticating...' : 'Sign In'}
            </button>

            <div style={{
              marginTop: '20px',
              padding: '12px',
              background: 'rgba(212, 175, 55, 0.08)',
              border: '1px solid rgba(212, 175, 55, 0.2)',
              borderRadius: '8px',
              fontSize: '11px',
              color: 'var(--text-secondary)',
            }}>
              <strong>Demo Staff Account:</strong><br />
              User: <code>admin</code> • Pass: <code>Admin@12345</code><br />
              Simulated MFA Code: <code>123456</code>
            </div>
          </form>
        ) : (
          <form onSubmit={handleVerifyMfa}>
            <div style={{
              padding: '12px',
              background: 'rgba(78, 159, 112, 0.15)',
              borderRadius: '8px',
              fontSize: '13px',
              marginBottom: '20px',
            }}>
              Step 2 of 2: Multi-Factor Authentication required.
            </div>

            <div style={{ marginBottom: '24px' }}>
              <label style={{ display: 'block', fontSize: '12px', color: 'var(--text-secondary)', marginBottom: '6px' }}>
                6-Digit Authenticator TOTP Code
              </label>
              <input
                type="text"
                style={{ width: '100%', fontSize: '20px', letterSpacing: '4px', textAlign: 'center' }}
                value={otpCode}
                onChange={(e) => setOtpCode(e.target.value)}
                maxLength={6}
                required
                autoFocus
              />
            </div>

            <button type="submit" className="btn-gold" style={{ width: '100%' }} disabled={loading}>
              {loading ? 'Verifying MFA...' : 'Verify & Enter Console'}
            </button>
          </form>
        )}
      </div>
    </div>
  );
};
