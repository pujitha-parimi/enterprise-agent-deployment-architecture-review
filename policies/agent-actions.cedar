// Illustrative policy set for an OAuth-authenticated AgentCore Gateway.
// Replace the sample Gateway ARN, action IDs, and claim names with the values
// in the deployed Gateway schema, then schema-validate and test before use.
// Account ID below is a documentation-only example, not a real credential.

// Allow support agents to read customer records only within their own tenant.
permit(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"CustomerAPI___get_customer",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
)
when {
  principal.hasTag("role") &&
  principal.getTag("role") == "support-agent" &&
  principal.hasTag("tenant_id") &&
  context.input.tenantId == principal.getTag("tenant_id")
};

// Allow support-case creation only for the authenticated tenant and approved
// low-risk priorities. The backend must independently authorize the tenant.
permit(
  principal is AgentCore::OAuthUser,
  action == AgentCore::Action::"CaseAPI___create_case",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
)
when {
  principal.hasTag("role") &&
  principal.getTag("role") == "support-agent" &&
  principal.hasTag("tenant_id") &&
  context.input.tenantId == principal.getTag("tenant_id") &&
  (context.input.priority == "low" || context.input.priority == "normal")
};

// Never allow this assistant to perform high-impact actions. Route these
// operations to separately authenticated, human-operated workflows.
forbid(
  principal,
  action == AgentCore::Action::"CustomerAPI___delete_customer",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
);

forbid(
  principal,
  action == AgentCore::Action::"PaymentsAPI___issue_refund",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
);

forbid(
  principal,
  action == AgentCore::Action::"AdminAPI___export_data",
  resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
);

// Break-glass containment: activate as an incident change to block every
// tool invocation through this Gateway. Remove only after incident approval.
// Cedar forbid-wins behavior overrides the permits above.
// Uncomment only when the gateway-wide shutdown is intentional:
//
// forbid(
//   principal,
//   action,
//   resource == AgentCore::Gateway::"arn:aws:bedrock-agentcore:us-east-1:111122223333:gateway/enterprise-agent-gateway"
// );

/*
Policy matrix

Policy                         Effect    Primary control
CustomerAPI___get_customer     Permit    Support role + tenant match
CaseAPI___create_case          Permit    Support role + tenant + low/normal priority
Delete/refund/export           Forbid    No agent access to high-impact operations
Gateway-wide shutdown          Forbid    Incident-only containment; forbid wins

Deployment requirements:
1. Confirm the Gateway uses OAuth and that trusted OIDC claims map to the
   expected principal tags. Do not trust model-supplied identity or tenant IDs.
2. Match every action ID and input property to the Gateway-generated Cedar
   schema; this file is a template, not a drop-in policy bundle.
3. Schema-validate, run positive/negative authorization tests, and use
   LOG_ONLY/shadow evaluation before enforcement where supported.
4. Backend APIs must re-check user/tenant authorization. Cedar is not a
   substitute for data-layer access control.
*/
