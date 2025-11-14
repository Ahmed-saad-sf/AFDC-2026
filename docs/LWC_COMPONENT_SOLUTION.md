# LWC Component Solution for Agentforce Meeting Notes

## Overview

This solution creates a Lightning Web Component (LWC) to render formatted meeting notes in Agentforce conversations, replacing HTML output with a native Salesforce component.

## Solution Architecture

### 1. **LWC Component: `meetingNotesDisplay`**

**Location:** `force-app/main/default/lwc/meetingNotesDisplay/`

**Features:**
- Parses JSON meeting data automatically
- Renders tables, lists, and text sections
- Displays icons for different data types
- Includes record link to Meeting Note
- Responsive design using Salesforce Lightning Design System (SLDS)

**Component Properties:**
- `meetingData` (String): JSON string containing meeting notes data
- `recordId` (String): ID of the Meeting Note record
- `title` (String): Title for the card (default: "Meeting Notes Analysis")

### 2. **Updated Apex Class: `UniversalAgentforceTableFormatter`**

**Changes:**
- Added `componentData` output: JSON string with component properties
- Added `componentName` output: LWC component name (`c:meetingNotesDisplay`)
- Now returns Markdown format by default (Agentforce-compatible)
- Maintains backward compatibility with HTML and plain text outputs

### 3. **Updated Flow: `MeetingNotes_Formatted`**

**Changes:**
- Set `outputFormat` to `'markdown'` (hardcoded)
- Added `componentData` output variable
- Added `componentName` output variable
- Flow now returns:
  - `processingStatus`: Markdown-formatted response (Agentforce can render this)
  - `componentData`: JSON data for LWC component
  - `componentName`: Component reference

### 4. **Updated Output Schema**

**Location:** `force-app/main/default/genAiPlannerBundles/AF_Decision_Maker/localActions/Meeting_Notes_Processing_16jKB000000L7Mn/MeetingNotes_Formatted_179KB000000DjEC/output/schema.json`

**New Properties:**
- `componentData`: JSON data for LWC component rendering
- `componentName`: Lightning Web Component name for rendering

## How It Works

### Current Implementation (Markdown)

The Flow now returns **Markdown** format in `processingStatus`, which Agentforce can render natively. This solves the HTML rendering issue.

### LWC Component Usage

The LWC component is available for use in:
1. **Record Pages**: Add to Meeting Note record pages
2. **Lightning Pages**: Use in App Builder
3. **Future Agentforce Integration**: When Agentforce supports LWC rendering

### Component Data Structure

The `componentData` JSON structure:
```json
{
  "meetingData": "{...JSON meeting data...}",
  "recordId": "a0X...",
  "title": "Meeting Notes Analysis"
}
```

## Deployment Steps

1. **Deploy LWC Component:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/lwc/meetingNotesDisplay
   ```

2. **Deploy Updated Apex Class:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/classes/UniversalAgentforceTableFormatter.cls
   ```

3. **Deploy Updated Flow:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/flows/MeetingNotes_Formatted.flow-meta.xml
   ```

4. **Deploy Updated Schema:**
   ```bash
   sf project deploy start --source-dir force-app/main/default/genAiPlannerBundles/AF_Decision_Maker
   ```

## Testing

### Test Markdown Output
1. Trigger the Agentforce action
2. Verify `processingStatus` contains Markdown (not HTML)
3. Check that Agentforce renders the Markdown correctly

### Test LWC Component (on Record Page)
1. Go to Meeting Note record page
2. Edit page in Lightning App Builder
3. Add `meetingNotesDisplay` component
4. Configure:
   - `meetingData`: Pass JSON string
   - `recordId`: Use `{!Meeting_Note__c.Id}`
   - `title`: "Meeting Notes Analysis"
5. Save and activate page
6. View a Meeting Note record to see the component

## Benefits

✅ **Solves HTML Issue**: Markdown is natively supported by Agentforce  
✅ **Reusable Component**: LWC can be used on record pages and Lightning pages  
✅ **Future-Proof**: Component data ready for future Agentforce LWC support  
✅ **Better UX**: Native Salesforce styling and responsive design  
✅ **Maintainable**: Clean separation of concerns

## Notes

- **Current Agentforce Limitation**: Agentforce conversations currently render Markdown, not LWC components directly
- **Workaround**: Use Markdown in conversation, LWC on record pages
- **Future Enhancement**: When Agentforce supports LWC rendering, the component data is already available

## Component Features

- **Auto-detection**: Automatically detects tables, lists, and text
- **Icons**: Context-aware icons for different data types
- **Tables**: Renders structured data as SLDS tables
- **Lists**: Bullet lists for array data
- **Record Links**: Direct links to Meeting Note records
- **Error Handling**: Graceful fallback if data is invalid

## Example Usage

### In Flow Output
The Flow returns:
- `processingStatus`: Markdown string (rendered by Agentforce)
- `componentData`: JSON string with component props
- `componentName`: "c:meetingNotesDisplay"

### On Record Page
```html
<c-meeting-notes-display
    meeting-data={meetingNoteJson}
    record-id={recordId}
    title="Meeting Analysis">
</c-meeting-notes-display>
```

## Troubleshooting

**Issue**: Component not rendering
- **Solution**: Check that component is exposed in `js-meta.xml`
- **Solution**: Verify JSON data format is valid

**Issue**: Markdown not rendering in Agentforce
- **Solution**: Ensure Flow is returning Markdown (not HTML)
- **Solution**: Check `outputFormat` is set to `'markdown'`

**Issue**: Tables not displaying correctly
- **Solution**: Verify JSON structure has array of objects
- **Solution**: Check component console for parsing errors

