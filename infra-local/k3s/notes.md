## Loki setup
- Use grafana/loki chart in SingleBinary mode for local
- Filesystem storage only
- Promtail must be installed separately

## Issues
- No logs until promtail installed
- If service are deployed before promptail installation, make sure to restart/rollout to get the log.