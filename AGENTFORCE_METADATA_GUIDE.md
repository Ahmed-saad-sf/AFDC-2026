# Agentforce Metadata API Guide

## Overview

Agentforce Agents and their related components can be deployed using the Salesforce Metadata API (which underpins tools like Salesforce CLI and DevOps solutions). Agentforce is built on the Einstein Bot and Generative AI framework, and Salesforce has introduced specific metadata types to facilitate the deployment of these AI features across various environments (Dev, QA, UAT, Production).

**Recommended API Version:** 65.0 (GenAiPlannerBundle requires API v64+)

---

## Metadata Type Hierarchy

### 1. **Bot** - The Agent Itself
**Metadata Type:** `Bot`

The top-level definition of the Agent. This includes key settings like:
- **Agent Type**: 
  - `ExternalCopilot` for Service Agents (customer-facing)
  - `InternalCopilot` for Employee Agents (internal use)
- Context variables (mappings to Salesforce objects)
- Session timeout settings
- Rich content and conversation logging preferences

**Example from codebase:**
```xml
<Bot xmlns="http://soap.sforce.com/2006/04/metadata">
    <type>InternalCopilot</type>
    <label>MAF_Meeting_Decision_Assistant</label>
    <logPrivateConversationData>true</logPrivateConversationData>
    <richContentEnabled>true</richContentEnabled>
    <sessionTimeout>0</sessionTimeout>
    <!-- Context variables for MessagingSession, VoiceCall, etc. -->
</Bot>
```

**Location:** `force-app/main/default/bots/{BotName}/{BotName}.bot-meta.xml`

---

### 2. **BotVersion** - Agent Configuration
**Metadata Type:** `BotVersion`

Represents a specific version of the Agent's configuration, including:
- Bot dialogs (welcome messages, error handling, transfers)
- Conversation variables
- **Connection to Planner Bundle** via `conversationDefinitionPlanners`
- Entry dialog configuration
- Tone and language settings

**Key Connection Point:**
```xml
<conversationDefinitionPlanners>
    <genAiPlannerName>MAF_Meeting_Decision_Assistant</genAiPlannerName>
</conversationDefinitionPlanners>
```

This links the BotVersion to the GenAiPlannerBundle that contains the Agent's core logic.

**Location:** `force-app/main/default/bots/{BotName}/v1.botVersion-meta.xml`

---

### 3. **GenAiPlannerBundle** - Agent Core Logic
**Metadata Type:** `GenAiPlannerBundle`

**⚠️ API Version Requirement:** API v64+ (previously called `GenAiPlanner`)

A crucial container that bundles all the Topics and Actions the Agent uses to plan and interact with the Large Language Model (LLM). This is the "brain" of the Agent that:
- Defines how the Agent plans its responses
- Organizes Topics (GenAiPlugin) and Actions (GenAiFunction)
- Coordinates the Agent's decision-making process

**Note:** This metadata type requires API v64+. The project has been updated to API v65.0, so GenAiPlannerBundle is now fully supported via Metadata API.

---

### 4. **GenAiPlugin** - Topics
**Metadata Type:** `GenAiPlugin`

Represents an Agent Topic, which is a category of actions the Agent can perform. Topics help organize related functionality and provide context to the LLM about when to use specific actions.

**Key Components:**
- `pluginType`: Set to `Topic`
- `scope`: Description of when this topic should be used
- `genAiPluginInstructions`: Step-by-step instructions for the LLM
- `genAiFunctions`: References to Actions (GenAiFunction) available in this topic

**Example from codebase:**
```xml
<GenAiPlugin xmlns="http://soap.sforce.com/2006/04/metadata">
    <pluginType>Topic</pluginType>
    <masterLabel>Product Inquiries and Qualification</masterLabel>
    <scope>Your job is to answer sales-related questions...</scope>
    <genAiFunctions>
        <functionName>EmployeeCopilot__AnswerQuestionsWithKnowledge</functionName>
    </genAiFunctions>
    <genAiPluginInstructions>
        <description>To handle sales-related questions, follow these instructions...</description>
    </genAiPluginInstructions>
</GenAiPlugin>
```

