const BASE_URL = 'http://127.0.0.1:8000/api/v1';

export interface StaffAuth {
  token: string;
  username: string;
  role: string;
}

export interface ReportItem {
  id: string;
  reported_user_id: string;
  reported_display_name: string;
  reported_phone: string;
  reported_dob: string;
  reported_is_adult: boolean;
  reported_is_suspended: boolean;
  call_id?: string;
  reason: string;
  details?: string;
  status: string;
  created_at: string;
}

export interface FeedbackItem {
  id: string;
  user_id: string;
  user_display_name: string;
  user_phone: string;
  subject: string;
  message: string;
  status: string;
  created_at: string;
}

export interface MetricsData {
  total_users: number;
  queue_wait_average_seconds: number;
  connection_success_rate: number;
  connected_minutes_voice: number;
  connected_minutes_video: number;
  fifth_call_completion_count: number;
  otp_sends_count: number;
  estimated_provider_spend_inr: number;
}

export interface PassItem {
  id: string;
  user_id: string;
  purchase_token: string;
  order_id: string;
  price_inr: number;
  duration_minutes: number;
  starts_at: string;
  expires_at: string;
  status: string;
  created_at: string;
}

export interface AuditItem {
  id: string;
  staff_username: string;
  action: string;
  target_id?: string;
  reason?: string;
  created_at: string;
}

export class AdminApi {
  private static getToken(): string | null {
    return localStorage.getItem('aara_staff_token');
  }

  private static headers(): HeadersInit {
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
    };
    const token = this.getToken();
    if (token) {
      headers['Authorization'] = `Bearer ${token}`;
    }
    return headers;
  }

  static async login(username: string, password: string): Promise<{ token: string; requires_mfa: boolean }> {
    const res = await fetch(`${BASE_URL}/admin/login`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ username, password }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: 'Login failed' }));
      throw new Error(err.detail || 'Login failed');
    }
    return res.json();
  }

  static async verifyMfa(tempToken: string, otpCode: string): Promise<StaffAuth> {
    const res = await fetch(`${BASE_URL}/admin/verify-mfa`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ temp_token: tempToken, otp_code: otpCode }),
    });
    if (!res.ok) {
      const err = await res.json().catch(() => ({ detail: 'MFA failed' }));
      throw new Error(err.detail || 'MFA failed');
    }
    const data = await res.json();
    localStorage.setItem('aara_staff_token', data.token);
    localStorage.setItem('aara_staff_user', JSON.stringify(data));
    return data;
  }

  static async getReports(): Promise<ReportItem[]> {
    const res = await fetch(`${BASE_URL}/admin/reports`, { headers: this.headers() });
    if (!res.ok) throw new Error('Failed to load reports');
    return res.json();
  }

  static async getFeedback(): Promise<FeedbackItem[]> {
    const res = await fetch(`${BASE_URL}/admin/feedback`, { headers: this.headers() });
    if (!res.ok) throw new Error('Failed to load feedback');
    return res.json();
  }

  static async resolveFeedback(ticketId: string): Promise<void> {
    const res = await fetch(`${BASE_URL}/admin/feedback/${encodeURIComponent(ticketId)}/resolve`, {
      method: 'POST',
      headers: this.headers(),
    });
    if (!res.ok) throw new Error('Failed to resolve feedback');
  }

  static async suspendUser(userId: string, reason: string): Promise<void> {
    const res = await fetch(`${BASE_URL}/admin/suspend`, {
      method: 'POST',
      headers: this.headers(),
      body: JSON.stringify({ user_id: userId, reason }),
    });
    if (!res.ok) throw new Error('Failed to suspend user');
  }

  static async getMetrics(): Promise<MetricsData> {
    const res = await fetch(`${BASE_URL}/admin/metrics`, { headers: this.headers() });
    if (!res.ok) throw new Error('Failed to load metrics');
    return res.json();
  }

  static async getPurchases(query?: string): Promise<PassItem[]> {
    const url = query ? `${BASE_URL}/admin/purchases?query=${encodeURIComponent(query)}` : `${BASE_URL}/admin/purchases`;
    const res = await fetch(url, { headers: this.headers() });
    if (!res.ok) throw new Error('Failed to load purchases');
    return res.json();
  }

  static async refundPurchase(token: string): Promise<void> {
    const res = await fetch(`${BASE_URL}/admin/refund/${encodeURIComponent(token)}`, {
      method: 'POST',
      headers: this.headers(),
    });
    if (!res.ok) throw new Error('Failed to refund purchase');
  }

  static async getAuditLogs(): Promise<AuditItem[]> {
    const res = await fetch(`${BASE_URL}/admin/audit-logs`, { headers: this.headers() });
    if (!res.ok) throw new Error('Failed to load audit logs');
    return res.json();
  }

  static logout() {
    localStorage.removeItem('aara_staff_token');
    localStorage.removeItem('aara_staff_user');
  }
}
