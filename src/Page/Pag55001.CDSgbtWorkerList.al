page 55001 "CDS gbt_Worker List"
{
    ApplicationArea = All;
    Caption = 'Workers - Dataverse';
    PageType = List;
    SourceTable = "CDS gbt_Worker";
    SourceTableView = sorting(gbt_WorkerCode);
    UsageCategory = Lists;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(General)
            {
                field(gbt_WorkerCode; Rec.gbt_WorkerCode)
                {
                    ToolTip = 'Specifies the value of the Worker Code field.', Comment = '%';
                    StyleExpr = FirstColumnStyle;
                }
                field(gbt_Firstname; Rec.gbt_Firstname)
                {
                    ToolTip = 'Specifies the value of the First name field.', Comment = '%';
                }
                field(gbt_MiddleName; Rec.gbt_MiddleName)
                {
                    ToolTip = 'Specifies the value of the Middle Name field.', Comment = '%';
                }
                field(gbt_LastName; Rec.gbt_LastName)
                {
                    ToolTip = 'Specifies the value of the Last Name field.', Comment = '%';
                }
                field(gbt_JobTitle; Rec.gbt_JobTitle)
                {
                    ToolTip = 'Specifies the value of the Job Title field.', Comment = '%';
                }
                field(gbt_WorkerId; Rec.gbt_WorkerId)
                {
                    ToolTip = 'Specifies the value of the Worker field.', Comment = '%';
                }
                field(gbt_CompanyId; Rec.CompanyId)
                {
                    ToolTip = 'Specifies the value of the CompanyId field.', Comment = '%';
                }
                field(statuscode; Rec.statuscode)
                {
                    ToolTip = 'Specifies the value of the Status Reason field.', Comment = '%';
                }
                field(Coupled; Coupled)
                {
                    ToolTip = 'Specifies if the Dataverse record is coupled to BC';
                }
            }
        }
    }
    actions
    {
        area(processing)
        {
            action(ShowOnlyUncoupled)
            {
                ApplicationArea = Suite;
                Caption = 'Hide Coupled Workers';
                Image = FilterLines;
                ToolTip = 'Do not show coupled Workers.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(true);
                end;
            }
            action(ShowAll)
            {
                ApplicationArea = Suite;
                Caption = 'Show Coupled Workers';
                Image = ClearFilter;
                ToolTip = 'Show coupled Workers.';

                trigger OnAction()
                begin
                    Rec.MarkedOnly(false);
                end;
            }
        }
        area(Promoted)
        {
            group(Category_Process)
            {
                Caption = 'Process';

                actionref(ShowOnlyUncoupled_Promoted; ShowOnlyUncoupled)
                {
                }
                actionref(ShowAll_Promoted; ShowAll)
                {
                }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        CRMIntegrationRecord: Record "CRM Integration Record";
        RecordID: RecordID;
    begin
        if CRMIntegrationRecord.FindRecordIDFromID(rec.gbt_WorkerId, DATABASE::"Employee", RecordID) then
            if CurrentlyCoupledCDSWorker.gbt_WorkerId = rec.gbt_WorkerId then begin
                Coupled := 'Current';
                FirstColumnStyle := 'Strong';
                Rec.Mark(true);
            end else begin
                Coupled := 'Yes';
                FirstColumnStyle := 'Subordinate';
                Rec.Mark(false);
            end
        else begin
            Coupled := 'No';
            FirstColumnStyle := 'None';
            Rec.Mark(true);
        end;
    end;

    trigger OnInit()
    begin
        CODEUNIT.Run(CODEUNIT::"CRM Integration Management");
        Commit();
    end;

    trigger OnOpenPage()
    var
        LookupCRMTables: Codeunit "Lookup CRM Tables";
    begin
        Rec.FilterGroup(4);
        Rec.SetView(LookupCRMTables.GetIntegrationTableMappingView(DATABASE::"CDS gbt_Worker"));
        Rec.FilterGroup(0);
    end;

    var
        CurrentlyCoupledCDSWorker: Record "CDS gbt_Worker";
        Coupled: Text;
        FirstColumnStyle: Text;

    procedure SetCurrentlyCoupledCDSWorker(CDSWorker: Record "CDS gbt_Worker")
    begin
        CurrentlyCoupledCDSWorker := CDSWorker;
    end;








}