**Location:** `force-app/main/default/genAiPlugins/{PluginName}.genAiPlugin-meta.xml`

---

### 5. **GenAiFunction** - Actions
**Metadata Type:** `GenAiFunction`

Represents an Agent Action, which is the actual business logic the Agent invokes. Actions can:
- Call Salesforce Flows
- Invoke Apex methods
- Execute other business processes

**Key Components:**
- `invocationTarget`: Name of the Flow or Apex class
- `invocationTargetType`: `flow` or `apex`
- `isConfirmationRequired`: Whether user confirmation is needed
- Input/Output schemas (JSON Schema files)

**Example from codebase:**
```xml
<GenAiFunction xmlns="http://soap.sforce.com/2006/04/metadata">
    <masterLabel>Process Meeting Notes</masterLabel>
    <description>Use this action to process and store meeting notes...</description>
    <invocationTarget>MeetingNotesProcessor</invocationTarget>
    <invocationTargetType>flow</invocationTargetType>
    <isConfirmationRequired>false</isConfirmationRequired>
</GenAiFunction>
```

**Location:** `force-app/main/default/genAiFunctions/{FunctionName}/{FunctionName}.genAiFunction-meta.xml`

**Schema Files:**
- Input: `force-app/main/default/genAiFunctions/{FunctionName}/input/schema.json`
- Output: `force-app/main/default/genAiFunctions/{FunctionName}/output/schema.json`

**Schema Features:**
- JSON Schema format with `properties`, `required`, `unevaluatedProperties`
- Lightning-specific annotations: `lightning:type`, `lightning:isPII`
- Copilot-specific annotations: `copilotAction:isDisplayable`, `copilotAction:isUsedByPlanner`, `copilotAction:isUserInput`

---

### 6. **GenAiPromptTemplate** - Prompts
**Metadata Type:** `GenAiPromptTemplate`

The metadata for any custom prompt templates you define. These templates can be used by:
- GenAiFunctions (Actions)
- Flows (via `generatePromptResponse` action type)
- Direct LLM interactions

**Key Components:**
- `type`: Usually `einstein_gpt__flex`
- `visibility`: `Global` or `Internal`
- `templateVersions`: Contains the actual prompt content
  - `content`: The prompt template with placeholders
  - `inputs`: Input parameters (e.g., `{!$Input:rawMeetingNotes}`)
  - `primaryModel`: The LLM model to use
  - `status`: `Published` or `Draft`

**Example from codebase:**
```xml
<GenAiPromptTemplate xmlns="http://soap.sforce.com/2006/04/metadata">
    <developerName>Meeting_Notes_Analyzer</developerName>
    <masterLabel>Meeting Notes Analyzer</masterLabel>
    <type>einstein_gpt__flex</type>
    <visibility>Global</visibility>
    <templateVersions>
        <content>You are an expert meeting notes assistant...</content>
        <inputs>
            <apiName>Meeting_Conversation</apiName>
            <definition>primitive://String</definition>
            <required>true</required>
        </inputs>
        <primaryModel>sfdc_ai__DefaultBedrockAnthropicClaude4Sonnet</primaryModel>
        <status>Published</status>
    </templateVersions>
</GenAiPromptTemplate>
```

**Location:** `force-app/main/default/genAiPromptTemplates/{TemplateName}.genAiPromptTemplate-meta.xml`

---

## Component Relationships

```
Bot (Agent Definition)
  └── BotVersion (Configuration)
        └── conversationDefinitionPlanners
              └── GenAiPlannerBundle (Core Logic - API v64+)
                    ├── GenAiPlugin (Topic 1)
                    │     └── genAiFunctions
                    │           └── GenAiFunction (Action 1)
                    │                 ├── invocationTarget: Flow/Apex
                    │                 ├── input/schema.json
                    │                 └── output/schema.json
                    ├── GenAiPlugin (Topic 2)
                    │     └── genAiFunctions
                    │           └── GenAiFunction (Action 2)
                    └── ...
                          
GenAiPromptTemplate (Standalone, can be used by Flows or Functions)
```

