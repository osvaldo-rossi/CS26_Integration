pageextension 55002 "CDS Employee Card Ext" extends "Employee Card"
{
    actions
    {
        addlast(Processing)
        {
            group(ActionGroupCDS)
            {
                Caption = 'Dataverse';
                // Gated on the Dataverse connection only - deliberately NOT
                // "CRMIntegrationEnabled or CDSIntegrationEnabled" as the base pages do.
                // This demo must run on an environment where Sales can never be installed.
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
                        CRMIntegrationManagement: Codeunit "CRM Integration Management";
                    begin
                        CRMIntegrationManagement.UpdateOneNow(Rec.RecordId);
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
                            CRMCouplingManagement: Codeunit "CRM Coupling Management";
                        begin
                            CRMCouplingManagement.RemoveCoupling(Rec.RecordId);
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
