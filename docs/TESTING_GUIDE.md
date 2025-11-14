# Step-by-Step Testing Guide for LWC Component Solution

## ✅ Deployment Status

All components have been successfully deployed:
- ✅ LWC Component: `meetingNotesDisplay`
- ✅ Apex Class: `UniversalAgentforceTableFormatter`
- ✅ Flow: `MeetingNotes_Formatted`
- ✅ Schema: Updated output schema

---

## 🧪 Testing Steps

### **Test 1: Verify Markdown Output in Agentforce Conversation**

#### Step 1.1: Open Agentforce
1. Log in to your Salesforce org
2. Navigate to **Setup** → Search for "Agentforce" → Click **Agentforce**
3. Click on **Agents** in the left sidebar
4. Find and click on **AF_Decision_Maker** agent

#### Step 1.2: Start a Conversation
1. Click **Preview** or **Test** button (usually in the top right)
2. This opens the Agentforce conversation interface

#### Step 1.3: Test Meeting Notes Processing
1. Type a message like:
   ```
   I need to process meeting notes from today's team meeting. 
   Here are the notes:
   
   Meeting: Q4 Planning Session
   Date: Today
   Participants: John, Sarah, Mike
   
   Key Decisions:
   - Approved budget increase of 15%
   - New product launch scheduled for March
   - Marketing campaign to start next week
   
   Action Items:
   - John: Finalize budget proposal by Friday
   - Sarah: Prepare product launch timeline
   - Mike: Create marketing campaign brief
   
   Topics Discussed:
   - Budget planning
   - Product roadmap
   - Marketing strategy
   ```

