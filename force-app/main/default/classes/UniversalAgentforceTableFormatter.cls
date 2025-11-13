public class UniversalAgentforceTableFormatter {
    
    @InvocableMethod(label='Format JSON Response with Dynamic Tables' 
                     description='Converts any JSON structure to formatted HTML or Markdown with auto-detected tables')
    public static List<Response> formatResponse(List<Request> requests) {
        Request req = requests[0];
        Response res = new Response();
        
        try {
            // Clean JSON if it has markdown code fences
            String cleanedJson = cleanJson(req.jsonResponse);
            
            Map<String, Object> data = 
                (Map<String, Object>) JSON.deserializeUntyped(cleanedJson);
            
            // Determine output format
            String outputFormat = String.isBlank(req.outputFormat) ? 'html' : req.outputFormat.toLowerCase();
            
            // Build formatted response based on format
            if (outputFormat == 'markdown') {
                res.formattedOutput = buildMarkdownResponse(data, req.recordId);
            } else {
                res.formattedOutput = buildDynamicHTMLResponse(data, req.recordId, req.tableStyling);
            }
            
            res.formattedHtml = res.formattedOutput; // Backward compatibility
            res.plainText = buildPlainTextResponse(data, req.recordId);
            res.success = true;
            res.tablesDetected = detectTableCount(data);
            
        } catch (Exception e) {
            res.formattedOutput = '❌ Error formatting response: ' + e.getMessage();
            res.formattedHtml = res.formattedOutput;
            res.plainText = res.formattedOutput;
            res.success = false;
            res.tablesDetected = 0;
        }
        
        return new List<Response>{ res };
    }
    
    // ============================================================
    // CLEAN JSON - REMOVE MARKDOWN CODE FENCES
    // ============================================================
    private static String cleanJson(String jsonString) {
        if (String.isBlank(jsonString)) {
            return jsonString;
        }
        
        String cleaned = jsonString.trim();
        
        // Remove ```json at start
        if (cleaned.startsWith('```json')) {
            cleaned = cleaned.substring(7);
        } else if (cleaned.startsWith('```')) {
            cleaned = cleaned.substring(3);
        }
        
        // Remove ``` at end
        if (cleaned.endsWith('```')) {
            cleaned = cleaned.substring(0, cleaned.length() - 3);
        }
        
        return cleaned.trim();
    }
    
    // ============================================================
    // MARKDOWN RESPONSE BUILDER
    // ============================================================
    private static String buildMarkdownResponse(Map<String, Object> data, String recordId) {
        String markdown = '';
        
        // Header
        markdown += '# ✅ Analysis Complete\n\n';
        
        // Process each field in the JSON
        for (String key : data.keySet()) {
            Object value = data.get(key);
            markdown += processFieldMarkdown(key, value);
        }
        
        // Record Link
        if (String.isNotBlank(recordId)) {
            markdown += '\n---\n\n';
            markdown += '🔗 **[View Complete Record](/lightning/r/Meeting_Note__c/' + recordId + '/view)**\n\n';
        }
        
        // Footer
        markdown += '\n---\n\n';
        markdown += '*Would you like me to analyze another meeting or help with something else?*\n';
        
        return markdown;
    }
    
    // ============================================================
    // PROCESS FIELD - MARKDOWN VERSION
    // ============================================================
    private static String processFieldMarkdown(String fieldName, Object value) {
        String markdown = '';
        
        if (value == null) {
            return '';
        }
        
        String valueType = getValueType(value);
        
        if (valueType == 'LIST') {
            List<Object> listValue = (List<Object>) value;
            
            if (isTable(listValue)) {
                markdown += buildMarkdownTable(fieldName, listValue);
            } else {
                markdown += buildMarkdownList(fieldName, listValue);
            }
            
        } else if (valueType == 'MAP') {
            markdown += buildMarkdownNestedObject(fieldName, (Map<String, Object>) value);
            
        } else if (valueType == 'STRING' || valueType == 'PRIMITIVE') {
            markdown += buildMarkdownSimpleField(fieldName, String.valueOf(value));
        }
        
        return markdown;
    }
    
    // ============================================================
    // MARKDOWN TABLE BUILDER
    // ============================================================
    private static String buildMarkdownTable(String tableName, List<Object> tableData) {
        if (tableData == null || tableData.isEmpty()) {
            return '';
        }
        
        String markdown = '';
        
        // Section header
        markdown += '\n## ' + getIcon(tableName) + ' ' + formatFieldName(tableName) + '\n\n';
        
        // Get all unique column names
        Set<String> allColumns = new Set<String>();
        for (Object row : tableData) {
            if (row instanceof Map<String, Object>) {
                allColumns.addAll(((Map<String, Object>) row).keySet());
            }
        }
        List<String> columns = new List<String>(allColumns);
        columns.sort();
        
        // Table Header
        markdown += '| ';
        for (String column : columns) {
            markdown += formatFieldName(column) + ' | ';
        }
        markdown += '\n';
        
        // Table separator
        markdown += '|';
        for (Integer i = 0; i < columns.size(); i++) {
            markdown += '---|';
        }
        markdown += '\n';
        
        // Table Body
        for (Object row : tableData) {
            if (row instanceof Map<String, Object>) {
                Map<String, Object> rowMap = (Map<String, Object>) row;
                
                markdown += '| ';
                for (String column : columns) {
                    Object cellValue = rowMap.get(column);
                    markdown += formatCellValueMarkdown(column, cellValue) + ' | ';
                }
                markdown += '\n';
            }
        }
        
        markdown += '\n';
        
        return markdown;
    }
    
    // ============================================================
    // FORMAT CELL VALUE - MARKDOWN VERSION
    // ============================================================
    private static String formatCellValueMarkdown(String columnName, Object value) {
        if (value == null) {
            return '—';
        }
        
        String strValue = String.valueOf(value);
        String lowerColumn = columnName.toLowerCase();
        
        // Escape pipe characters to prevent table breaking
        strValue = strValue.replace('|', '\\|');
        
        // Match Decision / Status / Boolean fields
        if (lowerColumn.contains('match') || 
            lowerColumn.contains('decision') || 
            lowerColumn.contains('status') || 
            lowerColumn.contains('approved')) {
            return formatBadgeMarkdown(strValue);
        }
        
        // Percentage fields
        if (lowerColumn.contains('percent') || 
            lowerColumn.contains('rate') || 
            strValue.endsWith('%')) {
            return '**' + strValue + '**';
        }
        
        // Amount/Currency fields
        if (lowerColumn.contains('amount') || 
            lowerColumn.contains('price') || 
            lowerColumn.contains('cost') || 
            lowerColumn.contains('rent')) {
            return '**' + strValue + '**';
        }
        
        // Parameter/Name fields
        if (lowerColumn.contains('parameter') || 
            lowerColumn.contains('name') || 
            lowerColumn.contains('title')) {
            return '**' + strValue + '**';
        }
        
        return strValue;
    }
    
    // ============================================================
    // FORMAT BADGE - MARKDOWN VERSION
    // ============================================================
    private static String formatBadgeMarkdown(String value) {
        String icon;
        String upperValue = value.toUpperCase();
        
        if (upperValue == 'YES' || upperValue == 'APPROVED' || 
            upperValue == 'SUCCESS' || upperValue == 'TRUE') {
            icon = '✅';
        } else if (upperValue == 'NO' || upperValue == 'REJECTED' || 
                   upperValue == 'FAILED' || upperValue == 'FALSE') {
            icon = '❌';
        } else if (upperValue == 'PARTIAL' || upperValue == 'PENDING' || 
                   upperValue.contains('PROGRESS')) {
            icon = '⚠️';
        } else {
            icon = '●';
        }
        
        return icon + ' **' + value + '**';
    }
    
    // ============================================================
    // MARKDOWN LIST BUILDER
    // ============================================================
    private static String buildMarkdownList(String fieldName, List<Object> listValue) {
        if (listValue == null || listValue.isEmpty()) {
            return '';
        }
        
        String markdown = '';
        markdown += '\n## ' + getIcon(fieldName) + ' ' + formatFieldName(fieldName) + '\n\n';
        
        for (Object item : listValue) {
            markdown += '- ' + String.valueOf(item) + '\n';
        }
        
        markdown += '\n';
        
        return markdown;
    }
    
    // ============================================================
    // MARKDOWN SIMPLE FIELD
    // ============================================================
    private static String buildMarkdownSimpleField(String fieldName, String value) {
        if (String.isBlank(value)) {
            return '';
        }
        
        String lowerField = fieldName.toLowerCase();
        
        // Summary or Description - blockquote formatting
        if (lowerField.contains('summary') || lowerField.contains('description')) {
            String markdown = '\n## ' + getIcon(fieldName) + ' ' + formatFieldName(fieldName) + '\n\n';
            markdown += '> ' + value.replace('\n', '\n> ') + '\n\n';
            return markdown;
        }
        
        // Comparison Type or short fields - inline
        if (lowerField.contains('type') || lowerField.contains('status') || lowerField == 'comparisontype') {
            return '**' + formatFieldName(fieldName) + ':** ' + value + '\n\n';
        }
        
        // Regular field
        return '\n**' + formatFieldName(fieldName) + ':**\n' + value + '\n\n';
    }
    
    // ============================================================
    // MARKDOWN NESTED OBJECT
    // ============================================================
    private static String buildMarkdownNestedObject(String fieldName, Map<String, Object> nestedMap) {
        String markdown = '';
        markdown += '\n## ' + formatFieldName(fieldName) + '\n\n';
        
        for (String key : nestedMap.keySet()) {
            markdown += processFieldMarkdown(key, nestedMap.get(key));
        }
        
        return markdown;
    }
    
    // ============================================================
    // DYNAMIC HTML BUILDER (ORIGINAL)
    // ============================================================
    private static String buildDynamicHTMLResponse(Map<String, Object> data, 
                                                    String recordId, 
                                                    String styling) {
        String html = '<div style="font-family: Arial, sans-serif; max-width: 100%;">';
        
        // Header
        html += '<h3 style="color: #0176d3; margin-bottom: 10px;">✅ Analysis Complete</h3>';
        
        // Process each field in the JSON
        for (String key : data.keySet()) {
            Object value = data.get(key);
            html += processField(key, value, styling);
        }
        
        // Record Link
        if (String.isNotBlank(recordId)) {
            html += '<div style="margin-top: 20px; padding: 12px; background-color: #e8f4fd; border-radius: 4px;">';
            html += '<strong>🔗 View Complete Record:</strong> ';
            html += '<a href="/lightning/r/Meeting_Note__c/' + recordId + '/view" ';
            html += 'style="color: #0176d3; text-decoration: none; font-weight: 500;">Meeting Note</a>';
            html += '</div>';
        }
        
        // Footer
        html += '<div style="margin-top: 20px; padding: 10px; border-top: 1px solid #dddddd; color: #666;">';
        html += '<em>Would you like me to analyze another meeting or help with something else?</em>';
        html += '</div>';
        
        html += '</div>';
        
        return html;
    }
    
    // ============================================================
    // PROCESS FIELD - HTML VERSION (ORIGINAL)
    // ============================================================
    private static String processField(String fieldName, Object value, String styling) {
        String html = '';
        
        if (value == null) {
            return '';
        }
        
        String valueType = getValueType(value);
        
        if (valueType == 'LIST') {
            List<Object> listValue = (List<Object>) value;
            
            if (isTable(listValue)) {
                html += buildDynamicTable(fieldName, listValue, styling);
            } else {
                html += buildList(fieldName, listValue);
            }
            
        } else if (valueType == 'MAP') {
            html += buildNestedObject(fieldName, (Map<String, Object>) value);
            
        } else if (valueType == 'STRING' || valueType == 'PRIMITIVE') {
            html += buildSimpleField(fieldName, String.valueOf(value));
        }
        
        return html;
    }
    
    // ============================================================
    // DYNAMIC TABLE BUILDER - HTML (ORIGINAL)
    // ============================================================
    private static String buildDynamicTable(String tableName, 
                                            List<Object> tableData, 
                                            String styling) {
        if (tableData == null || tableData.isEmpty()) {
            return '';
        }
        
        String html = '';
        
        html += '<h4 style="color: #0176d3; margin-top: 20px; margin-bottom: 10px;">';
        html += getIcon(tableName) + ' ' + formatFieldName(tableName);
        html += '</h4>';
        
        String tableStyle = getStyling(styling, 'table');
        html += '<table style="' + tableStyle + '">';
        
        Set<String> allColumns = new Set<String>();
        for (Object row : tableData) {
            if (row instanceof Map<String, Object>) {
                allColumns.addAll(((Map<String, Object>) row).keySet());
            }
        }
        List<String> columns = new List<String>(allColumns);
        columns.sort();
        
        html += '<thead>';
        html += '<tr style="' + getStyling(styling, 'headerRow') + '">';
        for (String column : columns) {
            html += '<th style="' + getStyling(styling, 'headerCell') + '">';
            html += formatFieldName(column);
            html += '</th>';
        }
        html += '</tr>';
        html += '</thead>';
        
        html += '<tbody>';
        Integer rowIndex = 0;
        for (Object row : tableData) {
            if (row instanceof Map<String, Object>) {
                Map<String, Object> rowMap = (Map<String, Object>) row;
                
                String rowStyle = getStyling(styling, 'bodyRow');
                if (Math.mod(rowIndex, 2) == 0) {
                    rowStyle += ' background-color: #f9f9f9;';
                }
                
                html += '<tr style="' + rowStyle + '">';
                
                for (String column : columns) {
                    Object cellValue = rowMap.get(column);
                    html += '<td style="' + getStyling(styling, 'bodyCell') + '">';
                    html += formatCellValue(column, cellValue, styling);
                    html += '</td>';
                }
                
                html += '</tr>';
                rowIndex++;
            }
        }
        html += '</tbody>';
        html += '</table>';
        
        return html;
    }
    
    // ============================================================
    // FORMAT CELL VALUE - HTML (ORIGINAL)
    // ============================================================
    private static String formatCellValue(String columnName, Object value, String styling) {
        if (value == null) {
            return '<span style="color: #999; font-style: italic;">—</span>';
        }
        
        String strValue = String.valueOf(value);
        String lowerColumn = columnName.toLowerCase();
        
        if (lowerColumn.contains('match') || 
            lowerColumn.contains('decision') || 
            lowerColumn.contains('status') || 
            lowerColumn.contains('approved')) {
            return formatBadge(strValue);
        }
        
        if (lowerColumn.contains('percent') || 
            lowerColumn.contains('rate') || 
            strValue.endsWith('%')) {
            return '<span style="font-weight: 600; color: #0176d3;">' + strValue + '</span>';
        }
        
        if (lowerColumn.contains('amount') || 
            lowerColumn.contains('price') || 
            lowerColumn.contains('cost') || 
            lowerColumn.contains('rent')) {
            return '<span style="font-weight: 600; color: #2e844a;">' + strValue + '</span>';
        }
        
        if (lowerColumn.contains('date') || 
            lowerColumn.contains('rcd') || 
            lowerColumn.contains('time')) {
            return '<span style="color: #666;">' + strValue + '</span>';
        }
        
        if (lowerColumn.contains('parameter') || 
            lowerColumn.contains('name') || 
            lowerColumn.contains('title')) {
            return '<strong>' + strValue + '</strong>';
        }
        
        if (lowerColumn.contains('note') || 
            lowerColumn.contains('description') || 
            lowerColumn.contains('comment')) {
            return '<span style="font-size: 13px; color: #666;">' + strValue + '</span>';
        }
        
        return strValue;
    }
    
    // ============================================================
    // FORMAT BADGE - HTML (ORIGINAL)
    // ============================================================
    private static String formatBadge(String value) {
        String color;
        String icon;
        String upperValue = value.toUpperCase();
        
        if (upperValue == 'YES' || upperValue == 'APPROVED' || 
            upperValue == 'SUCCESS' || upperValue == 'TRUE') {
            color = '#2e844a';
            icon = '✓';
        } else if (upperValue == 'NO' || upperValue == 'REJECTED' || 
                   upperValue == 'FAILED' || upperValue == 'FALSE') {
            color = '#c23934';
            icon = '✗';
        } else if (upperValue == 'PARTIAL' || upperValue == 'PENDING' || 
                   upperValue.contains('PROGRESS')) {
            color = '#fe9339';
            icon = '◐';
        } else {
            color = '#706e6b';
            icon = '●';
        }
        
        return '<span style="display: inline-block; padding: 4px 10px; border-radius: 12px; ' +
               'background-color: ' + color + '; color: white; font-weight: 600; font-size: 12px;">' +
               icon + ' ' + value + '</span>';
    }
    
    // ============================================================
    // BUILD LIST - HTML (ORIGINAL)
    // ============================================================
    private static String buildList(String fieldName, List<Object> listValue) {
        if (listValue == null || listValue.isEmpty()) {
            return '';
        }
        
        String html = '';
        html += '<h4 style="color: #0176d3; margin-top: 20px; margin-bottom: 10px;">';
        html += getIcon(fieldName) + ' ' + formatFieldName(fieldName);
        html += '</h4>';
        html += '<ul style="margin: 0; padding-left: 20px;">';
        
        for (Object item : listValue) {
            html += '<li style="margin-bottom: 5px;">' + String.valueOf(item) + '</li>';
        }
        
        html += '</ul>';
        
        return html;
    }
    
    // ============================================================
    // BUILD SIMPLE FIELD - HTML (ORIGINAL)
    // ============================================================
    private static String buildSimpleField(String fieldName, String value) {
        if (String.isBlank(value)) {
            return '';
        }
        
        String lowerField = fieldName.toLowerCase();
        
        if (lowerField.contains('summary') || 
            lowerField.contains('description') || 
            lowerField == 'summary') {
            String html = '<div style="background-color: #f3f3f3; padding: 12px; border-radius: 4px; margin-bottom: 15px;">';
            html += '<strong>' + getIcon(fieldName) + ' ' + formatFieldName(fieldName) + ':</strong><br/>';
            html += value;
            html += '</div>';
            return html;
        }
        
        String html = '<div style="margin-bottom: 10px;">';
        html += '<strong>' + formatFieldName(fieldName) + ':</strong> ' + value;
        html += '</div>';
        
        return html;
    }
    
    // ============================================================
    // BUILD NESTED OBJECT - HTML (ORIGINAL)
    // ============================================================
    private static String buildNestedObject(String fieldName, Map<String, Object> nestedMap) {
        String html = '';
        html += '<h4 style="color: #0176d3; margin-top: 20px; margin-bottom: 10px;">';
        html += formatFieldName(fieldName);
        html += '</h4>';
        html += '<div style="margin-left: 20px; padding-left: 15px; border-left: 3px solid #0176d3;">';
        
        for (String key : nestedMap.keySet()) {
            html += processField(key, nestedMap.get(key), 'default');
        }
        
        html += '</div>';
        
        return html;
    }
    
    // ============================================================
    // HELPER METHODS (SHARED)
    // ============================================================
    
    private static Boolean isTable(List<Object> listValue) {
        if (listValue == null || listValue.isEmpty()) {
            return false;
        }
        
        Object firstItem = listValue[0];
        if (!(firstItem instanceof Map<String, Object>)) {
            return false;
        }
        
        Map<String, Object> firstMap = (Map<String, Object>) firstItem;
        Set<String> firstKeys = firstMap.keySet();
        
        return firstKeys.size() > 1;
    }
    
    private static String getValueType(Object value) {
        if (value instanceof List<Object>) {
            return 'LIST';
        } else if (value instanceof Map<String, Object>) {
            return 'MAP';
        } else if (value instanceof String) {
            return 'STRING';
        } else {
            return 'PRIMITIVE';
        }
    }
    
    private static String formatFieldName(String fieldName) {
        if (String.isBlank(fieldName)) {
            return '';
        }
        
        String formatted = fieldName;
        formatted = formatted.replace('_', ' ');
        formatted = formatted.replaceAll('([a-z])([A-Z])', '$1 $2');
        
        List<String> words = formatted.split(' ');
        List<String> titleWords = new List<String>();
        for (String word : words) {
            if (String.isNotBlank(word)) {
                titleWords.add(word.substring(0, 1).toUpperCase() + 
                              word.substring(1).toLowerCase());
            }
        }
        
        return String.join(titleWords, ' ');
    }
    
    private static String getIcon(String fieldName) {
        String lower = fieldName.toLowerCase();
        
        if (lower.contains('table') || lower.contains('comparison')) return '📊';
        if (lower.contains('summary')) return '📋';
        if (lower.contains('topic')) return '🎯';
        if (lower.contains('action')) return '📌';
        if (lower.contains('decision')) return '✅';
        if (lower.contains('note')) return '📝';
        if (lower.contains('key')) return '🔑';
        
        return '▸';
    }
    
    private static String getStyling(String profile, String element) {
        if (profile == 'minimal') {
            return getMinimalStyle(element);
        } else if (profile == 'colorful') {
            return getColorfulStyle(element);
        } else {
            return getDefaultStyle(element);
        }
    }
    
    private static String getDefaultStyle(String element) {
        Map<String, String> styles = new Map<String, String>{
            'table' => 'width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 14px;',
            'headerRow' => 'background-color: #0176d3; color: white;',
            'headerCell' => 'padding: 10px; text-align: left; border: 1px solid #ddd;',
            'bodyRow' => 'background-color: #ffffff;',
            'bodyCell' => 'padding: 10px; border: 1px solid #ddd;'
        };
        return styles.get(element);
    }
    
    private static String getMinimalStyle(String element) {
        Map<String, String> styles = new Map<String, String>{
            'table' => 'width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 14px;',
            'headerRow' => 'border-bottom: 2px solid #333;',
            'headerCell' => 'padding: 8px; text-align: left; font-weight: 600;',
            'bodyRow' => '',
            'bodyCell' => 'padding: 8px; border-bottom: 1px solid #eee;'
        };
        return styles.get(element);
    }
    
    private static String getColorfulStyle(String element) {
        Map<String, String> styles = new Map<String, String>{
            'table' => 'width: 100%; border-collapse: collapse; margin-bottom: 15px; font-size: 14px; box-shadow: 0 2px 4px rgba(0,0,0,0.1);',
            'headerRow' => 'background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white;',
            'headerCell' => 'padding: 12px; text-align: left; border: 1px solid #ddd;',
            'bodyRow' => 'background-color: #ffffff;',
            'bodyCell' => 'padding: 10px; border: 1px solid #ddd;'
        };
        return styles.get(element);
    }
    
    private static Integer detectTableCount(Map<String, Object> data) {
        Integer count = 0;
        for (String key : data.keySet()) {
            Object value = data.get(key);
            if (value instanceof List<Object>) {
                if (isTable((List<Object>) value)) {
                    count++;
                }
            }
        }
        return count;
    }
    
    private static String buildPlainTextResponse(Map<String, Object> data, String recordId) {
        String text = '✅ Analysis Complete\n\n';
        
        for (String key : data.keySet()) {
            text += formatFieldName(key) + ':\n';
            text += String.valueOf(data.get(key)) + '\n\n';
        }
        
        text += '\n🔗 View record: ' + recordId + '\n';
        
        return text;
    }
    
    // ============================================================
    // INNER CLASSES (UPDATED)
    // ============================================================
    public class Request {
        @InvocableVariable(required=true label='JSON Response from LLM')
        public String jsonResponse;
        
        @InvocableVariable(label='Meeting Note Record ID')
        public String recordId;
        
        @InvocableVariable(label='Output Format' 
                          description='html or markdown (default: html)')
        public String outputFormat = 'html';
        
        @InvocableVariable(label='Table Styling Profile' 
                          description='default, minimal, or colorful (HTML only)')
        public String tableStyling = 'default';
    }
    
    public class Response {
        @InvocableVariable(label='Formatted Output (HTML or Markdown)')
        public String formattedOutput;
        
        @InvocableVariable(label='Formatted HTML Output (deprecated - use formattedOutput)')
        public String formattedHtml;
        
        @InvocableVariable(label='Plain Text Fallback')
        public String plainText;
        
        @InvocableVariable(label='Success')
        public Boolean success;
        
        @InvocableVariable(label='Number of Tables Detected')
        public Integer tablesDetected;
    }
}