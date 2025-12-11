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
  - cron jobs
  - monitoring dashboards
  - alerting pipelines (email, Slack, webhooks, etc.)
- Works on **Exadata** and on-prem Oracle deployments

## Example query used
The script queries:

    SELECT value, time_computed
    FROM v$dataguard_stats
    WHERE name = 'apply lag';

## Requirements
- Linux environment
- Bash
- SQL*Plus client installed
- Oracle environment configured (`ORACLE_HOME`, `ORACLE_SID`, `PATH`)
- User with permission to query V$ views (SYS, SYSDG, or a user with `SELECT_CATALOG_ROLE`)

## Usage

1. Clone the repository:

        git clone https://github.com/guborges/Data-Guard-Apply-Lag-Monitor.git
        cd Data-Guard-Apply-Lag-Monitor

2. Edit database connection variables inside the script:

        vi dg_apply_lag.sh

3. Make the script executable:

        chmod +x dg_apply_lag.sh

4. Run the monitor:

        ./dg_apply_lag.sh

## Script output example

    Apply Lag: +00 00:00:02
    Time Computed: 2025-12-10 14:33:21
    Status: OK – Apply is synchronized.

If lag exceeds predefined thresholds, the script can be easily extended to trigger alerts or integrate with external monitoring/alerting tools.

## File structure

    Data-Guard-Apply-Lag-Monitor/
    ├── dg_apply_lag.sh
    └── README.md

## Notes
This script is used in real-world **Exadata Cloud@Customer** environments where Data Guard apply performance is mission-critical.  
It provides a lightweight and reliable way to monitor synchronization between primary and standby databases.

## License
MIT License
