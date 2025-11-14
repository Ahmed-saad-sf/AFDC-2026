# Agentforce Deployment Quick Reference

Quick reference for common Agentforce deployment tasks.

## ⚠️ Critical Requirements

1. **Bot MUST be created via UI first** (Metadata API limitation)
2. **All conversation variables need `<visibility>` attribute**
3. **Names must match exactly**: Bot = GenAiPlannerBundle = genAiPlannerName

## Deployment Commands

### Check if Component Exists
```bash
sf project retrieve start --metadata Bot:AgentName
sf project retrieve start --metadata GenAiPlannerBundle:AgentName
```

### Deploy Components
```bash
# Deploy GenAiPlannerBundle
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AgentName

# Deploy BotVersion (requires Bot to exist)
sf project deploy start --source-dir force-app/main/default/bots/AgentName
```

### Activate Agent
```bash
sf agent activate --api-name AgentName
```

## Common Errors & Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| "The field Agent Type is required" | Bot doesn't exist | Create Bot via UI first |
| "Variable visibility must be specified" | Missing visibility attribute | Add `<visibility>External</visibility>` or `<visibility>Internal</visibility>` |
| "Entity cannot be found" | Name mismatch | Check exact spelling and case |
| "genAiPlannerName mismatch" | Names don't match | Ensure Bot name = GenAiPlannerBundle name = genAiPlannerName |

## Deployment Order

1. Create Bot via UI (if needed)
2. Deploy GenAiPlannerBundle
3. Deploy BotVersion
4. Activate agent

## Required Metadata Fields

**Bot:**
- `<type>InternalCopilot</type>` or `<type>ExternalCopilot</type>`
- `botMlDomain.name` matches Bot API name

**BotVersion:**
- `<genAiPlannerName>AgentName</genAiPlannerName>` (must match GenAiPlannerBundle)
- All conversation variables need `<visibility>External</visibility>` or `<visibility>Internal</visibility>`

**GenAiPlannerBundle:**
- `<masterLabel>AgentName</masterLabel>` (must match Bot name)
- API version 64.0+

---

**For detailed information:** See [AGENTFORCE_DEPLOYMENT_GUIDE.md](./AGENTFORCE_DEPLOYMENT_GUIDE.md)

