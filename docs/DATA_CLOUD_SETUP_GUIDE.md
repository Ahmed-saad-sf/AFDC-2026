# Data Cloud + Agent Configuration Guide

## Overview
This guide will help you configure your AF_Decision_Maker agent to access all Salesforce data through Data Cloud with Einstein Trust Layer security.

---

## Prerequisites

✅ **You have:** Data Cloud enabled in your org  
✅ **Required licenses:** Agentforce + Data Cloud  
✅ **Admin access:** Setup permissions needed

---

## Step 1: Configure Data Cloud Data Streams

### A. Enable Salesforce CRM Data Stream

1. Navigate to **Setup** → Search for "Data Cloud"
2. Click **Data Streams**
3. Click **New**
4. Select **Salesforce CRM**
5. Authenticate to your org
6. Select objects to sync:
   - ✅ Account
   - ✅ Contact
   - ✅ Opportunity
   - ✅ Case
   - ✅ Lead
   - ✅ Task
   - ✅ Event
   - ✅ Meeting_Note__c (custom object)
   - ✅ Any other custom objects you need

7. Configure sync settings:
   - **Sync Frequency:** Real-time (recommended) or Scheduled
   - **Field Selection:** All fields or specific fields
   
8. Click **Save & Activate**

### B. Wait for Initial Sync

⏱️ Initial sync can take 15-60 minutes depending on data volume.

Check sync status:
- Data Cloud → Data Streams → View your stream
- Look for "Active" status with green checkmark

---

## Step 2: Configure Data Spaces

### A. Create Agentforce Data Space

1. Navigate to **Data Cloud** → **Data Spaces**
2. Click **New Data Space**
3. Enter details:
   - **Name:** Agentforce Data Space
   - **Description:** Data accessible to Agentforce agents
   
4. **Add Data Models:**
   - Click **Add Data Model**
   - Select objects:
     - Account
     - Contact
     - Opportunity
     - Case
     - Lead
     - Custom objects (Meeting_Note__c, etc.)

5. **Configure Relationships:**
   - Data Cloud will auto-detect standard relationships
   - Verify: Account → Contacts, Account → Opportunities, etc.
   
6. Click **Save & Activate**

---

## Step 3: Enable Einstein Trust Layer

### A. Activate Trust Layer

1. Navigate to **Setup** → Search for "Einstein Trust Layer"
2. Click **Enable Einstein Trust Layer**
3. Review security settings:
   - ✅ Enforce object-level security
   - ✅ Enforce field-level security
   - ✅ Apply sharing rules
   - ✅ Enable PII masking

4. Click **Enable**

### B. Configure PII Detection (Optional)

1. Navigate to **Einstein Trust Layer** → **PII Settings**
2. Mark sensitive fields as PII:
   - Contact: Email, Phone, SSN, etc.
   - Custom fields containing personal data
   
3. Configure masking rules:
   - **Full Mask:** xxx-xx-1234
   - **Partial Mask:** j***@example.com
   - **No Mask:** For users with explicit permission

---

## Step 4: Configure Agent Actions in UI

Since Metadata API deployment is restricted, configure actions through the UI:

### A. Navigate to Agent Builder

1. Go to **Setup** → Search for "Agent"
2. Click **Agents**
3. Find your **AF_Decision_Maker** agent
4. Click **Edit**

### B. Add Data Operations Topic

1. In Agent Builder, click **Topics**
2. Click **+ New Topic**
3. Enter details:
   - **Name:** Data Operations
   - **Description:** Query and manage all Salesforce data
   
4. Click **Save**

### C. Add Search Action to Topic

