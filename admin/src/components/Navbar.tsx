import React from 'react';
import { StaffAuth } from '../api/client';

interface NavbarProps {
  activeTab: string;
  onTabChange: (tab: string) => void;
  staffUser: StaffAuth | null;
  onLogout: () => void;
}

export const Navbar: React.FC<NavbarProps> = ({
  activeTab,
  onTabChange,
  staffUser,
  onLogout,
}) => {
  const tabs = [
    { id: 'reports', label: 'Reports & Safety' },
    { id: 'usage', label: 'Calls & Usage' },
    { id: 'payments', label: 'Payments & Passes' },
    { id: 'members', label: 'Members & Audit' },
  ];

  return (
    <header style={{
      backgroundColor: 'var(--bg-secondary)',
      borderBottom: '1px solid var(--border-color)',
      padding: '0 24px',
      display: 'flex',
      alignItems: 'center',
      justifyContent: 'space-between',
      height: '64px',
    }}>
      <div style={{ display: 'flex', alignItems: 'center', gap: '28px' }}>
        <div style={{ display: 'flex', alignItems: 'center', gap: '10px' }}>
          <div style={{
            width: '32px',
            height: '32px',
            borderRadius: '50%',
            background: 'var(--gold-primary)',
            color: '#0D0D11',
            display: 'flex',
            alignItems: 'center',
            justifyContent: 'center',
            fontWeight: 'bold',
            fontSize: '18px',
          }}>आ</div>
          <span style={{ fontSize: '18px', fontWeight: 'bold', letterSpacing: '0.5px' }}>
            Aara Console
          </span>
          <span className="badge badge-gold" style={{ marginLeft: '6px' }}>Pilot Ops</span>
        </div>

        <nav style={{ display: 'flex', gap: '4px' }}>
          {tabs.map((tab) => {
            const isActive = activeTab === tab.id;
            return (
              <button
                key={tab.id}
                onClick={() => onTabChange(tab.id)}
                style={{
                  background: isActive ? 'var(--bg-card)' : 'transparent',
                  color: isActive ? 'var(--gold-light)' : 'var(--text-secondary)',
                  border: isActive ? '1px solid var(--border-color)' : '1px solid transparent',
                  padding: '8px 16px',
                  borderRadius: '6px',
                  fontSize: '13px',
                }}
              >
                {tab.label}
              </button>
            );
          })}
        </nav>
      </div>

      <div style={{ display: 'flex', alignItems: 'center', gap: '16px' }}>
        {staffUser && (
          <div style={{ display: 'flex', alignItems: 'center', gap: '10px', fontSize: '13px' }}>
            <span style={{ color: 'var(--text-secondary)' }}>
              Logged in as <strong style={{ color: 'var(--text-primary)' }}>{staffUser.username}</strong>
            </span>
            <span className="badge badge-gold">{staffUser.role}</span>
            <span className="badge badge-success">MFA Active</span>
          </div>
        )}
        <button className="btn-secondary" onClick={onLogout} style={{ fontSize: '12px' }}>
          Sign Out
        </button>
      </div>
    </header>
  );
};
