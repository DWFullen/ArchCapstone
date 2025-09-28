# Request Details

- Goal: Modularize Azure infrastructure with AFD + WAF, route to Container Apps + Function App + (optional) Storage, enable managed TLS, and pass secrets via CI/CD without prompts.
- Constraints/Notes:
  - Use Azure Verified Modules where possible (AFD profile, etc.)
  - WAF must work for AFD Standard (no managed rule sets) and be ready for Premium
  - Avoid secret outputs; store secrets in Key Vault
  - Keep names compliant with min length rules

---

# Action Plan

## Phase A: Stabilize infra template
- [ ] Review and fix Bicep lints and schema issues in `infra/resources.bicep`
- [ ] Ensure no secrets are emitted as outputs; store in Key Vault instead
- [ ] Ensure resource names meet service minimum length rules with deterministic fallbacks

## Phase B: Front Door + WAF
- [ ] Keep AFD via AVM module with routes for default (Container App) and /api (Function App)
- [ ] Ensure Microsoft.Network Front Door WAF policy with `managedRules` always present
- [ ] For Standard SKU: managedRuleSets = []
- [ ] For Premium SKU: include Microsoft_DefaultRuleSet 2.0
- [ ] Associate WAF to AFD via Microsoft.Cdn securityPolicies and custom domain association
- [ ] Add rate-limit custom rule; ensure valid match conditions

## Phase C: DNS/TLS & Deployment
- [ ] Document DNS CNAME setup for custom domain → *.azurefd.net
- [ ] Validate managed certificate issuance upon DNS verification
- [ ] Provide deployment/run commands (az/azd) and basic verification steps
- [ ] Optional: when `enableCustomDomain` = false, associate WAF to endpoint instead of domain

## Phase D: Clean-up & Follow-ups
- [ ] Remove unnecessary dependsOn
- [ ] Trim unused params
- [ ] Add notes for future enhancements (private endpoints, monitoring, CI secrets flow)

---

# Tracking
- Work items will be marked complete here as they are executed.
