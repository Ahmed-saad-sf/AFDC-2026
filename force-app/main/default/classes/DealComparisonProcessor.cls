/**
 * Apex class for processing deal comparisons and querying Opportunity records
 * Compares DAC Decisions with existing Opportunity records and determines final decision
 */
public with sharing class DealComparisonProcessor {
    
    @InvocableMethod(label='Process Deal Comparison with CRM Query' 
                     description='Queries Opportunity records and compares DAC Decisions to determine match decisions and final decision')
    public static List<ComparisonResult> processComparison(List<ComparisonRequest> requests) {
        ComparisonRequest req = requests[0];
        ComparisonResult res = new ComparisonResult();
        
        try {
            // Validate input
            if (String.isBlank(req.jsonResponse)) {
                res.updatedJsonResponse = req.jsonResponse;
                res.success = false;
                res.errorMessage = 'JSON response is blank';
                res.finalDecision = 'Error';
                return new List<ComparisonResult>{ res };
            }
            
            // Parse JSON response
            Map<String, Object> jsonData = null;
            try {
                jsonData = (Map<String, Object>) JSON.deserializeUntyped(req.jsonResponse);
            } catch (JSONException e) {
                res.updatedJsonResponse = req.jsonResponse;
                res.success = false;
                res.errorMessage = 'Invalid JSON format: ' + e.getMessage();
                res.finalDecision = 'Error';
                return new List<ComparisonResult>{ res };
            }
            
            if (jsonData == null) {
                res.updatedJsonResponse = req.jsonResponse;
                res.success = false;
                res.errorMessage = 'Failed to parse JSON data';
                res.finalDecision = 'Error';
                return new List<ComparisonResult>{ res };
            }
            
            // Extract brand, location, unit for querying
            String brandConcept = jsonData.get('brandConcept') != null ? (String) jsonData.get('brandConcept') : null;
            String location = jsonData.get('location') != null ? (String) jsonData.get('location') : null;
            String unitName = jsonData.get('unitName') != null ? (String) jsonData.get('unitName') : null;
            
            // Query Opportunity
            Opportunity existingOpp = queryOpportunity(brandConcept, location, unitName);
            
            // Get comparison table - handle null case
            List<Object> comparisonTable = null;
            Object comparisonTableObj = jsonData.get('comparisonTable');
            if (comparisonTableObj != null) {
                if (comparisonTableObj instanceof List<Object>) {
                    comparisonTable = (List<Object>) comparisonTableObj;
                }
            }
            
            // Process each parameter and compare
            List<Map<String, Object>> updatedTable = new List<Map<String, Object>>();
            Boolean allMatch = true;
            
            // Only process if comparisonTable exists and is not empty
            if (comparisonTable != null && !comparisonTable.isEmpty()) {
                for (Object rowObj : comparisonTable) {
                    if (rowObj == null) {
                        continue; // Skip null rows
                    }
                    
                    if (!(rowObj instanceof Map<String, Object>)) {
                        continue; // Skip if not a map
                    }
                    
                    Map<String, Object> row = (Map<String, Object>) rowObj;
                    
                    // Get parameter and dacDecision with null checks
                    String parameter = row.get('parameter') != null ? String.valueOf(row.get('parameter')) : null;
                    String dacDecision = row.get('dacDecision') != null ? String.valueOf(row.get('dacDecision')) : null;
                    
                    // Skip if parameter is null
                    if (String.isBlank(parameter)) {
                        continue;
                    }
                    
                    // Get existing value from Opportunity
                    String existingValue = getExistingValue(existingOpp, parameter);
                    
                    // Compare and set matchDecision
                    String matchDecision = compareValues(existingValue, dacDecision, parameter);
                    row.put('existingDealInCRM', existingValue != null ? existingValue : 'Not found');
                    row.put('matchDecision', matchDecision != null ? matchDecision : 'No');
                    
                    // Track if all match
                    if (matchDecision != null && matchDecision != 'Yes') {
                        allMatch = false;
                    }
                    
                    updatedTable.add(row);
                }
            }
            
            // Update comparison table in JSON (even if empty)
            if (updatedTable != null) {
                jsonData.put('comparisonTable', updatedTable);
            }
            
            // Update JSON with comparison results
            jsonData.put('finalDecision', allMatch ? 'Go' : 'No Go');
            jsonData.put('opportunityFound', existingOpp != null);
            if (existingOpp != null) {
                jsonData.put('existingOpportunityId', existingOpp.Id);
                jsonData.put('existingOpportunityName', existingOpp.Name);
            }
            
            res.updatedJsonResponse = JSON.serialize(jsonData);
            res.success = true;
            res.finalDecision = allMatch ? 'Go' : 'No Go';
            res.opportunityFound = existingOpp != null;
            
        } catch (Exception e) {
            res.updatedJsonResponse = req.jsonResponse; // Return original if error
            res.success = false;
            res.errorMessage = e.getMessage();
            res.finalDecision = 'Error';
        }
        
        return new List<ComparisonResult>{ res };
    }
    
    /**
     * Query Opportunity by Brand, Location, and Unit Name
     */
    private static Opportunity queryOpportunity(String brandConcept, String location, String unitName) {
        if (String.isBlank(brandConcept) || String.isBlank(location)) {
            return null;
        }
        
        try {
            // Escape strings for SOQL
            String brandEscaped = String.escapeSingleQuotes(brandConcept);
            String locationEscaped = String.escapeSingleQuotes(location);
            String unitEscaped = String.isNotBlank(unitName) ? String.escapeSingleQuotes(unitName) : '';
            
            // Build SOQL query - try common field name variations
            // Adjust field names based on your org's schema
            // Start with basic query and add fields that might exist
            String soql = 'SELECT Id, Name';
            
            // Build WHERE clause with field variations
            // Try multiple field name combinations
            List<String> conditions = new List<String>();
            
            // Brand condition (try multiple field names - use OR to handle missing fields)
            String brandCondition = '';
            try {
                brandCondition = '(Brand_Concept__c = \'' + brandEscaped + '\' OR Brand__c = \'' + brandEscaped + '\' OR BrandConcept__c = \'' + brandEscaped + '\')';
                conditions.add(brandCondition);
            } catch (Exception e) {
                // If field doesn't exist, try simpler query
                brandCondition = 'Name LIKE \'%' + brandEscaped + '%\'';
                conditions.add(brandCondition);
            }
            
            // Location condition
            String locationCondition = '(Location__c = \'' + locationEscaped + '\' OR Mall__c = \'' + locationEscaped + '\')';
            conditions.add(locationCondition);
            
            // Unit name condition (optional)
            if (String.isNotBlank(unitEscaped)) {
                String unitCondition = '(Unit_Name__c = \'' + unitEscaped + '\' OR UnitName__c = \'' + unitEscaped + '\' OR Unit__c = \'' + unitEscaped + '\')';
                conditions.add(unitCondition);
            }
            
            String whereClause = ' WHERE ' + String.join(conditions, ' AND ');
            soql += ' FROM Opportunity' + whereClause + ' LIMIT 1';
            
            // Try to query - if it fails due to missing fields, return null gracefully
            try {
                List<Opportunity> opps = Database.query(soql);
                return opps.isEmpty() ? null : opps[0];
            } catch (QueryException e) {
                // If query fails (e.g., fields don't exist), try simpler query
                System.debug('Query failed, trying simpler query: ' + e.getMessage());
                try {
                    // Fallback: query by Name containing brand and location
                    String fallbackSoql = 'SELECT Id, Name FROM Opportunity WHERE Name LIKE \'%' + 
                                         String.escapeSingleQuotes(brandConcept) + '%\' AND Name LIKE \'%' + 
                                         String.escapeSingleQuotes(location) + '%\' LIMIT 1';
                    List<Opportunity> opps = Database.query(fallbackSoql);
                    return opps.isEmpty() ? null : opps[0];
                } catch (Exception e2) {
                    System.debug('Fallback query also failed: ' + e2.getMessage());
                    return null;
                }
            }
            
        } catch (Exception e) {
            // If query fails (e.g., fields don't exist), return null
            System.debug('Error querying Opportunity: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Get existing value from Opportunity based on parameter name
     */
    private static String getExistingValue(Opportunity opp, String parameter) {
        if (opp == null) {
            return null;
        }
        
        if (String.isBlank(parameter)) {
            return null;
        }
        
        // Map parameter names to field API names (try multiple variations)
        Map<String, List<String>> parameterToFields = new Map<String, List<String>>{
            'Brand Concept' => new List<String>{'Brand_Concept__c', 'Brand__c', 'BrandConcept__c'},
            'Location' => new List<String>{'Location__c', 'Mall__c'},
            'Percentage Rent' => new List<String>{'Percentage_Rent__c', 'Rent_Percentage__c'},
            'TOR Frequency' => new List<String>{'TOR_Frequency__c', 'TOR__c'},
            'NER Applicability' => new List<String>{'NER_Applicability__c', 'NER__c'},
            'Lease Period' => new List<String>{'Lease_Period__c', 'Lease_Period_Months__c'},
            'RCD' => new List<String>{'RCD__c', 'Rent_Commencement_Date__c'}
        };
        
        List<String> fieldNames = parameterToFields.get(parameter);
        if (fieldNames == null || fieldNames.isEmpty()) {
            return null;
        }
        
        // Try each field name until we find one that exists
        for (String fieldName : fieldNames) {
            try {
                if (String.isBlank(fieldName)) {
                    continue;
                }
                
                Object value = opp.get(fieldName);
                if (value != null) {
                    // Format based on type
                    if (value instanceof Date) {
                        Date dateValue = (Date) value;
                        return dateValue.format();
                    } else if (value instanceof Decimal) {
                        Decimal dec = (Decimal) value;
                        if (parameter != null && (parameter.contains('Rent') || parameter.contains('Percentage'))) {
                            return String.valueOf(dec) + '%';
                        }
                        return String.valueOf(dec);
                    } else if (value instanceof String) {
                        return (String) value;
                    }
                    return String.valueOf(value);
                }
            } catch (Exception e) {
                // Field doesn't exist, try next one
                System.debug('Field ' + fieldName + ' not accessible: ' + e.getMessage());
                continue;
            }
        }
        
        return null;
    }
    
    /**
     * Compare existing value with DAC decision
     */
    private static String compareValues(String existingValue, String dacDecision, String parameter) {
        // Handle null cases
        if (String.isBlank(existingValue) || existingValue == 'Not found' || existingValue == 'null') {
            return 'No'; // No existing deal found
        }
        
        if (String.isBlank(dacDecision) || dacDecision == 'null') {
            return 'No';
        }
        
        try {
            // Normalize values for comparison
            String existing = normalizeValue(existingValue, parameter);
            String dac = normalizeValue(dacDecision, parameter);
            
            // Check if normalized values are blank
            if (String.isBlank(existing) || String.isBlank(dac)) {
                return 'No';
            }
            
            // Exact match
            if (existing.equalsIgnoreCase(dac)) {
                return 'Yes';
            }
            
            // Partial match (contains or similar)
            if (existing.contains(dac) || dac.contains(existing)) {
                return 'Partial';
            }
            
            // No match
            return 'No';
        } catch (Exception e) {
            // If comparison fails, return No
            System.debug('Error comparing values: ' + e.getMessage());
            return 'No';
        }
    }
    
    /**
     * Normalize values for comparison
     */
    private static String normalizeValue(String value, String parameter) {
        if (String.isBlank(value)) {
            return '';
        }
        
        String normalized = value.trim();
        
        // Remove common formatting
        normalized = normalized.replace('%', '').trim();
        normalized = normalized.replace('months', '').trim();
        normalized = normalized.replace('month', '').trim();
        
        // Handle dates
        if (parameter == 'RCD') {
            // Try to normalize date formats
            normalized = normalized.replace('-', '/');
        }
        
        return normalized.toLowerCase();
    }
    
    // Inner classes
    public class ComparisonRequest {
        @InvocableVariable(required=true label='JSON Response from LLM')
        public String jsonResponse;
    }
    
    public class ComparisonResult {
        @InvocableVariable(label='Updated JSON Response with Match Decisions')
        public String updatedJsonResponse;
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Final Decision')
        public String finalDecision;
        
        @InvocableVariable(label='Opportunity Found')
        public Boolean opportunityFound;
        
        @InvocableVariable(label='Error Message')
        public String errorMessage;
    }
}

