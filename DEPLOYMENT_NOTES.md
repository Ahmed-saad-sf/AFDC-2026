# MAF_Decision_Maker Deployment Notes

> **📚 For future deployments, see:** [AGENTFORCE_DEPLOYMENT_GUIDE.md](./docs/AGENTFORCE_DEPLOYMENT_GUIDE.md) - Comprehensive deployment guide with best practices and requirements.

## Status
✅ **DEPLOYMENT SUCCESSFUL** - All components deployed successfully after resolving Bot creation requirement.

## Created Components
- ✅ Bot: `MAF_Decision_Maker.bot-meta.xml`
- ✅ BotVersion: `v1.botVersion-meta.xml`
- ✅ GenAiPlannerBundle: `MAF_Decision_Maker.genAiPlannerBundle` (✅ **DEPLOYED SUCCESSFULLY**)
- ✅ All schema files for actions and topics

## Deployment Issue
The Bot deployment is failing with: **"The field Agent Type is required when creating an agent"**

**Root Cause**: This is a known Salesforce Metadata API limitation. The Metadata API does **not support creating new Bots**. Bots must be created through the Salesforce UI first, then the BotVersion and other components can be deployed via Metadata API.

The `<type>InternalCopilot</type>` field is correctly present in the metadata file, but Salesforce requires the Bot container to exist before it can accept BotVersion deployments.

## Required Workaround: Create Bot via UI First

**The GenAiPlannerBundle is already deployed successfully.** To complete the deployment:

### Step 1: Create Bot via Salesforce UI
1. Log into your Salesforce org
2. Navigate to **Setup** → **Agentforce** → **Agents**
3. Click **New Agent** or **Create Agent**
4. Create a new Agent with:
   - **Name**: `MAF_Decision_Maker`
   - **Type**: `Internal Copilot`
   - **Description**: "Conversational AI agent that captures meeting notes, extracts decisions, validates records, and provides intelligent recommendations"
5. Save the agent (you can leave it with default settings for now)

### Step 2: Deploy BotVersion and Update Bot
After creating the Bot via UI, deploy the BotVersion:
```bash
sf project deploy start --source-dir force-app/main/default/bots/MAF_Decision_Maker
```

This will deploy:
- The BotVersion (`v1.botVersion-meta.xml`) which links to the GenAiPlannerBundle
- Update the Bot metadata with context variables and other settings

### Step 3: Verify Deployment
```bash
sf project retrieve start --metadata Bot:MAF_Decision_Maker
```

### Alternative: Use Agent SDK (Future)
The `agent-sdk` Python library can programmatically create agents, but requires:
- Python environment setup
- Installing `agentforce-sdk` package
- Converting metadata to SDK format

For now, the UI approach is the most straightforward solution.

## Files Created
All files are in:
- `force-app/main/default/bots/MAF_Decision_Maker/`
- `force-app/main/default/genAiPlannerBundles/MAF_Decision_Maker/`

---

# Key CLI Commands for Agentforce Deployment

## Basic Retrieve Command

```bash
sf project retrieve start --metadata Agent:<AgentName>
```

## Validate Before Deployment

```bash
sf project deploy start --dry-run -x manifest/package.xml -o your-target-org --json
```

## Deploy with Quick Deploy (after validation)

Once validated successfully, you can use the JobId for quick deployment.

## Important Metadata Types for Agentforce

The key metadata components you'll need to deploy include:

- **GenAiPlannerBundle**: Agent definition (Winter '26+)
- **GenAiPlanner**: Core agent (older versions)
- **GenAiFunction**: Agent actions and custom functions
- **GenAiPlugin**: Agent topics and instructions
- **PermissionSet**: Required permissions
- **ApexClass**: Custom Apex classes for actions
- **Flow**: Custom flows for actions
- **ConnectedApp**: For integrations

## Important Version Considerations

**Critical update for Winter '26**: There have been significant changes to Agentforce metadata structure!

- **Agent Bundle Metadata**: Now includes the agent, topics (with instructions), and actions all in one single file
- **API Version Compatibility**: If source is Winter '26, destination cannot be Summer '25
- **Global vs Local Components**: You typically don't need to deploy plugin/function metadata components since those are global topics/actions rather than local ones

## Deployment Best Practices

1. **Include Dependencies**: When deploying Agentforce metadata, you must include any components the Agent depends on, or the deployment will fail validation. These often include:
   - Flows (Flow metadata type)
   - Apex Classes (ApexClass metadata type)
   - Lightning Web Components (LWCs) (LightningComponentBundle metadata type)

2. **Activation is Separate**: Deployment doesn't automatically activate the Agent. You must use a separate command or process to make the new version live:
   ```bash
   sf agent activate
   ```

3. **Deployment Workflow**:
   - Retrieve: Use `sf project retrieve start` with a package.xml file that lists the metadata types
   - Deploy: Use `sf project deploy start` to push the retrieved files to the target org
   - Activate: Use `sf agent activate` to make the agent live
