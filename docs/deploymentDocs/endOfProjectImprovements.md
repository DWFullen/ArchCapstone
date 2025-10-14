## Automating Azure Front Door origin sync

When the Container App is re-created or its FQDN changes, Azure Front Door’s origin host and origin host header may need updating. To avoid manual fixes, consider one of these options:

- Post-deploy sync in CI/CD (recommended now)
	- After deploying the Container App, query its FQDN and update AFD origin host and origin host header via CLI.
	- Pros: Simple, deterministic, easy to add to existing pipelines.
	- Notes: Make the step idempotent by checking current origin settings first.

- Re-run Front Door deployment with current outputs
	- Feed the Container App FQDN output into the FD module every time infra is applied, not just on first deploy.
	- Pros: Keeps IaC as the source of truth.
	- Notes: Ensure the FD module isn’t gated in a way that prevents updates.

- Stable origin CNAME pattern
	- Point AFD origin to a stable CNAME like `origin.<domain>` that you control; CNAME targets the Container App FQDN.
	- If FQDN changes, update only the CNAME target (no FD changes).
	- Pros: Decouples AFD from app FQDN churn.

- Event-driven automation
	- Use Event Grid → Logic App/Azure Function to detect app changes and patch AFD automatically.
	- Pros: Fully autonomous; no pipeline dependency.
	- Notes: More moving parts and initial setup.

- Reduce FQDN changes
	- Keep the Container App and managed environment stable (avoid delete/recreate) and use deterministic names.

Recommended path:
- Short term: add a post-deploy sync in the pipeline (cheap and reliable).
- Medium term: adopt the stable origin CNAME pattern to avoid touching AFD when the app changes.

