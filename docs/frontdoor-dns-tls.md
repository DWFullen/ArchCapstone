# Azure Front Door DNS & TLS Guidance

## Overview
This document explains how to finalize DNS and TLS for the Front Door deployment created by `frontdoor.bicep`. Managed certificates are issued automatically once CNAME validation succeeds.

## 1. Identify Front Door Endpoint Hostname
After deployment (with `deployFrontDoor=true`), retrieve the endpoint hostname (example: `zus1rcrcwebsitedevv1fd.azurefd.net`). Since the module output is currently not exposed (due to conditional output constraints), you can:
- Use Azure Portal: Front Door profile > Endpoint > Host name
- Or CLI: `az afd endpoint list -g <rg> --profile-name <profileName> -o table`

## 2. Create DNS CNAME Records
For each custom domain you passed:
- `www.rebelcorpo.com` (primary)
- Any additional domains

Add a CNAME record:
```
Host: www
Type: CNAME
Value: <frontDoorEndpointHost>
TTL: 300 (recommended 300–600 during validation)
```
For apex/root domain (`rebelcorpo.com`):
- If your DNS provider supports ALIAS/ANAME flattening, create ALIAS/ANAME to the Front Door endpoint.
- If not supported, consider only using the `www` subdomain or delegating via Azure DNS with alias.

## 3. Propagation & Validation
Typical propagation: 5–15 minutes; could take up to 1 hour.
Managed certificate states:
- `Pending` → DNS not validated yet
- `Issuing` → Validation succeeded, certificate request in progress
- `Deployed` → Active
If stuck in `Pending` > 1 hour, verify CNAME correctness and no conflicting A/AAAA records.

## 4. Forcing Re-Validation
If validation stalls:
1. Remove the custom domain from Front Door.
2. Re-add it after confirming the CNAME.
3. Wait again for state transition.

## 5. WAF Association
The security policy associates the WAF to all custom domains using pattern `/*`.
If you add more domains later:
- Add the domain resource
- Update the security policy association (currently static in module; future enhancement could parametrize incremental domain attach)

## 6. Redirect Behavior
All configured routes enforce HTTPS if `enforceHttpsRedirect=true` (set in module). For HTTP to HTTPS at edge you already have `httpsRedirect: Enabled`.

## 7. Troubleshooting
| Symptom | Possible Cause | Action |
|---------|----------------|--------|
| 403 or 401 at /api/* | Function auth or network restrictions | Check Function App networking & auth settings |
| 502/503 from Front Door | Origins not yet warm or DNS for origin unresolved | Confirm origin hostnames resolve & app responds directly |
| Managed cert stuck Pending | CNAME missing/misconfigured | Re-run DNS, clear conflicting records |
| WAF not blocking expected traffic | Policy in Detection mode | Switch `wafMode` to `Prevention` |

## 8. Future Improvements
- Expose endpoint and WAF outputs directly (requires safe conditional patterns or always-on deployment)
- Add custom response rules or caching rulesets
- Parameterize domain-to-route mapping for multi-site hosting

## 9. References
- Front Door custom domains: https://learn.microsoft.com/azure/frontdoor/standard-premium/how-to-add-custom-domain
- Managed certificates: https://learn.microsoft.com/azure/frontdoor/standard-premium/how-to-configure-https
- WAF with Front Door: https://learn.microsoft.com/azure/web-application-firewall/afds/waf-front-door-overview

---
Document version: 2025-10-06
