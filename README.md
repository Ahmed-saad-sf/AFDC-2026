# AFDC-2026 - Salesforce Agentforce Project

This Salesforce project contains Agentforce agents and related components for meeting notes processing and AI-powered customer interactions.

## Project Overview

This project includes:
- **Agentforce Agents**: Multiple AI agents including the MAF Meeting Decision Assistant
- **Meeting Notes Processing**: Automated processing and analysis of meeting notes using LLM
- **GenAI Integration**: Prompt templates and functions for AI-powered workflows
- **Flows**: Automation flows for meeting notes processing and formatting

## Key Components

### Agentforce Agents
- **MAF_Meeting_Decision_Assistant**: Internal copilot for processing meeting notes and extracting insights
- **Agentforce_Sales_Coach**: Sales coaching agent
- **Agentforce_Sales_Development_Rep**: Sales development representative agent
- **Analytics_Agent**: Analytics-focused agent
- **Inbound_Sales_Agent**: Inbound sales handling agent
- **VoiceCRM**: Voice CRM agent

### Meeting Notes Processing
- **Process_Meeting_Notes** (GenAiFunction): Action to process and store meeting notes
- **MeetingNotesProcessor** (Flow): Main processing flow
- **MeetingNotes_Formatted** (Flow): Enhanced flow with formatting
- **Meeting_Notes_Analyzer** (GenAiPromptTemplate): LLM prompt for analyzing meeting conversations
- **UniversalAgentforceTableFormatter** (Apex): Utility class for formatting JSON responses as HTML/Markdown tables

### Custom Objects
- **Meeting_Note__c**: Custom object for storing processed meeting notes

## Project Structure

```
force-app/main/default/
├── bots/                          # Agentforce Bot definitions
├── genAiPlannerBundles/          # Planner bundles (API v65.0+)
├── genAiFunctions/               # Agent Actions
├── genAiPlugins/                 # Agent Topics
├── genAiPromptTemplates/         # LLM Prompt templates
├── flows/                        # Salesforce Flows
├── classes/                      # Apex classes
└── objects/                      # Custom objects
```

## API Version

- **Source API Version**: 65.0
- **GenAiPlannerBundle Support**: Enabled (requires API v64+)

## Setup Instructions

1. **Clone the repository**
   ```bash
   git clone <repository-url>
   cd AFDC-2026
   ```

2. **Authorize Salesforce Org**
   ```bash
   sf org login web --alias <alias>
   ```

3. **Deploy to Salesforce**
   ```bash
   sf project deploy start
   ```

## Documentation

- [Agentforce Metadata API Guide](./AGENTFORCE_METADATA_GUIDE.md) - Comprehensive guide on Agentforce metadata types and deployment

## Key Features

- ✅ Full Metadata API support for Agentforce components
- ✅ GenAiPlannerBundle support (API v65.0)
- ✅ Meeting notes processing with LLM
- ✅ Dynamic table formatting for AI responses
- ✅ Multiple Agentforce agents for different use cases

## Requirements

- Salesforce CLI (sf CLI)
- Salesforce org with Agentforce enabled
- API version 65.0 or higher

## License

[Add your license here]

