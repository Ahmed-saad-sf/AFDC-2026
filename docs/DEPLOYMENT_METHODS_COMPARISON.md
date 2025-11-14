# Agentforce Deployment Methods Comparison

Comparison of different methods to deploy Agentforce agents.

## Summary

**Method Used in This Project:** ✅ **Metadata API via Salesforce CLI**

## Method Comparison

| Method | Used? | Pros | Cons | Best For |
|--------|-------|------|------|----------|
| **Metadata API (CLI)** | ✅ Yes | • Standard approach<br>• Version control friendly<br>• Well documented<br>• CI/CD integration | • Cannot create Bots<br>• Must use UI first | Standard deployments, CI/CD |
| **Python SDK** | ❌ No | • Can create Bots programmatically<br>• More flexible<br>• Automation friendly | • Requires Python setup<br>• Different workflow<br>• Less standard | Programmatic creation, automation |
| **Tooling API** | ❌ No | • Most flexible<br>• Direct API access<br>• Can query/update anything | • More complex<br>• Requires API knowledge<br>• Lower level | Custom integrations, advanced use |

## Detailed Comparison

### 1. Metadata API (via Salesforce CLI) ✅ **USED**

**Commands Used:**
```bash
# Deploy components
sf project deploy start --source-dir force-app/main/default/bots/AgentName
sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AgentName

# Retrieve components
sf project retrieve start --metadata Bot:AgentName
sf project retrieve start --metadata GenAiPlannerBundle:AgentName

# Activate agent
sf agent activate --api-name AgentName
```

**What We Learned:**
- ✅ Works well for GenAiPlannerBundle and BotVersion
- ❌ Cannot create new Bots (must use UI first)
- ✅ Standard approach, integrates with version control
- ✅ Good for CI/CD pipelines

**When to Use:**
- Standard deployments
- Version-controlled projects
- CI/CD pipelines
- When Bot already exists in org

---

### 2. Python SDK (agent-sdk) ❌ **NOT USED**

**Why We Didn't Use It:**
- Not installed in the environment
- Bot already existed in org (created via UI)
- Metadata API was sufficient for our needs

**How It Works:**
```python
from agent_sdk import Agentforce
from agent_sdk.core.auth import BasicAuth

auth = BasicAuth(username="user", password="pass")
client = Agentforce(auth=auth)

# Create agent programmatically
agent = AgentUtils.create_agent_from_modular_files(agent_dir, agent_name)
result = client.create(agent)
```

**Advantages:**
- ✅ Can create Bots programmatically (bypasses UI requirement)
- ✅ Can generate agents from descriptions
- ✅ More flexible for automation
- ✅ Can work with JSON/directory structures

**When to Use:**
- Need to create Bots programmatically
- Automation/scripting requirements
- Generating agents from descriptions
- Custom agent creation workflows

**See:** `agent-sdk/examples/` for examples

---

### 3. Tooling API ❌ **NOT USED**

**Why We Didn't Use It:**
- More complex than needed
- Metadata API was sufficient
- Requires direct API knowledge

**How It Works:**
```bash
# Query via Tooling API
sf data query --query "SELECT Id, DeveloperName FROM Bot WHERE DeveloperName = 'AgentName'"

# Or REST API
curl -X GET \
  https://instance.salesforce.com/services/data/v65.0/tooling/query/?q=SELECT+Id+FROM+Bot \
  -H "Authorization: Bearer TOKEN"
```

**Advantages:**
- ✅ Most flexible
- ✅ Direct API access
- ✅ Can query and update any component
- ✅ Real-time data access

**When to Use:**
- Custom integrations
- Advanced use cases
- Need direct API access
- Querying component status

**See:** [Tooling API Reference](./agentforce-references/agents-tooling.md)

---

## Recommendations

### For Standard Deployments
**Use: Metadata API via Salesforce CLI** ✅
- Most common approach
- Well-documented
- Version control friendly
- Just remember: Create Bot via UI first

### For Automation/Programmatic Creation
**Use: Python SDK (agent-sdk)**
- Can create Bots programmatically
- Better for automation
- More flexible workflows

### For Advanced/Custom Needs
**Use: Tooling API**
- Maximum flexibility
- Direct API access
- Custom integrations

---

## What We Actually Used

**Deployment Method:** Metadata API via Salesforce CLI

**Commands:**
- `sf project deploy start` - Deploy components
- `sf project retrieve start` - Retrieve/verify components
- `sf agent activate` - Activate agent version

**Workflow:**
1. Created Bot via UI (Metadata API limitation)
2. Deployed GenAiPlannerBundle via CLI
3. Deployed BotVersion via CLI
4. Activated agent via CLI

**Result:** ✅ Successful deployment

---

## Future Considerations

If you need to create Bots programmatically in the future:

1. **Install Python SDK:**
   ```bash
   pip install agentforce-sdk
   ```

2. **Use SDK to create Bot:**
   ```python
   from agent_sdk import Agentforce
   # Create agent programmatically
   ```

3. **Then deploy via Metadata API:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/bots/AgentName
   ```

This combines the best of both: SDK for Bot creation, Metadata API for standard deployment.

---

**For this project:** We used Metadata API via Salesforce CLI, which worked perfectly once the Bot was created via UI.