1. Open the **Data Operations** topic
2. Click **Actions** tab
3. Click **+ New Action**
4. Select **Standard Action**
5. Choose one of these (depending on what's available in your org):
   - **Search Records** (if Data Cloud is fully configured)
   - **Einstein Search** (fallback option)
   - **Query Records** (alternative)

6. Configure action:
   - **Progress Message:** "Searching Salesforce data..."
   - **Requires Confirmation:** No
   
7. Click **Save**

### D. Add Topic Instructions

1. Still in the **Data Operations** topic
2. Click **Instructions** tab
3. Click **+ New Instruction**
4. Paste these instructions:

```
DATA CLOUD QUERY CAPABILITIES:

You have access to query ALL Salesforce data through Data Cloud with Einstein Trust Layer security.

IMPORTANT PRINCIPLES:
1. All queries respect user permissions automatically
2. Users can only see data they have access to
3. Field-level security is enforced
4. Sharing rules are applied automatically
5. Always confirm before making updates

QUERY EXAMPLES:

User: "Show me all accounts in California"
→ Query Accounts with BillingState = California

User: "What are the open opportunities over $100K?"
→ Query Opportunities with Amount > 100000 AND IsClosed = false

User: "Find contacts named John Smith"
→ Query Contacts with Name containing John Smith

RESPONSE FORMATTING:

1. For queries returning multiple records:
   • Format as a numbered list or table
   • Show key fields (Name, Amount, Status, etc.)
   • Limit to top 10-20 results unless user asks for more

2. For single record queries:
   • Show relevant fields clearly
   • Include related records if relevant
   • Provide record URL for navigation

3. For errors:
   • Explain clearly what went wrong
   • Suggest alternatives if permission denied
   • Ask clarifying questions if query is ambiguous
```

5. Click **Save**

### E. Set Topic Scope

1. In topic settings, set **Scope:**

```
My job is to help users query, read, update, and create Salesforce records across all objects they have access to. I use Data Cloud with Einstein Trust Layer to ensure secure, permission-aware data access.
```

2. Click **Save**

### F. Activate the Agent

1. Click **Activate** button
2. Confirm activation

---

## Step 5: Test the Configuration

### A. Test Basic Queries

Open the agent and try these queries:

**Test 1: Simple Query**
```
User: "Show me all accounts"
Expected: List of accounts user has access to
```

**Test 2: Filtered Query**
```
User: "Find opportunities closing this month"
Expected: List of opportunities with CloseDate in current month
```

**Test 3: Cross-Object Query**
```
User: "Show accounts with open cases"
Expected: Accounts that have related open cases
```

**Test 4: Permission Test**
```
User: "Show me all opportunities" (as user with limited access)
Expected: Only opportunities the user has access to (sharing rules applied)
```

### B. Verify Security

1. Test with different user profiles
2. Verify that users only see data they have permission for
3. Check that PII fields are masked for users without access

---

## Step 6: Monitor and Optimize

### A. Enable Debug Logs

1. Navigate to **Setup** → **Debug Logs**
2. Create trace flag for your user
3. Run queries and review logs

### B. Monitor Data Cloud Usage

1. Navigate to **Data Cloud** → **Analytics**
2. Review:
   - Query volume
   - Response times
   - Error rates

### C. Optimize Performance

If queries are slow:
- Add indexes to frequently queried fields
- Limit result sets (default: 20 records)
- Use specific filters instead of broad queries

---

## Troubleshooting

### Issue: "Action not available"

**Solution:**
1. Verify Data Cloud is fully activated
2. Check that Data Streams are syncing
3. Confirm Data Space is active
4. Try using **Einstein Search** action instead

### Issue: "No results found"

**Solution:**
1. Check user has permission to the object
2. Verify data exists in Data Cloud
3. Check Data Stream sync status
4. Review sharing rules

### Issue: "Permission denied"

**Solution:**
1. Verify user has object-level read permission
2. Check field-level security settings
3. Review sharing rules for the user
4. Confirm Einstein Trust Layer is enabled

### Issue: "PII data showing when it shouldn't"

**Solution:**
1. Navigate to Einstein Trust Layer → PII Settings
2. Mark the field as PII
3. Configure masking rules
4. Refresh the agent

---

## Advanced Configuration

### Enable Record Updates

To allow agents to update records:

1. In Agent Builder, add action: **Update Records**
2. Configure confirmation required: **Yes**
3. Add instructions for update workflow
4. Test with limited permissions first

### Enable Record Creation

To allow agents to create records:

1. In Agent Builder, add action: **Create Records**
2. Configure confirmation required: **Yes**
3. Add validation rules in instructions
4. Test thoroughly before production

### Add Custom Objects

To include custom objects:

1. Add to Data Stream (Step 1)
2. Add to Data Space (Step 2)
3. Wait for sync
4. Test queries

---

## Best Practices

### Security
- ✅ Always enable Einstein Trust Layer
- ✅ Configure PII masking for sensitive fields
- ✅ Test with different user profiles
- ✅ Review audit logs regularly
- ✅ Start with read-only access
- ✅ Add update/create permissions gradually

### Performance
- ✅ Limit result sets to 10-20 records by default
- ✅ Use specific filters instead of broad queries
- ✅ Enable real-time sync for critical objects
- ✅ Use scheduled sync for large historical data

### User Experience
- ✅ Provide clear error messages
- ✅ Ask clarifying questions for ambiguous queries
- ✅ Format results in tables or lists
- ✅ Include record links for easy navigation
- ✅ Confirm before making updates

---

## Success Checklist

Before going to production:

- [ ] Data Cloud fully activated and syncing
- [ ] All required objects added to Data Space
- [ ] Einstein Trust Layer enabled and configured
- [ ] PII fields marked and masking rules set
- [ ] Agent actions configured and tested
- [ ] Tested with multiple user profiles
- [ ] Verified security and permissions
- [ ] Reviewed audit logs
- [ ] User training completed
- [ ] Documentation updated

---

## Support

If you encounter issues:

1. **Check Salesforce Status:** status.salesforce.com
2. **Review Setup Audit Trail:** Setup → Setup Audit Trail
3. **Enable Debug Logs:** Setup → Debug Logs
4. **Contact Support:** Include the ErrorId from any error messages

---

## Next Steps

After configuration is complete:

1. ✅ Train users on new capabilities
2. ✅ Create example queries for common use cases
3. ✅ Monitor usage and performance
4. ✅ Add more objects as needed
5. ✅ Gather user feedback for improvements

---

**Congratulations! Your agent now has access to all Salesforce data through Data Cloud!** 🎉

