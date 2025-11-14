# Agentforce Metadata Types

Source: https://developer.salesforce.com/docs/einstein/genai/references/agents-metadata-tooling/agents-metadata.html

Manage actions and customize the planner service using the Metadata API.

## Agent Metadata Hierarchy

### Bot
The top-level representation of an Einstein Bot or an Agentforce Agent.

- `localMlDomain.name`: Agent name
- `type`: Agent type
- `description`: Agent description
- `ConversationContextVariable`: A context variable local to the current bot or agent version

### BotVersion
A BotVersion represents the configuration for a specific bot or agent version. A single Einstein Bot or Agentforce Agent can have many versions, but only one version can be active.

- `ConversationVariable`: A container that stores a specific piece of data collected from the customer. You can use variables within actions as both inputs and outputs.

### GenAiPlannerBundle
Represents a planner for an agent or agent template. It's a container for all the topics and actions used to interact with a large language model (LLM). An agent has a single GenAiPlannerBundle component. A `GenAIPlannerBundle` file contains the Agentforce Builder Agent-Topic Map for a specific agent.

- `GenAiPluginInstructionDef`: Topic instructions

### GenAiPlugin
Represents an agent topic, which is a category of actions related to a particular job to be done by the agent. An agent can have multiple GenAiPlugin components.

- `developerName`: Topic API name

### GenAiFunction
Represents an action that can be added to agents. Action input and output variables are located in `schema.json` for each action's input and output folders, or in `schema.json` in the `localActions` folder of `genAIPlannerBundle`.

