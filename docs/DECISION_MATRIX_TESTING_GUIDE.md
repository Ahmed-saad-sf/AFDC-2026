# Decision Matrix Solution - Testing Guide

## ✅ Deployment Status

All components have been successfully deployed:
- ✅ **Apex Class**: `DealComparisonProcessor` (new)
- ✅ **Apex Class**: `UniversalAgentforceTableFormatter` (updated)
- ✅ **Flow**: `MeetingNotes_Formatted` (updated with comparison step)
- ✅ **Prompt Template**: `Meeting_Notes_Analyzer` (updated)
- ✅ **Topic Instructions**: Updated with decision matrix logic
- ✅ **Schema**: Output schema updated

---

## 🧪 Step-by-Step Testing Guide

### **Prerequisites**

1. **Create Test Opportunity Record** (if testing with existing deal):
   - Navigate to **Opportunities** tab
   - Create a new Opportunity with:
     - **Brand Concept**: Café B (or use field: `Brand_Concept__c`, `Brand__c`, or `BrandConcept__c`)
     - **Location**: Farsi Mall (or use field: `Location__c` or `Mall__c`)
     - **Unit Name**: A1-B1 (or use field: `Unit_Name__c`, `UnitName__c`, or `Unit__c`)
     - **Percentage Rent**: 12% (or use field: `Percentage_Rent__c`)
     - **TOR Frequency**: Monthly (or use field: `TOR_Frequency__c`)
     - **NER Applicability**: Basic Rent only (or use field: `NER_Applicability__c`)
     - **Lease Period**: 60 (or use field: `Lease_Period__c` or `Lease_Period_Months__c`)
     - **RCD**: 1-Nov-2025 (or use field: `RCD__c` or `Rent_Commencement_Date__c`)

2. **Note Field API Names**: 
   - The Apex class tries multiple field name variations
   - If your org uses different field names, you may need to update `DealComparisonProcessor.cls`

---

### **Test 1: Test with Existing Opportunity (Match Scenario)**

#### Step 1.1: Prepare Test Data
1. Ensure you have an Opportunity record matching:
   - Brand: Café B
   - Location: Farsi Mall
   - Unit: A1-B1

#### Step 1.2: Test in Agentforce
1. Open **Agentforce** → **AF_Decision_Maker** agent
2. Start a conversation with:
   ```
   I need to process meeting notes from today's DAC meeting.
   
   Meeting: DAC Decision Meeting
   Date: Today
   
   Key Decisions:
   - Brand Concept: Café B (same as existing)
   - Location: Farsi Mall (same as existing)
   - Percentage Rent: 12% (same as existing)
   - TOR Frequency: Monthly (same as existing)
   - NER Applicability: Basic Rent only (same as existing)
   - Lease Period: 60 months (same as existing)
   - RCD: 1-Nov-2025 (same as existing)
   ```

#### Step 1.3: Verify Results
**Expected Result:**
- ✅ Comparison table shows all parameters
- ✅ **Existing Deal in CRM** column populated with values from Opportunity
- ✅ **DAC Decision** column shows meeting decisions
- ✅ **Match Decision** shows "Yes" for all parameters
- ✅ **Final Decision** = **"Go"** (all parameters match)

---

### **Test 2: Test with Existing Opportunity (No Match Scenario)**

#### Step 2.1: Test in Agentforce
1. Use the same Opportunity from Test 1
2. Start conversation with:
   ```
   I need to process meeting notes from today's DAC meeting.
   
   Meeting: DAC Decision Meeting
   
   Key Decisions:
   - Brand Concept: Café B (same)
   - Location: Farsi Mall (same)
   - Percentage Rent: 15% (CHANGED from 12%)
   - TOR Frequency: Monthly (same)
   - NER Applicability: Basic Rent only (same)
   - Lease Period: 60 months (same)
   - RCD: 1-Nov-2025 (same)
   ```

