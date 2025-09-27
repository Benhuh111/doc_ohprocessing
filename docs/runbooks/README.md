Runbook templates for Doc_Ohpp

This folder contains runbooks and incident playbooks for common alerts and operational tasks.

1) High 5xx error rate (API)
- Symptoms: CloudWatch alarm for 5xx triggers. Users report failed uploads or 5xx responses.
- Quick checks:
  - Check application logs in CloudWatch: look for stack traces and root cause.
  - Check X-Ray: find slow traces and error segments.
  - Check application health endpoint: `curl -sS http://<instance-ip>:8080/api/documents/health`.
  - Check recent deployment in CodeDeploy console for failures.
- Mitigation steps:
  - If recent deployment failed, trigger automatic rollback via CodeDeploy or redeploy last stable revision.
  - If JVM OOM/GC issues, capture heap dump and restart the app on instance via systemd script: `sudo systemctl restart docohpp`.
  - If an external dependency (DynamoDB/S3) is failing, check AWS service health and retry logic.
- Post-incident:
  - Create an incident ticket, capture root cause, and add remediation to code or infra configs.

2) Latency spike (P95 > threshold)
- Symptoms: CloudWatch latency alarm.
- Quick checks:
  - Check X-Ray traces for slow segments.
  - Check JVM GC metrics and CPU usage.
  - Inspect DB/DynamoDB latency or throttling metrics.
- Mitigation steps:
  - Scale out instances if under-provisioned or increase autoscaling target.
  - Restart unhealthy instance(s) to return them to LB pool.

3) SQS queue depth increase
- Symptoms: ApproximateNumberOfMessagesVisible alarm triggers.
- Quick checks:
  - Inspect consumer logs for errors or backlog.
  - Check CloudWatch metrics for messages-in-flight and consumer error rates.
- Mitigation steps:
  - Increase consumer capacity (scale out), or trigger an emergency worker to drain the queue.
  - If the message processing fails due to data errors, inspect message payloads and move problematic items to DLQ.

4) CodeDeploy deployment failure
- Symptoms: Deployment failed in CodeDeploy console, instances in FAILED state.
- Quick checks:
  - Open deployment in CodeDeploy console and inspect lifecycle event logs.
  - Check appspec.yml hooks for failing scripts under `deployment/aws-codedeploy/`.
- Mitigation steps:
  - Trigger automatic rollback (if enabled) or manually redeploy last known good revision.
  - Fix failing lifecycle scripts, re-bundle artifact, and retry.

Contact & escalation
- Primary on-call: <owner-email / PagerDuty>
- Infra owner: <infra-owner-email>
- Repo owner: https://github.com/Benhuh111

Maintenance tasks
- Rotate IAM keys quarterly.
- Review CloudWatch alarms monthly.
- Patch OS/AMI monthly; review major runtime upgrades quarterly.

Storage
- Keep runbooks in this folder; update on each postmortem.


