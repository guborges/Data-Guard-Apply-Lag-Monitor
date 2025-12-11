# Oracle Data Guard Apply Lag Monitor

## Overview
This repository contains a shell script used to monitor **Oracle Data Guard Apply Lag** in mission-critical RAC and Exadata environments.  
The script collects the apply lag value directly from dynamic performance views and can be used for scheduled monitoring, alerting, or integration with observability tools.

It was designed to help DBAs detect delays in log apply on physical standby databases, enabling faster troubleshooting and improving Data Guard resiliency.

## Features
- Retrieves **real-time apply lag** using `v$dataguard_stats`
- Supports **Oracle RAC** (multi-thread) and standalone configurations
- Validates database role (Primary vs. Standby)
- Outputs numeric and human-readable values
- Easy to integrate with:
  - Cron jobs
  - Monitoring dashboards
  - Alerting pipelines (email, Slack, webhook, etc.)
- Works on **Exadata** and On-Prem Oracle deployments

## Example Query Used
The script queries:

```sql
SELECT value, time_computed
FROM v$dataguard_stats
WHERE name = 'apply lag';