#### Step 1.4: Verify Response Format
**Expected Result:**
- ✅ The response should be in **Markdown format** (not HTML)
- ✅ You should see formatted text with:
  - Headers (##)
  - Bullet points (-)
  - Tables (if applicable)
  - Emojis/icons (✅, 📋, etc.)
- ✅ **NO HTML tags** should be visible (like `<div>`, `<table>`, etc.)
- ✅ The response should be readable and well-formatted

**What to Look For:**
```
✅ Analysis Complete

## 📋 Key Action Items

| Who | What | When |
|-----|------|------|
| John | Finalize budget proposal | Friday |
| Sarah | Prepare product launch timeline | ... |
...
```

---

### **Test 2: Verify Flow Output Variables**

#### Step 2.1: Check Flow Variables
1. Navigate to **Setup** → **Flows**
2. Find and open **MeetingNotes-Formatted** flow
3. Review the flow structure:
   - Should have `processingStatus` output variable
   - Should have `componentData` output variable
   - Should have `componentName` output variable

#### Step 2.2: Verify Apex Action Configuration
1. In the flow, find the **Format_JSON_Response_with_Dynamic_Tables_Action** action
2. Check the input parameters:
   - `outputFormat` should be set to `"markdown"` (hardcoded string)
3. Check the output parameters:
   - `formattedOutput` → assigned to `processingStatus`
   - `componentData` → assigned to `componentData`
   - `componentName` → assigned to `componentName`

---

### **Test 3: Test LWC Component on Record Page (Optional)**

#### Step 3.1: Create a Test Meeting Note Record
1. Navigate to **Meeting Notes** tab (or search for "Meeting Note" in App Launcher)
2. Click **New**
3. Fill in:
   - **Name**: "Test Meeting - Q4 Planning"
   - **Conversation Text**: Use the same meeting notes from Test 1
4. Click **Save**

#### Step 3.2: Add LWC Component to Record Page
1. Go to the Meeting Note record you just created
2. Click the **⚙️ Gear Icon** (top right) → **Edit Page**
3. This opens Lightning App Builder
4. In the left sidebar, find **Custom** section
5. Drag **meetingNotesDisplay** component onto the page
6. Click on the component to configure:
   - **Meeting Data**: 
     ```json
     {
       "keyActionItems": [
         {"who": "John", "what": "Finalize budget", "when": "Friday"}
       ],
       "decisionsMade": ["Approved budget increase", "New product launch"],
       "topicsDiscussed": ["Budget planning", "Product roadmap"]
     }
     ```
   - **Record ID**: `{!Meeting_Note__c.Id}`
   - **Title**: "Meeting Notes Analysis"
7. Click **Save** (top right)
8. Click **Activate** → **Assign as Org Default** or **Assign to App/Profile**

#### Step 3.3: Verify Component Display
1. Navigate back to the Meeting Note record
2. **Expected Result:**
   - ✅ Component displays in a Lightning Card
   - ✅ Shows formatted sections with icons
   - ✅ Tables render correctly (if data includes arrays of objects)
   - ✅ Lists display as bullet points
   - ✅ Record link appears at the bottom

---

### **Test 4: Verify Apex Class Output**

#### Step 4.1: Test Apex Method via Developer Console
1. Open **Developer Console** (Setup → Developer Console)
2. Go to **Debug** → **Open Execute Anonymous Window**
3. Run this code:
   ```apex
   // Test data
   String jsonResponse = '{"keyActionItems":[{"who":"John","what":"Task","when":"Friday"}],"decisionsMade":["Decision 1"]}';
   String recordId = 'a0X000000000000'; // Use a real Meeting Note ID
   
   // Create request
   UniversalAgentforceTableFormatter.Request req = 
       new UniversalAgentforceTableFormatter.Request();
   req.jsonResponse = jsonResponse;
   req.recordId = recordId;
   req.outputFormat = 'markdown';
   
   // Execute
   List<UniversalAgentforceTableFormatter.Response> responses = 
       UniversalAgentforceTableFormatter.formatResponse(new List<UniversalAgentforceTableFormatter.Request>{req});
   
   // Check results
   System.debug('Formatted Output: ' + responses[0].formattedOutput);
   System.debug('Component Data: ' + responses[0].componentData);
   System.debug('Component Name: ' + responses[0].componentName);
   System.debug('Success: ' + responses[0].success);
   ```

4. Check the **Debug Log**:
   - ✅ `formattedOutput` should contain Markdown (not HTML)
   - ✅ `componentData` should contain JSON string
   - ✅ `componentName` should be `"c:meetingNotesDisplay"`
   - ✅ `success` should be `true`

---

### **Test 5: End-to-End Agentforce Test**

#### Step 5.1: Complete Conversation Flow
1. Open Agentforce conversation (as in Test 1)
2. Start with: "I need to process meeting notes"
3. Provide meeting notes when prompted
4. Wait for the agent to process

#### Step 5.2: Verify Complete Response
**Expected Results:**
- ✅ Agent responds with formatted Markdown
- ✅ Response includes:
  - Meeting analysis summary
  - Key sections (Action Items, Decisions, Topics, etc.)
  - Record link to created Meeting Note
- ✅ **NO HTML tags** visible
- ✅ Formatting is clean and readable

#### Step 5.3: Check Created Record
1. Click the record link in the agent's response (if provided)
2. Or navigate to **Meeting Notes** tab
3. Find the newly created record
4. Verify:
   - ✅ Record was created successfully
   - ✅ **Processed Notes** field contains the formatted response
   - ✅ All fields are populated correctly

---

## 🔍 Troubleshooting

### Issue: Still seeing HTML in response
**Solution:**
1. Verify Flow is using the updated version
2. Check that `outputFormat` is set to `"markdown"` (not a variable)
3. Redeploy the Flow:
   ```bash
   sf project deploy start --source-dir force-app/main/default/flows/MeetingNotes_Formatted.flow-meta.xml
   ```

### Issue: Component not appearing on record page
**Solution:**
1. Verify component is exposed in `js-meta.xml`
2. Check that you're using the correct API name: `c-meeting-notes-display`
3. Ensure the page is activated and assigned to your profile/app

### Issue: Tables not rendering correctly
**Solution:**
1. Check JSON structure - tables require arrays of objects
2. Verify component is receiving valid JSON
3. Check browser console for JavaScript errors

### Issue: Flow error during execution
**Solution:**
1. Check Flow debug logs
2. Verify Apex class is deployed
3. Ensure all required fields are provided

---

## ✅ Success Criteria

All tests pass if:
- ✅ Agentforce conversation returns Markdown (not HTML)
- ✅ Response is readable and well-formatted
- ✅ Meeting Note records are created successfully
- ✅ LWC component displays correctly (if tested)
- ✅ No errors in debug logs

---

## 📝 Notes

- **Markdown is the primary output** for Agentforce conversations
- **LWC component** is available for record pages and future use
- **Component data** is prepared for potential future Agentforce LWC support
- All components are backward compatible

---

## 🚀 Next Steps

After successful testing:
1. Monitor agent conversations for any issues
2. Gather user feedback on formatting
3. Consider adding the LWC component to Meeting Note record pages
4. Document any customizations needed for your use case

