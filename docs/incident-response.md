# Misbehaving-agent incident response

**Owner:** on-call service owner, with Security/Privacy escalation as applicable
**Objective:** contain unsafe actions quickly, preserve evidence, restore a known-good release, and verify recovery.

## Detect

Alert the on-call team on:

- Any confirmed unauthorized tool action, cross-tenant access, sensitive-data disclosure, or policy bypass (page immediately).
- AgentCore Policy denials or unexpected allows outside the established baseline.
- Sudden changes in tool-call volume, repeated actions, prompt-attack/safety signals, error rate, latency, or cost per successful task.
- Runtime failures, model throttling, elevated user reports, or unexpected changes in model/prompt/policy versions.

Correlate AgentCore Observability traces and policy decisions with CloudWatch metrics/logs, application/API audit logs, and CloudTrail deployment/identity events. Alert on aggregate identifiers and safe metadata; avoid putting unredacted prompts or customer data in alert messages.

## Contain and investigate

1. **Declare and scope.** Open an incident, record UTC start time, affected agent/version/Region, trace or request IDs, tools, tenants, and suspected impact. Notify Security/Privacy for potential disclosure or access-control events.
2. **Stop harmful actions.** Activate the gateway-wide Cedar `forbid` shutdown in [`agent-actions.cedar`](../policies/agent-actions.cedar), or disable the affected Gateway/target if the policy path is unavailable. Revoke/rotate credentials if compromise is suspected. For a single faulty tool, forbid that action and disable its target. Do not rely on changing the system prompt as containment.
3. **Limit exposure.** Disable memory writes and external integrations if implicated; apply API rate limits or suspend the affected agent. Preserve policy, prompt, model, deployment, and configuration versions before changing them.
4. **Investigate.** Use trace/request IDs to reconstruct inputs, model/version, tool arguments/results, policy decision, caller identity, backend authorization, and data accessed. Preserve evidence in approved restricted storage with access logs and retention controls. Determine the blast radius and whether data export, mutation, or disclosure occurred; avoid copying raw sensitive content into tickets.
5. **Escalate and notify.** Follow the organization's security, privacy, legal, and customer notification procedures and applicable reporting timelines. Record decisions and approvals in the incident record.

## Roll back and recover

1. Roll back the immutable agent image/configuration, prompt, model ID, tool schema/targets, and Cedar policy bundle to the last approved versions. Do not simply remove a deny policy until the replacement state is reviewed.
2. If the change is not isolated, keep the agent or affected tools disabled and restore from the last known-good regional deployment. Do not fail over data or inference across the approved residency boundary.
3. Run the smoke, authorization, tenant-isolation, and safety regression suite from [`evaluation.md`](evaluation.md). Confirm audit logging and alarms are functioning.
4. Re-enable first in a restricted canary with reduced traffic and tool permissions. Monitor policy decisions, incidents, quality, latency, and spend before expanding.
5. Close the shutdown only with incident commander and Security approval. Verify the active release and policies by hash/version, document impact/root cause/remediation, and create follow-up actions.

## Readiness checklist

- A tested, versioned gateway-wide shutdown policy and a restricted operator role.
- Immutable previous release artifacts and policy snapshots available in the recovery Region.
- Trace/request-ID lookup, audit-log retention, escalation contacts, and rollback authority documented.
- Quarterly tabletop or incident simulation; record recovery time and fix gaps.
