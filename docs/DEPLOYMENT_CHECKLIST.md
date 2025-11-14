# Agentforce Deployment Checklist

Use this checklist for every Agentforce agent deployment to avoid common issues.

## Pre-Deployment

- [ ] **Verify Bot exists in org**
  ```bash
  sf project retrieve start --metadata Bot:AgentName
  ```
  - If not found: Create via UI (Setup → Agentforce → Agents → New Agent)

- [ ] **Check naming consistency**
  - [ ] Bot name matches GenAiPlannerBundle masterLabel
  - [ ] BotVersion genAiPlannerName matches GenAiPlannerBundle name
  - [ ] All names are case-sensitive and match exactly

- [ ] **Validate BotVersion metadata**
  - [ ] All conversation variables have `<visibility>` attribute (External/Internal)
  - [ ] `<genAiPlannerName>` matches GenAiPlannerBundle name
  - [ ] Required fields present (entryDialog, toneType, etc.)

- [ ] **Validate Bot metadata**
  - [ ] `<type>` field present (InternalCopilot or ExternalCopilot)
  - [ ] `botMlDomain.name` matches Bot API name

- [ ] **Validate GenAiPlannerBundle metadata**
  - [ ] `masterLabel` matches Bot name
  - [ ] API version is 64.0 or higher

## Deployment Steps

- [ ] **Step 1: Deploy GenAiPlannerBundle**
  ```bash
  sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AgentName
  ```
  - [ ] Verify deployment success
  - [ ] Note component ID for reference

- [ ] **Step 2: Deploy BotVersion (if Bot exists)**
  ```bash
  sf project deploy start --source-dir force-app/main/default/bots/AgentName
  ```
  - [ ] Verify deployment success
  - [ ] Check for any warnings

- [ ] **Step 3: Verify deployment**
  ```bash
  sf project retrieve start --metadata Bot:AgentName
  ```
  - [ ] All components retrieved successfully
  - [ ] No errors in retrieval

## Post-Deployment

- [ ] **Activate agent version (if needed)**
  ```bash
  sf agent activate --api-name AgentName
  ```
  - Or activate via UI

- [ ] **Test in Salesforce UI**
  - [ ] Navigate to Setup → Agentforce → Agents
  - [ ] Open agent and verify configuration
  - [ ] Test agent in preview mode
  - [ ] Verify welcome message displays correctly
  - [ ] Verify error handling works

- [ ] **Document component IDs**
  - [ ] Bot ID: `_________________`
  - [ ] BotVersion ID: `_________________`
  - [ ] GenAiPlannerBundle ID: `_________________`

## Common Issues to Watch For

- [ ] ❌ "The field Agent Type is required" → Bot doesn't exist, create via UI
- [ ] ❌ "Variable visibility must be specified" → Add visibility to conversation variables
- [ ] ❌ "Entity cannot be found" → Check name spelling and case
- [ ] ❌ "genAiPlannerName mismatch" → Verify names match exactly

## Quick Reference

**Deployment Order:**
1. Create Bot via UI (if needed)
2. Deploy GenAiPlannerBundle
3. Deploy BotVersion
4. Activate agent

**Required Fields:**
- Bot: `<type>`, `botMlDomain.name`
- BotVersion: `<genAiPlannerName>`, conversation variable `<visibility>`
- GenAiPlannerBundle: `masterLabel`

**Verification:**
```bash
# Check all components
sf project retrieve start --metadata Bot:AgentName
sf project retrieve start --metadata GenAiPlannerBundle:AgentName
```

---

**Last Updated:** Based on AF_Decision_Maker deployment experience  
**For detailed information:** See [AGENTFORCE_DEPLOYMENT_GUIDE.md](./AGENTFORCE_DEPLOYMENT_GUIDE.md)

