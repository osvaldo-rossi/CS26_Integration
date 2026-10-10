codeunit 55001 "CDS Worker Integration Setup"
{
    var
        // Deliberately distinct from the wizard-created 'WORKER' mapping. Codeunit 5369
        // "Manual Int Mapping Events" replays table 5384 onto whatever name it finds in 5380
        // during OnAfterResetConfiguration, with no existence check - so sharing a name with a
        // wizard mapping makes the result depend on undefined subscriber order. Distinct names
        // also put the AL-registered and wizard-created rows adjacent in Integration Table Mappings.
        MappingName: label 'WORKER AL', Locked = true;
        // The Dataverse entity LOGICAL name - table 55001's ExternalName, not the mapping name.
        // This is what ends up in the &etn= segment of the deep-link URL.
        WorkerEntityName: label 'gbt_worker', Locked = true;


    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", OnGetCDSTableNo, '', false, false)]
    local procedure "CRM Setup Defaults_OnGetCDSTableNo"(BCTableNo: Integer; var CDSTableNo: Integer; var handled: Boolean)
    begin
        if BCTableNo = DATABASE::Employee then begin
            CDSTableNo := DATABASE::"CDS gbt_Worker";
            handled := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Lookup CRM Tables", OnLookupCRMTables, '', false, false)]
    local procedure "Lookup CRM Tables_OnLookupCRMTables"(CRMTableID: Integer; NAVTableId: Integer; SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text; var Handled: Boolean)
    begin
        if CRMTableID = DATABASE::"CDS gbt_Worker" then
            Handled := LookupCDSWorker(SavedCRMId, CRMId, IntTableFilter);
    end;

    local procedure LookupCDSWorker(SavedCRMId: Guid; var CRMId: Guid; IntTableFilter: Text): Boolean
    var
        CDSWorker: Record "CDS gbt_Worker";
        OriginalCDSWorker: Record "CDS gbt_Worker";
        CDSWorkerList: Page "CDS gbt_Worker List";
    begin
        // Position on the current selection and tell the page which Worker is already
        // coupled, so it can render 'Current' in Strong style. Without this the page's
        // StyleExpr never fires and the 'Hide Coupled Workers' filter marks the wrong rows.
        if not IsNullGuid(CRMId) then begin
            if CDSWorker.Get(CRMId) then
                CDSWorkerList.SetRecord(CDSWorker);
            if not IsNullGuid(SavedCRMId) then
                if OriginalCDSWorker.Get(SavedCRMId) then
                    CDSWorkerList.SetCurrentlyCoupledCDSWorker(OriginalCDSWorker);
        end;

        CDSWorker.SetView(IntTableFilter);
        CDSWorkerList.SetTableView(CDSWorker);
        CDSWorkerList.LookupMode(true);
        Commit();
        if CDSWorkerList.RunModal() = ACTION::LookupOK then begin
            CDSWorkerList.GetRecord(CDSWorker);
            CRMId := CDSWorker.gbt_WorkerId;
            exit(true);
        end;
        exit(false);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CRM Setup Defaults", OnAddEntityTableMapping, '', false, false)]
    local procedure "CRM Setup Defaults_OnAddEntityTableMapping"(var TempNameValueBuffer: Record "Name/Value Buffer" temporary)
    var
        CRMSetupDefaults: Codeunit "CRM Setup Defaults";
    begin
        // Both sides get registered, as the base app does for every entity
        // ('contact' is added for both Contact and CRM Contact) - GetCRMEntityTypeName
        // looks the name up by either table id.
        CRMSetupDefaults.AddEntityTableMapping(WorkerEntityName, Database::Employee, TempNameValueBuffer);
        CRMSetupDefaults.AddEntityTableMapping(WorkerEntityName, Database::"CDS gbt_Worker", TempNameValueBuffer);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", OnAfterResetConfiguration, '', false, false)]
    local procedure "CDS Setup Defaults_OnAfterResetConfiguration"(CDSConnectionSetup: Record "CDS Connection Setup")
    var
        IntegrationTableMapping: Record "Integration Table Mapping";
        IntegrationFieldMapping: Record "Integration Field Mapping";
        CDSCompany: Record "CDS Company";
        CDSWorker: Record "CDS gbt_Worker";
        Employee: Record Employee;
        TableMappingRec: Record "Integration Table Mapping";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        EmptyGuid: Guid;
    begin
        InsertIntegrationTableMapping(
            IntegrationTableMapping, MappingName,
            DATABASE::Employee, DATABASE::"CDS gbt_Worker", CDSWorker.FieldNo(gbt_WorkerId), CDSWorker.FieldNo(ModifiedOn), '', '', false, IntegrationTableMapping.Direction::Bidirectional, 'CDS');

        InsertIntegrationFieldMapping(MappingName, Employee.FieldNo("No."), CDSWorker.FieldNo(gbt_WorkerCode), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(MappingName, Employee.FieldNo("First Name"), CDSWorker.FieldNo(gbt_FirstName), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(MappingName, Employee.FieldNo("Middle Name"), CDSWorker.FieldNo(gbt_MiddleName), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(MappingName, Employee.FieldNo("Last Name"), CDSWorker.FieldNo(gbt_LastName), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);
        InsertIntegrationFieldMapping(MappingName, Employee.FieldNo("Job Title"), CDSWorker.FieldNo(gbt_JobTitle), IntegrationFieldMapping.Direction::Bidirectional, '', true, false);

        //After resetting integration, configure default
        //After setting the table integration mapping entities and fields
        //Configure synchronization paramteres.
        If IntegrationTableMapping.Get(MappingName) then begin
            //Direction
            //IntegrationTableMapping.Direction := IntegrationTableMapping.Direction::ToIntegrationTable;

            //Table filter


            //Integration Table Filter
            CDSWorker.Reset();
            if CDSIntegrationMgt.GetCDSCompany(CDSCompany) then
                CDSWorker.SetFilter(CompanyId, StrSubstno('%1|%2', CDSCompany.CompanyId, EmptyGuid));
            IntegrationTableMapping.SetIntegrationTableFilter(
                GetTableFilterFromView(DATABASE::"CDS gbt_Worker", CDSWorker.TableCaption(), CDSWorker.GetView()));

            //Dependencies
            IntegrationTableMapping."Dependency Filter" := '';

            //Other Settings
            IntegrationTableMapping."Synch. Only Coupled Records" := false;
            IntegrationTableMapping."Synch. After Bulk Coupling" := true;
            IntegrationtableMapping."Create New in Case of No Match" := true;
            IntegrationTableMapping."Update-Conflict Resolution" := IntegrationTableMapping."Update-Conflict Resolution"::None;
            IntegrationTableMapping."Deletion-Conflict Resolution" := IntegrationTableMapping."Deletion-Conflict Resolution"::None;
            IntegrationTableMapping.Modify();
        end;

        //Set Match-based Coupling Criteria and other field mapping attributes
        IntegrationFieldMapping.Reset();
        IntegrationFieldMapping.SetRange("Integration Table Mapping Name", MappingName);
        If IntegrationFieldMapping.FindSet() then
            repeat
                IntegrationFieldMapping."Use For Match-Based Coupling" := false;
                if (IntegrationFieldMapping."Field No." = Employee.FieldNo("No.")) then
                    IntegrationFieldMapping."Use For Match-Based Coupling" := true;
                IntegrationFieldMapping.Modify();
            until IntegrationFieldMapping.Next() = 0;

        //---get the IntegrationTable Mapping record with the name.  if the record is not found, create the Job queue entry	
        TableMappingRec."Name" := MappingName;
        if TableMappingRec.Find('=') then begin
            // Message('About to create Job Queue entry for ' + TableMappingRec.Name);
            CreateCustomSyncJobQueueEntry(TableMappingRec);
        end;
    end;

    local procedure InsertIntegrationTableMapping(var IntegrationTableMapping: Record "Integration Table Mapping"; MappingName: Code[20]; TableNo: Integer; IntegrationTableNo: Integer; IntegrationTableUIDFieldNo: Integer; IntegrationTableModifiedFieldNo: Integer; TableConfigTemplateCode: Code[10]; IntegrationTableConfigTemplateCode: Code[10]; SynchOnlyCoupledRecords: Boolean; DirectionArg: Option; IntegrationTableType: Text[20])
    begin
        IntegrationTableMapping.CreateRecord(MappingName, TableNo, IntegrationTableNo, IntegrationTableUIDFieldNo, IntegrationTableModifiedFieldNo, TableConfigTemplateCode, IntegrationTableConfigTemplateCode, SynchOnlyCoupledRecords, DirectionArg, 'CDS');
    end;

    procedure InsertIntegrationFieldMapping(IntegrationTableMappingName: Code[20]; TableFieldNo: Integer; IntegrationTableFieldNo: Integer; SynchDirection: Option; ConstValue: Text; ValidateField: Boolean; ValidateIntegrationTableField: Boolean)
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
    begin
        IntegrationFieldMapping.CreateRecord(IntegrationTableMappingName, TableFieldNo, IntegrationTableFieldNo, SynchDirection,
            ConstValue, ValidateField, ValidateIntegrationTableField);
    end;

    local procedure GetTableFilterFromView(TableID: Integer; Caption: Text; View: Text): Text
    var
        FilterBuilder: FilterPageBuilder;
    begin
        FilterBuilder.AddTable(Caption, TableID);
        FilterBuilder.SetView(Caption, View);
        exit(FilterBuilder.GetView(Caption, false));
    end;

    local procedure CreateCustomSyncJobQueueEntry(TableMappingRec: Record "Integration Table Mapping")
    var
        JobQueueEntry: Record "Job Queue Entry";
    begin
        JobQueueEntry.SetRange("Object Type to Run", JobQueueEntry."Object Type to Run"::Codeunit);
        JobQueueEntry.SetRange("Object ID to Run", Codeunit::"Integration Synch. Job Runner");
        JobQueueEntry.SetRange("Record ID to Process", TableMappingRec.RecordId());
        JobQueueEntry.DeleteTasks();

        JobQueueEntry.InitRecurringJob(2);
        JobQueueEntry."Object Type to Run" := JobQueueEntry."Object Type to Run"::Codeunit;
        JobQueueEntry."Object ID to Run" := Codeunit::"Integration Synch. Job Runner";
        JobQueueEntry."Record ID to Process" := TableMappingRec.RecordId();
        JobQueueEntry."Run in User Session" := false;
        JobQueueEntry.Description := MappingName + ' - Dataverse synchronization job.';
        JobQueueEntry."Maximum No. of Attempts to Run" := 10;
        JobQueueEntry.Status := JobQueueEntry.Status::Ready;
        JobQueueEntry."Rerun Delay (sec.)" := 30;
        JobQueueEntry."Inactivity Timeout Period" := 5;
        JobQueueEntry."Recurring Job" := true;

        // Insert(true) alone writes the entry with Status = Ready but leaves "System Task ID"
        // empty - only codeunit 453 calls ScheduleTask(), so the job looks scheduled and never runs.
        // Base app's RecreateJobQueueEntryFromIntTableMapping is internal, hence the hand-roll,
        // but it ends the same way.
        Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Integration Mgt.", OnHasCompanyIdField, '', false, false)]
    local procedure "CDS Integration Mgt._OnHasCompanyIdField"(TableId: Integer; var HasField: Boolean)
    begin
        case TableId of
            Database::"CDS gbt_Worker":
                HasField := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", OnBeforeInsertRecord, '', false, false)]
    local procedure "Integration Rec. Synch. Invoke_OnBeforeInsertRecord"(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef; var InsertWithSystemId: Boolean)
    begin
        SetWorkerCompanyId(SourceRecordRef, DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", OnBeforeModifyRecord, '', false, false)]
    local procedure "Integration Rec. Synch. Invoke_OnBeforeModifyRecord"(IntegrationTableMapping: Record "Integration Table Mapping"; SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        SetWorkerCompanyId(SourceRecordRef, DestinationRecordRef);
    end;

    /// <summary>
    /// Stamps the current Business Central company on a Dataverse Worker before it is written.
    /// Only the Employee -> Worker direction is stamped; Employee has no company column.
    /// Nothing else in the product sets CompanyId - coupling does not - so both the Insert
    /// and the Modify event have to be covered, or Workers reach Dataverse with an empty
    /// company and the plug-in deletion guard never fires for them.
    /// </summary>
    local procedure SetWorkerCompanyId(SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    var
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
    begin
        if SourceRecordRef.Number() <> Database::Employee then
            exit;
        if DestinationRecordRef.Number() <> Database::"CDS gbt_Worker" then
            exit;
        if not CDSIntegrationMgt.IsIntegrationEnabled() then
            exit;

        CDSIntegrationMgt.SetCompanyId(DestinationRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Integration Rec. Synch. Invoke", OnAfterInsertRecord, '', false, false)]
    local procedure "Integration Rec. Synch. Invoke_OnAfterInsertRecord"(IntegrationTableMapping: Record "Integration Table Mapping"; var SourceRecordRef: RecordRef; var DestinationRecordRef: RecordRef)
    begin
        // Dataverse -> BC. The Worker is the SOURCE of this insert, so the OnBefore subscribers
        // above never see it and it would stay unstamped until a change happened to flow back.
        // Base app does exactly this for 'CRM Contact-Contact' in CDS Int. Table Subscriber.
        if (SourceRecordRef.Number() = Database::"CDS gbt_Worker") and (DestinationRecordRef.Number() = Database::Employee) then
            StampWorkerCompanyId(SourceRecordRef);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Int. Rec. Couple Invoke", OnAfterCoupleRecord, '', false, false)]
    local procedure "Int. Rec. Couple Invoke_OnAfterCoupleRecord"(IntegrationTableMapping: Record "Integration Table Mapping"; var LocalRecordRef: RecordRef; var IntegrationRecordRef: RecordRef)
    begin
        // Set Up Coupling / Match-Based Coupling of two records that both already exist.
        // Nothing is inserted, so neither insert subscriber fires - coupling alone has never
        // set CompanyId in any version of the base app.
        if (LocalRecordRef.Number() = Database::Employee) and (IntegrationRecordRef.Number() = Database::"CDS gbt_Worker") then
            StampWorkerCompanyId(IntegrationRecordRef);
    end;

    /// <summary>
    /// Writes the current Business Central company onto a Dataverse Worker that already exists.
    /// Used on the paths where the Worker is not the destination of an insert, so that every
    /// coupled Worker carries a company id regardless of which side the record was born on.
    /// </summary>
    local procedure StampWorkerCompanyId(var WorkerRecordRef: RecordRef)
    var
        CDSWorker: Record "CDS gbt_Worker";
        CDSIntegrationMgt: Codeunit "CDS Integration Mgt.";
        RecRef: RecordRef;
    begin
        if not CDSIntegrationMgt.IsIntegrationEnabled() then
            exit;

        WorkerRecordRef.SetTable(CDSWorker);
        if not IsNullGuid(CDSWorker.CompanyId) then
            exit;

        // Base app calculates the lookup-name FlowFields before modifying a Dataverse record
        // - see SetCompanyIdOnCRMContact - otherwise Dataverse rejects the modify.
        CDSWorker.SetAutoCalcFields(OwningBusinessUnitName);
        CDSWorker.Find();

        RecRef.GetTable(CDSWorker);
        CDSIntegrationMgt.SetCompanyId(RecRef);
        RecRef.Modify();

        CDSWorker.Find();
        WorkerRecordRef.GetTable(CDSWorker);
    end;
}
