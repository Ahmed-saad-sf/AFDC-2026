import { LightningElement, api } from 'lwc';

export default class MeetingNotesDisplay extends LightningElement {
    @api meetingData;
    @api recordId;
    @api title;

    // Parsed data
    parsedData = {};
    hasData = false;

    connectedCallback() {
        this.parseData();
    }

    parseData() {
        if (!this.meetingData) {
            this.hasData = false;
            return;
        }

        try {
            // If meetingData is a string, parse it as JSON
            if (typeof this.meetingData === 'string') {
                // Remove markdown code fences if present
                let cleaned = this.meetingData.trim();
                if (cleaned.startsWith('```json')) {
                    cleaned = cleaned.substring(7);
                } else if (cleaned.startsWith('```')) {
                    cleaned = cleaned.substring(3);
                }
                if (cleaned.endsWith('```')) {
                    cleaned = cleaned.substring(0, cleaned.length - 3);
                }
                this.parsedData = JSON.parse(cleaned.trim());
            } else {
                this.parsedData = this.meetingData;
            }
            this.hasData = true;
        } catch (error) {
            console.error('Error parsing meeting data:', error);
            this.hasData = false;
        }
    }

    get sections() {
        if (!this.hasData || !this.parsedData) {
            return [];
        }

        const sections = [];
        for (const [key, value] of Object.entries(this.parsedData)) {
            const fieldType = this.getFieldType(value);
            const section = {
                key: key,
                label: this.formatLabel(key),
                value: value,
                type: fieldType,
                icon: this.getIcon(key),
                isTable: fieldType === 'table',
                isList: fieldType === 'list',
                isText: fieldType === 'text',
                isObject: fieldType === 'object'
            };

            // Add table-specific properties
            if (fieldType === 'table') {
                section.columns = this.getTableColumns(value);
                // Process rows to include cell values for template access
                section.rows = value.map((row, index) => {
                    const processedRow = {
                        _index: index,
                        _cells: []
                    };
                    section.columns.forEach(column => {
                        processedRow._cells.push({
                            column: column,
                            value: row[column] || '—'
                        });
                    });
                    return processedRow;
                });
            }
            
            // Add object string representation
            if (fieldType === 'object') {
                section.valueString = JSON.stringify(value, null, 2);
            }

            sections.push(section);
        }
        return sections;
    }

    formatLabel(key) {
        return key
            .replace(/_/g, ' ')
            .replace(/([a-z])([A-Z])/g, '$1 $2')
            .split(' ')
            .map(word => word.charAt(0).toUpperCase() + word.slice(1).toLowerCase())
            .join(' ');
    }

    getFieldType(value) {
        if (Array.isArray(value)) {
            if (value.length > 0 && typeof value[0] === 'object' && value[0] !== null) {
                return 'table';
            }
            return 'list';
        }
        if (typeof value === 'object' && value !== null) {
            return 'object';
        }
        return 'text';
    }

    getIcon(key) {
        const lower = key.toLowerCase();
        if (lower.includes('action')) return '📌';
        if (lower.includes('decision')) return '✅';
        if (lower.includes('topic')) return '🎯';
        if (lower.includes('summary')) return '📋';
        if (lower.includes('table') || lower.includes('comparison')) return '📊';
        if (lower.includes('note')) return '📝';
        if (lower.includes('key')) return '🔑';
        return '▸';
    }

    get recordUrl() {
        if (!this.recordId) return null;
        return `/lightning/r/Meeting_Note__c/${this.recordId}/view`;
    }

    isTableRow(row) {
        return typeof row === 'object' && row !== null && !Array.isArray(row);
    }

    getTableColumns(rows) {
        if (!rows || rows.length === 0) return [];
        const firstRow = rows[0];
        if (typeof firstRow !== 'object' || firstRow === null) return [];
        return Object.keys(firstRow);
    }

    getTableCellValue(row, column) {
        if (!row || typeof row !== 'object') return '—';
        const value = row[column];
        if (value === null || value === undefined) return '—';
        return value;
    }

    formatCellValue(value) {
        if (value === null || value === undefined) return '—';
        if (typeof value === 'boolean') return value ? '✅ Yes' : '❌ No';
        return String(value);
    }
}