#### Step 2.2: Verify Results
**Expected Result:**
- ✅ Comparison table shows all parameters
- ✅ **Existing Deal in CRM** shows: 12%
- ✅ **DAC Decision** shows: 15%
- ✅ **Match Decision** for Percentage Rent = **"No"**
- ✅ **Match Decision** for other parameters = **"Yes"**
- ✅ **Final Decision** = **"No Go"** (because Percentage Rent doesn't match)

---

### **Test 3: Test with No Existing Opportunity**

#### Step 3.1: Test in Agentforce
1. Use a Brand/Location/Unit combination that doesn't exist in Opportunities
2. Start conversation with:
   ```
   I need to process meeting notes for a new deal.
   
   Meeting: DAC Decision Meeting
   
   Key Decisions:
   - Brand Concept: New Brand X
   - Location: New Location Y
   - Unit Name: Unit Z
   - Percentage Rent: 15%
   - TOR Frequency: Monthly
   - NER Applicability: Basic Rent only
   - Lease Period: 60 months
   - RCD: 1-Jan-2026
   ```

#### Step 3.2: Verify Results
**Expected Result:**
- ✅ Comparison table shows all parameters
- ✅ **Existing Deal in CRM** shows: "Not found" for all parameters
- ✅ **Match Decision** = **"No"** for all parameters (no existing deal)
- ✅ **Final Decision** = **"No Go"** (no existing deal found)

---

### **Test 4: Verify Decision Matrix Format**

#### Step 4.1: Check Response Format
The response should include:

```
# ✅ Analysis Complete

## ❌ Final Decision: No Go

⚠️ **Note:** The final decision is **No Go** because not all parameters match the existing deal in CRM.

## 📊 Decision Comparison Matrix

| Parameter | Existing Deal in CRM | DAC Decision | Notes for New Deal | Match Decision |
|-----------|---------------------|--------------|-------------------|----------------|
| Brand Concept | Café B | Café B | Switch from Café A to Café B | ✅ **Yes** |
| Location | Farsi Mall | Farsi Mall | Same location | ✅ **Yes** |
| Percentage Rent | 12% | 15% | Increase proposed by John | ❌ **No** |
...
```

#### Step 4.2: Verify Table Columns
- ✅ **Parameter**: Name of the parameter
- ✅ **Existing Deal in CRM**: Value from Opportunity (or "Not found")
- ✅ **DAC Decision**: Decision from meeting
- ✅ **Notes for New Deal**: Rationale/explanation
- ✅ **Match Decision**: Yes/No/Partial with icons

---

### **Test 5: Verify Final Decision Logic**

#### Test Case 5.1: All Match = Go
- All matchDecisions = "Yes"
- **Expected**: finalDecision = "Go"

#### Test Case 5.2: One No = No Go
- One matchDecision = "No"
- **Expected**: finalDecision = "No Go"

#### Test Case 5.3: One Partial = No Go
- One matchDecision = "Partial"
- **Expected**: finalDecision = "No Go"

#### Test Case 5.4: No Opportunity Found = No Go
- Opportunity not found
- All matchDecisions = "No"
- **Expected**: finalDecision = "No Go"

---

## 🔍 Troubleshooting

### Issue: Opportunity not found when it should exist
**Possible Causes:**
1. Field API names don't match
2. Values don't match exactly (case-sensitive, spacing)
3. Unit Name not provided or doesn't match

**Solution:**
1. Check Opportunity field API names in your org
2. Update `DealComparisonProcessor.cls` with correct field names
3. Verify Brand, Location, Unit Name values match exactly

### Issue: Match Decision always "No"
**Possible Causes:**
1. Field values not being retrieved correctly
2. Comparison logic too strict
3. Date/Number formatting differences

**Solution:**
1. Check debug logs for field retrieval
2. Verify field values in Opportunity record
3. Check comparison logic in `compareValues()` method

### Issue: Final Decision not calculated correctly
**Possible Causes:**
1. Comparison logic not running
2. Match decisions not being set

**Solution:**
1. Check Flow debug logs
2. Verify `DealComparisonProcessor` is being called
3. Check that all matchDecisions are being set

---

## 📋 Field Name Configuration

The Apex class tries these field name variations. **Update if your org uses different names:**

### Brand Concept Fields:
- `Brand_Concept__c`
- `Brand__c`
- `BrandConcept__c`

### Location Fields:
- `Location__c`
- `Mall__c`

### Unit Name Fields:
- `Unit_Name__c`
- `UnitName__c`
- `Unit__c`

### Percentage Rent Fields:
- `Percentage_Rent__c`
- `Rent_Percentage__c`

### TOR Frequency Fields:
- `TOR_Frequency__c`
- `TOR__c`

### NER Applicability Fields:
- `NER_Applicability__c`
- `NER__c`

### Lease Period Fields:
- `Lease_Period__c`
- `Lease_Period_Months__c`

### RCD Fields:
- `RCD__c`
- `Rent_Commencement_Date__c`

---

## ✅ Success Criteria

All tests pass if:
- ✅ Opportunity query works (finds existing deals)
- ✅ Comparison table shows all 5 columns
- ✅ Match decisions are calculated correctly
- ✅ Final decision follows the rule: "No Go" unless ALL match
- ✅ Response is in Markdown format (not HTML)
- ✅ Final decision is prominently displayed
- ✅ No duplicate responses

---

## 🚀 Next Steps

After successful testing:
1. Verify field API names match your org's schema
2. Update `DealComparisonProcessor.cls` if field names differ
3. Test with real meeting notes
4. Monitor for any edge cases
5. Gather user feedback on decision matrix format

