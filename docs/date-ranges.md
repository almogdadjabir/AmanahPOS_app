# Date ranges: local day vs backend UTC day

Backend `date_from` / `date_to` (sales list/summary/reports, inventory inbound,
vendor-summary, premium-summary) are **UTC calendar days**, day D =
[D 00:00Z, D+1 00:00Z). They are NOT converted to `business.timezone`.

In the app:
- Sales history, dashboard, debts, shifts are **local SQLite**: they use
  `BusinessDay.utcTextRange(zone)` (exact local-day bounds). No limitation.
- The only REST call that sends dates today is `GET sales/reports/`
  (`SalesHistoryRepoImpl._buildReportUri`). It goes through
  `BusinessDay.restDateParam`, the single mapping point.
  `inbound/vendor-summary` accepts dates but the app sends none.

Where the local day can be off: any REST date endpoint, by the zone offset.
Khartoum (UTC+2): the first 2 hours of local day D (00:00-02:00) belong to UTC
day D-1, so they are missing from "D" and appear in the previous day.

Backend follow-up requested: accept ISO datetime bounds (`date_from=...Z`)
or honour `business.timezone`. Once available, change only `restDateParam`.
