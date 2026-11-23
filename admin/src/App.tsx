import React, { useState, useEffect } from 'react';
import { StaffAuth, AdminApi } from './api/client';
import { Navbar } from './components/Navbar';
import { LoginPage } from './pages/LoginPage';
import { ReportsPage } from './pages/ReportsPage';
import { CallsUsagePage } from './pages/CallsUsagePage';
import { PaymentsPage } from './pages/PaymentsPage';
import { MembersAuditPage } from './pages/MembersAuditPage';

export const App: React.FC = () => {
  const [staffUser, setStaffUser] = useState<StaffAuth | null>(null);
  const [activeTab, setActiveTab] = useState<string>('reports');

  useEffect(() => {
    const saved = localStorage.getItem('aara_staff_user');
    if (saved) {
      try {
        setStaffUser(JSON.parse(saved));
      } catch (_) {}
    }
  }, []);

  const handleLoginSuccess = (auth: StaffAuth) => {
    setStaffUser(auth);
  };

  const handleLogout = () => {
    AdminApi.logout();
    setStaffUser(null);
  };

  if (!staffUser) {
    return <LoginPage onLoginSuccess={handleLoginSuccess} />;
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <Navbar
        activeTab={activeTab}
        onTabChange={setActiveTab}
        staffUser={staffUser}
        onLogout={handleLogout}
      />

      <main style={{ flex: 1, backgroundColor: 'var(--bg-primary)' }}>
        {activeTab === 'reports' && <ReportsPage />}
        {activeTab === 'usage' && <CallsUsagePage />}
        {activeTab === 'payments' && <PaymentsPage />}
        {activeTab === 'members' && <MembersAuditPage />}
      </main>
    </div>
  );
};

export default App;
