# Agent evaluation and release gates

Every change to the model, system prompt, tools, Cedar policies, memory behavior, or runtime configuration is a new agent release and must pass the same gates. Maintain a versioned, privacy-reviewed evaluation set containing representative tasks, adversarial/prompt-injection cases, cross-tenant attempts, malformed tool inputs, and known regressions. Use synthetic or approved de-identified data; keep expected outcomes and scoring reproducible.

| Measure | Cadence | Pass/fail gate |
|---|---|---|
| Task success and answer correctness, scored against labeled cases | Every pull request; full suite before each release | At least 90% task success and no more than a 1 percentage-point regression from the current production baseline. Critical workflow cases must all pass. |
| Grounding/citation correctness where sources are required | Every release; weekly production sample | At least 98% of sampled factual claims are supported by the cited approved source; no fabricated source references in critical workflows. |
| Tool authorization, tenant isolation, and high-impact action denial | Every policy/tool change and every release | 100% of unauthorized, cross-tenant, delete, refund, and export test attempts are denied; 100% of permitted fixtures are allowed. Any miss blocks release. |
| Prompt injection, sensitive-data handling, unsafe output | Every release; monthly expanded adversarial suite | No critical/high-severity finding; no protected-data disclosure or policy bypass in the release suite. Any confirmed exposure blocks release. |
| p95 latency, errors, throttles, tool-call count | Every release; continuous production monitoring | Meet the service SLO; p95 no worse than 10% versus baseline under matched load; error/throttle rates within agreed SLO. |
| Cost per successful task and total spend | Every release; daily budget/anomaly review | Cost per successful task no more than 10% above the approved baseline unless explicitly accepted; projected spend remains within the approved budget. |
| Memory isolation, retention, and deletion (when enabled) | Every release affecting memory; quarterly | No cross-user/tenant retrieval; deletion and retention tests pass; otherwise memory remains disabled for the workflow. |

## Release sequence

1. **Pull request:** run deterministic unit, schema, Cedar authorization, prompt-injection, and evaluation-set tests. Require reviewer approval for model/policy/tool changes.
2. **Pre-production:** run the full suite against production-equivalent configuration and representative load. Validate current regional model/service availability and residency controls.
3. **Canary:** deploy the immutable version to 5% of eligible traffic for at least 30 minutes and 100 completed tasks (whichever takes longer). Compare quality, policy decisions, errors, p95 latency, and cost against the current version.
4. **Expand:** if no release gate regresses, advance to 25%, then 100%, with an operator monitoring the rollout. Keep a one-step rollback available throughout.
5. **Continuous:** monitor service and safety indicators continuously; review a privacy-approved production sample weekly and investigate every policy anomaly or user-reported unsafe result.

**Automatic rollback / pause:** any unauthorized action or tenant-isolation failure; any sensitive-data disclosure; a critical/high safety issue; task success below 90% or more than 1 percentage-point below baseline; p95 latency more than 10% above baseline; or error/cost exceeding its agreed SLO/budget. Pause rollout, use the incident runbook, and do not waive a security gate to meet a release date.