---

## Deployment Commands

### Retrieve All Agentforce Components
```bash
# Retrieve Bot and BotVersion
sf project retrieve start --metadata Bot

# Retrieve GenAiPlugin (Topics)
sf project retrieve start --metadata GenAiPlugin

# Retrieve GenAiFunction (Actions)
sf project retrieve start --metadata GenAiFunction

# Retrieve GenAiPromptTemplate (Prompts)
sf project retrieve start --metadata GenAiPromptTemplate

# Retrieve GenAiPlannerBundle (requires API v64+)
sf project retrieve start --metadata GenAiPlannerBundle
```

### Retrieve Specific Components
```bash
# Retrieve specific Bot
sf project retrieve start --metadata Bot:MAF_Meeting_Decision_Assistant

# Retrieve specific Function
sf project retrieve start --metadata GenAiFunction:Process_Meeting_Notes

# Retrieve specific Prompt Template
sf project retrieve start --metadata GenAiPromptTemplate:Meeting_Notes_Analyzer
```

### Deploy Components
```bash
# Deploy all Agentforce components
sf project deploy start --source-dir force-app/main/default

# Deploy specific metadata type
sf project deploy start --metadata Bot,GenAiPlugin,GenAiFunction,GenAiPromptTemplate
```

---

## Best Practices

1. **API Version Management**
   - Use API v64+ for full GenAiPlannerBundle support
   - If using v60.0, GenAiPlannerBundle must be managed through UI

2. **Schema Design**
   - Use descriptive property names in JSON schemas
   - Leverage `copilotAction:isDisplayable` to control what users see
   - Use `copilotAction:isUsedByPlanner` to indicate planner-relevant outputs
   - Mark PII fields with `lightning:isPII: true`

3. **Function Organization**
   - Group related Actions under appropriate Topics (GenAiPlugin)
   - Provide clear descriptions for both Functions and Plugins
   - Use confirmation requirements for destructive actions

4. **Prompt Templates**
   - Keep prompts focused and specific
   - Use input placeholders consistently: `{!$Input:parameterName}`
   - Test with different models to find optimal performance
   - Version control prompt changes carefully

5. **Testing**
   - Test Actions independently before integrating into Topics
   - Validate JSON schemas match Flow/Apex inputs/outputs
   - Test prompt templates with various inputs
   - Verify context variable mappings in Bot configuration

---

## Common Use Cases in This Codebase

### Meeting Notes Processing
1. **Bot**: `MAF_Meeting_Decision_Assistant` (InternalCopilot)
2. **Function**: `Process_Meeting_Notes` → Calls `MeetingNotesProcessor` Flow
3. **Flow**: Uses `Meeting_Notes_Analyzer` GenAiPromptTemplate
4. **Output**: Creates `Meeting_Note__c` records with formatted insights

### Sales Inquiry Handling
1. **Plugin**: `sales_sdr_agent_SalesInquiryHandling` (Topic)
2. **Function**: `EmployeeCopilot__AnswerQuestionsWithKnowledge`
3. **Instructions**: Step-by-step guidance for handling sales questions

---

## References

- [Salesforce Metadata API Documentation](https://developer.salesforce.com/docs/atlas.en-us.api_meta.meta/api_meta/)
- [Metadata Coverage Report](https://developer.salesforce.com/docs/metadata-coverage)
- [Agentforce Documentation](https://help.salesforce.com/)

---

## Notes

- GenAiPlannerBundle was introduced in API v64 (previously GenAiPlanner)
- ConversationChannelDefinition and ConversationMessageDefinition are related but separate metadata types
- BotVersion references the planner bundle by name, not by direct metadata reference
- Functions can invoke Flows or Apex classes with `@InvocableMethod` annotation

