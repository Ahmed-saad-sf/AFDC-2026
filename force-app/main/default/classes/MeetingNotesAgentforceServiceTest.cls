/**
 * Test class for MeetingNotesAgentforceService
 */
@isTest
private class MeetingNotesAgentforceServiceTest {
    
    @isTest
    static void testProcessMeetingNotes_Success() {
        // Create test data
        Meeting_Note__c testNote = new Meeting_Note__c(
            Raw_Notes__c = 'Meeting with John. Discussed Q4 goals. Action: Follow up next week.',
            Meeting_Date__c = Date.today(),
            Processing_Status__c = 'Pending'
        );
        insert testNote;
        
        Test.startTest();
        String result = MeetingNotesAgentforceService.processMeetingNotes(testNote.Id);
        Test.stopTest();
        
        // Verify results
        Meeting_Note__c updatedNote = [
            SELECT Id, Processing_Status__c, Processed_Insights__c 
            FROM Meeting_Note__c 
            WHERE Id = :testNote.Id
        ];
        
        System.assertEquals('Completed', updatedNote.Processing_Status__c, 'Status should be Completed');
        System.assertNotEquals(null, updatedNote.Processed_Insights__c, 'Insights should be populated');
    }
    
    @isTest
    static void testProcessMeetingNotes_Error() {
        // Create test data with invalid ID
        Id invalidId = '001000000000000AAA';
        
        Test.startTest();
        try {
            MeetingNotesAgentforceService.processMeetingNotes(invalidId);
            System.assert(false, 'Should have thrown an exception');
        } catch (MeetingNotesAgentforceService.MeetingNotesProcessingException e) {
            System.assert(true, 'Exception thrown as expected');
        }
        Test.stopTest();
    }
}



