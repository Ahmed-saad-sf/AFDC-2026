# Agentforce Deployment Guide - Best Practices & Requirements

This guide documents the deployment steps, requirements, and lessons learned from deploying Agentforce agents to avoid repeated trial-and-error in future projects.

## Deployment Method Used

**This guide uses the Metadata API via Salesforce CLI** (`sf project deploy start`).

### Available Deployment Methods:

1. **Metadata API (via Salesforce CLI)** ✅ **Used in this guide**
   - Command: `sf project deploy start`
   - Pros: Standard, well-documented, works with version control
   - Cons: Cannot create Bots (must use UI first)
   - Best for: Standard deployments, CI/CD pipelines

2. **Python SDK (agent-sdk)**
   - Library: `agentforce-sdk`
   - Pros: Can programmatically create agents, more flexible
   - Cons: Requires Python setup, different workflow
   - Best for: Programmatic agent creation, automation

3. **Tooling API**
   - Direct API calls to Salesforce
   - Pros: Most flexible, can create/update any component
   - Cons: More complex, requires API knowledge
   - Best for: Custom integrations, advanced use cases

**Note:** We did NOT use Python SDK or Tooling API - all deployments were done via Metadata API through Salesforce CLI.

## Table of Contents
1. [Critical Requirements](#critical-requirements)
2. [Deployment Order](#deployment-order)
3. [Metadata Structure Requirements](#metadata-structure-requirements)
4. [Common Issues & Solutions](#common-issues--solutions)
5. [Step-by-Step Deployment Process](#step-by-step-deployment-process)
6. [Verification Steps](#verification-steps)

---

## Critical Requirements

### 1. Bot Creation Limitation
**⚠️ CRITICAL**: The Salesforce Metadata API **does NOT support creating new Bots**. 

- **Bots MUST be created via Salesforce UI first** before deploying BotVersion or other components
- Attempting to create a Bot via Metadata API will fail with: `"The field Agent Type is required when creating an agent"`
- This is a known Salesforce limitation, not a configuration issue

### 2. Naming Consistency
- **Bot name** and **GenAiPlannerBundle name** must match exactly
- BotVersion references the GenAiPlannerBundle via `<genAiPlannerName>` - names must align
- Check existing components in org before deployment to avoid naming conflicts

### 3. Required Fields
- **BotVersion conversation variables** require `<visibility>` attribute (External or Internal)
- **Bot** requires `<type>` field (InternalCopilot or ExternalCopilot)
- **BotVersion** requires `<genAiPlannerName>` to link to GenAiPlannerBundle

---

## Deployment Order

### Correct Sequence:
1. ✅ **Create Bot via UI** (if it doesn't exist)
2. ✅ **Deploy GenAiPlannerBundle** (can be deployed independently)
3. ✅ **Deploy BotVersion** (requires Bot to exist)
4. ✅ **Update Bot metadata** (context variables, settings)

### Why This Order Matters:
- GenAiPlannerBundle can be deployed independently
- BotVersion requires the Bot container to exist first
- Bot metadata updates can be deployed after Bot exists

---

## Metadata Structure Requirements

### Bot Metadata (`Bot.bot-meta.xml`)
```xml
<Bot xmlns="http://soap.sforce.com/2006/04/metadata">
    <botMlDomain>
        <label>AgentName</label>
        <name>AgentName</name>
    </botMlDomain>
    <type>InternalCopilot</type>  <!-- Required: InternalCopilot or ExternalCopilot -->
    <description>Agent description</description>
    <logPrivateConversationData>true</logPrivateConversationData>
    <richContentEnabled>true</richContentEnabled>
    <sessionTimeout>0</sessionTimeout>
    <!-- Context variables -->
</Bot>
```

**Key Points:**
- `<type>` field is required and must be one of: `InternalCopilot`, `ExternalCopilot`
- `botMlDomain.name` must match the Bot's API name
- Context variables are optional but commonly used

### BotVersion Metadata (`v1.botVersion-meta.xml`)
```xml
<BotVersion xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>v1</fullName>
    <conversationDefinitionPlanners>
        <genAiPlannerName>AgentName</genAiPlannerName>  <!-- Must match GenAiPlannerBundle name -->
    </conversationDefinitionPlanners>
    <conversationVariables>
        <dataType>Text</dataType>
        <developerName>VariableName</developerName>
        <label>Variable Label</label>
        <visibility>External</visibility>  <!-- REQUIRED: External or Internal -->
    </conversationVariables>
    <entryDialog>Welcome</entryDialog>
    <toneType>Casual</toneType>
    <!-- Bot dialogs, etc. -->
</BotVersion>
```

**Key Points:**
- `<genAiPlannerName>` must exactly match the GenAiPlannerBundle `masterLabel`
- **ALL conversation variables MUST have `<visibility>` attribute**
- Visibility values: `External` (visible to end users) or `Internal` (system only)

### GenAiPlannerBundle Metadata
```xml
<GenAiPlannerBundle xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>AgentName</masterLabel>  <!-- Must match Bot name and genAiPlannerName -->
    <description>Agent description</description>
    <plannerType>AiCopilot__ReAct</plannerType>
    <plannerSurfaces>
        <surfaceType>Messaging</surfaceType>
        <!-- Surface configurations -->
    </plannerSurfaces>
</GenAiPlannerBundle>
```

**Key Points:**
- `masterLabel` must match Bot name and BotVersion's `genAiPlannerName`
- Can be deployed independently of Bot/BotVersion
- Requires API version 64.0 or higher

---

## Common Issues & Solutions

### Issue 1: "The field Agent Type is required when creating an agent"
**Cause**: Attempting to create a new Bot via Metadata API  
**Solution**: 
- Create the Bot via Salesforce UI first (Setup → Agentforce → Agents)
- Then deploy BotVersion and other components

### Issue 2: "Variable visibility must be specified"
**Cause**: Conversation variables missing `<visibility>` attribute  
**Solution**: Add `<visibility>External</visibility>` or `<visibility>Internal</visibility>` to all conversation variables

### Issue 3: "Entity of type 'Bot' named 'X' cannot be found"
**Cause**: Bot doesn't exist in org or name mismatch  
**Solution**: 
- Verify Bot exists: `sf project retrieve start --metadata Bot:BotName`
- Check exact name spelling (case-sensitive)
- Create Bot via UI if it doesn't exist

### Issue 4: GenAiPlannerBundle name mismatch
**Cause**: BotVersion references a GenAiPlannerBundle that doesn't match  
**Solution**: 
- Verify GenAiPlannerBundle exists: `sf project retrieve start --metadata GenAiPlannerBundle:BundleName`
- Ensure `<genAiPlannerName>` in BotVersion matches `masterLabel` in GenAiPlannerBundle exactly

### Issue 5: Deployment succeeds but agent doesn't work
**Cause**: BotVersion not activated  
**Solution**: Activate the agent version: `sf agent activate --api-name AgentName`

---

## Step-by-Step Deployment Process

### Pre-Deployment Checklist
- [ ] Verify Bot exists in org (or create via UI)
- [ ] Verify GenAiPlannerBundle name matches Bot name
- [ ] Check all conversation variables have visibility attribute
- [ ] Verify BotVersion references correct GenAiPlannerBundle name
- [ ] Ensure API version is 64.0+ (for GenAiPlannerBundle)

### Step 1: Verify/Create Bot
```bash
# Check if Bot exists
sf project retrieve start --metadata Bot:AgentName

# If not found, create via UI:
# Setup → Agentforce → Agents → New Agent
# - Name: AgentName
# - Type: Internal Copilot (or External Copilot)
# - Save with default settings
```

### Step 2: Deploy GenAiPlannerBundle
```bash
# Deploy GenAiPlannerBundle (can be done independently)
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AgentName

# Verify deployment
sf project retrieve start --metadata GenAiPlannerBundle:AgentName
```

### Step 3: Verify BotVersion Configuration
Before deploying, verify:
- `<genAiPlannerName>` matches GenAiPlannerBundle `masterLabel`
- All conversation variables have `<visibility>` attribute
- Bot dialogs are properly configured

### Step 4: Deploy BotVersion
```bash
# Deploy BotVersion (requires Bot to exist)
sf project deploy start --source-dir force-app/main/default/bots/AgentName

# This will deploy:
# - BotVersion (v1.botVersion-meta.xml)
# - Bot metadata updates (AgentName.bot-meta.xml)
```

### Step 5: Verify Deployment
```bash
# Retrieve to verify all components
sf project retrieve start --metadata Bot:AgentName

# Check deployment status
sf project deploy report --job-id <deployment-id>
```

### Step 6: Activate Agent (if needed)
```bash
# Activate the agent version
sf agent activate --api-name AgentName

# Or activate via UI:
# Setup → Agentforce → Agents → Select Agent → Activate Version
```

---

## Verification Steps

### 1. Verify Bot Exists
```bash
sf project retrieve start --metadata Bot:AgentName --json | grep -i "success\|error"
```

### 2. Verify GenAiPlannerBundle Exists
```bash
sf project retrieve start --metadata GenAiPlannerBundle:AgentName --json | grep -i "success\|error"
```

### 3. Verify BotVersion Links Correctly
- Retrieve BotVersion and check `<genAiPlannerName>` matches GenAiPlannerBundle name
- Verify all conversation variables have visibility

### 4. Test in UI
- Navigate to Setup → Agentforce → Agents
- Open the agent and verify configuration
- Test agent in preview mode

---

## Quick Reference Commands

### Check Component Existence
```bash
# Check Bot
sf project retrieve start --metadata Bot:AgentName

# Check GenAiPlannerBundle
sf project retrieve start --metadata GenAiPlannerBundle:AgentName

# Check BotVersion
sf project retrieve start --metadata BotVersion:AgentName.v1
```

### Deploy Components
```bash
# Deploy GenAiPlannerBundle only
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AgentName

# Deploy Bot and BotVersion
sf project deploy start --source-dir force-app/main/default/bots/AgentName

# Deploy both together
sf project deploy start \
  --source-dir force-app/main/default/genAiPlannerBundles/AgentName \
  --source-dir force-app/main/default/bots/AgentName
```

### Validate Before Deploying
```bash
# Dry-run deployment
sf project deploy start --dry-run --source-dir force-app/main/default/bots/AgentName
```

### Activate Agent
```bash
sf agent activate --api-name AgentName
```

---

## Best Practices

1. **Always verify component existence before deployment**
   - Use `sf project retrieve start` to check if components exist
   - Avoids confusion about naming mismatches

2. **Deploy GenAiPlannerBundle first**
   - Can be deployed independently
   - Helps identify naming issues early

3. **Use consistent naming**
   - Bot name = GenAiPlannerBundle masterLabel = genAiPlannerName
   - Use the same name across all components

4. **Validate metadata structure**
   - Check all required fields are present
   - Verify conversation variables have visibility
   - Ensure type fields are correct

5. **Test incrementally**
   - Deploy GenAiPlannerBundle first and verify
   - Then deploy BotVersion and verify
   - Test in UI before considering deployment complete

6. **Document component IDs**
   - Keep track of deployed component IDs for reference
   - Helps with troubleshooting and verification

---

## Lessons Learned

### From AF_Decision_Maker Deployment:

1. **Bot must exist before BotVersion deployment**
   - Created Bot via UI as `AF_Decision_Maker`
   - Then successfully deployed BotVersion

2. **Naming consistency is critical**
   - Bot: `AF_Decision_Maker`
   - GenAiPlannerBundle: `AF_Decision_Maker`
   - BotVersion genAiPlannerName: `AF_Decision_Maker`
   - All must match exactly

3. **Conversation variables require visibility**
   - Error: "Variable visibility must be specified"
   - Solution: Added `<visibility>External</visibility>` or `<visibility>Internal</visibility>`

4. **GenAiPlannerBundle can be deployed independently**
   - Deployed successfully before Bot existed
   - Useful for testing and validation

5. **Metadata API limitations**
   - Cannot create Bots via Metadata API
   - Must use UI for initial Bot creation
   - BotVersion and updates can be deployed via API

---

## Alternative Deployment Methods

### Using Python SDK (agent-sdk)

If you want to use the Python SDK instead of Metadata API:

```bash
# Install the SDK
pip install agentforce-sdk

# Use Python to create agents programmatically
from agent_sdk import Agentforce
from agent_sdk.core.auth import BasicAuth

auth = BasicAuth(username="your_username", password="your_password")
client = Agentforce(auth=auth)

# Create agent from JSON or directory structure
agent = AgentUtils.create_agent_from_modular_files(agent_directory, agent_name)
result = client.create(agent)
```

**Advantages:**
- Can create Bots programmatically (bypasses UI requirement)
- More flexible for automation
- Can generate agents from descriptions

**See:** `agent-sdk/examples/` directory for examples

### Using Tooling API

For direct API access:

```bash
# Use Salesforce CLI with Tooling API
sf data query --query "SELECT Id, DeveloperName FROM Bot WHERE DeveloperName = 'AgentName'"

# Or use REST API directly
curl -X GET \
  https://your-instance.salesforce.com/services/data/v65.0/tooling/query/?q=SELECT+Id+FROM+Bot \
  -H "Authorization: Bearer YOUR_ACCESS_TOKEN"
```

**Advantages:**
- Most flexible
- Can query and update any component
- Direct API access

**See:** [Agentforce Tooling Objects Reference](./agentforce-references/agents-tooling.md)

## Related Documentation

- [Agentforce Metadata Guide](../AGENTFORCE_METADATA_GUIDE.md)
- [Agentforce Reference Documentation](./agentforce-references/README.md)
- [Salesforce Agentforce Metadata Types](https://developer.salesforce.com/docs/einstein/genai/references/agents-metadata-tooling/agents-metadata.html)
- [Salesforce Agentforce Tooling API](https://developer.salesforce.com/docs/einstein/genai/references/agents-metadata-tooling/agents-tooling.html)

---

## Summary

**Key Takeaways:**
1. ✅ Create Bot via UI first (Metadata API limitation)
2. ✅ Deploy GenAiPlannerBundle independently
3. ✅ Deploy BotVersion after Bot exists
4. ✅ Ensure all conversation variables have visibility
5. ✅ Verify naming consistency across all components
6. ✅ Test incrementally and verify each step

Following this guide will prevent repeated trial-and-error deployments and ensure successful Agentforce agent deployments.

