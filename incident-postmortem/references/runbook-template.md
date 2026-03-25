# Runbook Template

## Runbook: [SERVICE/ALERT NAME]

**Last Updated**: YYYY-MM-DD
**Owner**: [team/person]
**Alert**: [alert name that triggers this runbook]

---

## Overview
[What this service does, why it matters, what happens when it fails]

## Quick Reference

| Item | Value |
|------|-------|
| Dashboard | [link] |
| Logs | [link to Kibana/CloudWatch/Grafana] |
| Service | [service name in K8s/ECS] |
| Repo | [GitHub link] |
| On-call | [PagerDuty/OpsGenie link] |
| Slack | [#channel] |

## Diagnostic Steps

### Step 1: Assess Severity
```bash
# Check service health
curl -s https://api.example.com/health | jq .

# Check error rate (last 5 min)
# [Prometheus/CloudWatch query]

# Check number of affected users
# [query to estimate impact]
```

**If error rate > 5%**: Escalate to P1
**If error rate 1-5%**: P2, continue diagnosis
**If error rate < 1%**: P3, investigate during business hours

### Step 2: Check Common Causes

#### Database Connection Issues
```bash
# Check connection pool
docker exec postgres psql -U user -d db -c "SELECT count(*) FROM pg_stat_activity;"

# Check slow queries
docker exec postgres psql -U user -d db -c "
  SELECT pid, now() - pg_stat_activity.query_start AS duration, query
  FROM pg_stat_activity
  WHERE state != 'idle' AND query_start < now() - interval '30 seconds'
  ORDER BY duration DESC;"
```

#### Memory/CPU Issues
```bash
# Check container resources
docker stats --no-stream

# Check node resources
top -bn1 | head -20
free -h
df -h
```

#### External Dependency Down
```bash
# Check connectivity to dependencies
curl -s -o /dev/null -w "%{http_code}" https://external-api.com/health

# Check DNS
nslookup external-api.com
```

### Step 3: Apply Fix

#### Option A: Restart Service
```bash
# Docker
docker restart service-name

# Kubernetes
kubectl rollout restart deployment/service-name -n production

# ECS
aws ecs update-service --cluster prod --service service-name --force-new-deployment
```

#### Option B: Scale Up
```bash
# Kubernetes
kubectl scale deployment/service-name --replicas=5 -n production

# ECS
aws ecs update-service --cluster prod --service service-name --desired-count 5
```

#### Option C: Rollback
```bash
# Kubernetes
kubectl rollout undo deployment/service-name -n production

# Manual rollback to specific version
kubectl set image deployment/service-name container=image:previous-tag -n production
```

#### Option D: Toggle Feature Flag
```bash
# If using feature flags, disable the problematic feature
curl -X PUT https://flags.example.com/api/flags/FEATURE_X -d '{"enabled": false}'
```

### Step 4: Verify Recovery
```bash
# Check service health
curl -s https://api.example.com/health | jq .

# Monitor error rate for 10 minutes
# [watch dashboard link]

# Verify specific user flows
curl -s https://api.example.com/api/v1/test-endpoint
```

### Step 5: Communicate
```
# Slack message template:
🟢 [Service Name] - Recovered
- Issue: [brief description]
- Duration: [start] - [end]
- Impact: [users/requests affected]
- Resolution: [what was done]
- RCA: [will be published by DATE]
```

## Escalation

| Level | Contact | When |
|-------|---------|------|
| L1 | On-call engineer | First response |
| L2 | Team lead | After 15 min without resolution |
| L3 | Engineering manager | After 30 min or customer-facing P1 |
| L4 | CTO | Data breach or extended outage (> 1h) |

## Emergency Contacts

| Role | Name | Phone |
|------|------|-------|
| On-call | [rotação] | [PagerDuty] |
| DB Admin | [name] | [phone] |
| Infra Lead | [name] | [phone] |

## Related Runbooks
- [Link to related service runbook]
- [Link to database runbook]
- [Link to infrastructure runbook]
