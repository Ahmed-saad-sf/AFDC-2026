/**
 * Service class for processing meeting notes using Flow-based Agentforce
 * 
 * NOTE: This class is primarily used when Flow needs to call Apex for complex operations.
 * The primary flow is: Agentforce Conversation → Flow → Agentforce LLM → Meeting_Note__c
 * 
 * This service can be called from Flow or used as a helper for optional LWC component.
 */
public with sharing class MeetingNotesAgentforceService {
    
    /**
     * Process meeting notes using Flow-based Agentforce
     * Called from Flow or optional LWC component
     * 
     * @param meetingNoteId The ID of the Meeting_Note__c record
     * @return Processed insights as a string
     */
    public static String processMeetingNotes(Id meetingNoteId) {
        try {
            // Retrieve the meeting note
            Meeting_Note__c meetingNote = [
                SELECT Id, Raw_Notes__c, Processing_Status__c 
                FROM Meeting_Note__c 
                WHERE Id = :meetingNoteId 
                LIMIT 1
            ];
            
            // Update status to Processing
            meetingNote.Processing_Status__c = 'Processing';
            update meetingNote;
            
            // Call Flow-based Agentforce with LLM
            // The Flow handles the Agentforce LLM processing
            String processedInsights = invokeAgentforceFlow(meetingNote.Raw_Notes__c);
            
            // Update the meeting note with processed insights
            meetingNote.Processed_Insights__c = processedInsights;
            meetingNote.Processing_Status__c = 'Completed';
            update meetingNote;
            
            return processedInsights;
            
        } catch (Exception e) {
            // Update status to Error
            Meeting_Note__c meetingNote = new Meeting_Note__c(Id = meetingNoteId);
            meetingNote.Processing_Status__c = 'Error';
            update meetingNote;
            
            throw new MeetingNotesProcessingException('Error processing meeting notes: ' + e.getMessage());
        }
    }
    
    /**
     * Invoke Flow-based Agentforce with LLM
     * The Flow "MeetingNotesProcessor" processes meeting notes via Agentforce LLM
     * 
     * @param rawNotes The raw meeting notes to process
     * @return Processed insights from Agentforce LLM
     */
    private static String invokeAgentforceFlow(String rawNotes) {
        try {
            Flow.Interview.MeetingNotesProcessor flow = new Flow.Interview.MeetingNotesProcessor(
                new Map<String, Object>{
                    'rawNotes' => rawNotes
                }
            );
            
            flow.start();
            
            String result = (String)flow.getVariableValue('processedInsights');
            
            if (result == null || result.trim().length() == 0) {
                throw new MeetingNotesProcessingException('Flow completed but no insights were returned. Please check Flow configuration.');
            }
            
            return result;
            
        } catch (FlowException e) {
            throw new MeetingNotesProcessingException('Flow Error: ' + e.getMessage() + '. Please ensure the Flow "MeetingNotesProcessor" exists and is active.');
        } catch (Exception e) {
            throw new MeetingNotesProcessingException('Error invoking Flow-based Agentforce: ' + e.getMessage());
        }
    }
    
    /**
     * Custom exception class
     */
    public class MeetingNotesProcessingException extends Exception {}
}

