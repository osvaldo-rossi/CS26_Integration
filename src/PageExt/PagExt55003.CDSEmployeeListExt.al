pageextension 55003 "CDS Employee List Ext" extends "Employee List"
{
    layout
    {
        addlast(Control1)
        {
            field("Coupled to Dataverse"; Rec."Coupled to Dataverse")
            {
                ApplicationArea = BasicHR;
                Visible = CDSIntegrationEnabled;
            }
        }
    }

    actions
    {
        addlast(processing)
        {
            group(ActionGroupCDS)
            {
                Caption = 'Dataverse';
                // See "CDS Employee Card Ext" - Dataverse only, never the Sales layer.
                Visible = CDSIntegrationEnabled;

                action(CDSGotoWorker)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Worker';
                    Image = CoupledContactPerson;
                    ToolTip = 'Open the coupled Dataverse worker.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowCRMEntityFromRecordID(Rec.RecordId);
                    end;
                }
                action(CDSSynchronizeNow)
                {
                    AccessByPermission = TableData "CRM Integration Record" = IM;
                    ApplicationArea = BasicHR;
                    Caption = 'Synchronize';
                    Image = Refresh;
                    ToolTip = 'Send or get updated data to or from Dataverse.';

                    trigger OnAction()
                    var
                        Employee: Record Employee;
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        EmployeeRecordRef: RecordRef;
                    begin
                        CurrPage.SetSelectionFilter(Employee);
                        // SetSelectionFilter only filters - it does not position on a record.
                        // Without Next(), Employee.RecordId has no primary key and
                        // CRM Integration Management.GetRecordRef fails with "The record is not open."
                        Employee.Next();

                        if Employee.Count() = 1 then
                            CRMIntegrationManagement.UpdateOneNow(Employee.RecordId)
                        else begin
                            EmployeeRecordRef.GetTable(Employee);
                            CRMIntegrationManagement.UpdateMultipleNow(EmployeeRecordRef);
                        end;
                    end;
                }
                group(CDSCoupling)
                {
                    Caption = 'Coupling', Comment = 'Coupling is a noun';
                    Image = LinkAccount;
                    ToolTip = 'Create, change, or delete a coupling between the employee and a Dataverse worker.';

                    action(ManageCDSCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = BasicHR;
                        Caption = 'Set Up Coupling';
                        Image = LinkAccount;
                        ToolTip = 'Create or modify the coupling to a Dataverse worker.';

                        trigger OnAction()
                        var
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                        begin
                            CRMIntegrationManagement.DefineCoupling(Rec.RecordId);
                        end;
                    }
                    action(MatchBasedCDSCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = IM;
                        ApplicationArea = BasicHR;
                        Caption = 'Match-Based Coupling';
                        Image = CoupledContactPerson;
                        ToolTip = 'Couple employees to Dataverse workers by matching the employee number to the worker code.';

                        trigger OnAction()
                        var
                            Employee: Record Employee;
                            CRMIntegrationManagement: Codeunit "CRM Integration Management";
                            EmployeeRecordRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Employee);
                            EmployeeRecordRef.GetTable(Employee);
                            CRMIntegrationManagement.MatchBasedCoupling(EmployeeRecordRef);
                        end;
                    }
                    action(DeleteCDSCoupling)
                    {
                        AccessByPermission = TableData "CRM Integration Record" = D;
                        ApplicationArea = BasicHR;
                        Caption = 'Delete Coupling';
                        Enabled = CDSIsCoupledToRecord;
                        Image = UnLinkAccount;
                        ToolTip = 'Delete the coupling to a Dataverse worker.';

                        trigger OnAction()
                        var
                            Employee: Record Employee;
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                            EmployeeRecordRef: RecordRef;
                        begin
                            CurrPage.SetSelectionFilter(Employee);
                            EmployeeRecordRef.GetTable(Employee);
                            CRMCouplingManagement.RemoveCoupling(EmployeeRecordRef);
                        end;
                    }
                }
                action(ShowCDSLog)
                {
                    ApplicationArea = BasicHR;
                    Caption = 'Synchronization Log';
                    Image = Log;
                    ToolTip = 'View integration synchronization jobs for the employee table.';

                    trigger OnAction()
                    var
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.ShowLog(Rec.RecordId);
                    end;
                }
            }
        }
        addlast(Promoted)
        {
            group(Category_CDS)
            {
                Caption = 'Dataverse';

                actionref(CDSGotoWorker_Promoted; CDSGotoWorker) { }
                actionref(CDSSynchronizeNow_Promoted; CDSSynchronizeNow) { }
                actionref(ManageCDSCoupling_Promoted; ManageCDSCoupling) { }
                actionref(MatchBasedCDSCoupling_Promoted; MatchBasedCDSCoupling) { }
                actionref(DeleteCDSCoupling_Promoted; DeleteCDSCoupling) { }
                actionref(ShowCDSLog_Promoted; ShowCDSLog) { }
            }
        }
    }

    trigger OnOpenPage()
    var
        CRMIntegrationManagement: Codeunit "CRM Integration Management";
    begin
        CDSIntegrationEnabled := CRMIntegrationManagement.IsCDSIntegrationEnabled();
    end;

    trigger OnAfterGetCurrRecord()
    var
        CRMCouplingManagement: Codeunit "CRM Coupling Management";
    begin
        if CDSIntegrationEnabled then
            CDSIsCoupledToRecord := CRMCouplingManagement.IsRecordCoupledToCRM(Rec.RecordId);
    end;

    var
        CDSIntegrationEnabled: Boolean;
        CDSIsCoupledToRecord: Boolean;
}
