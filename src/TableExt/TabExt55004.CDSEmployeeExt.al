tableextension 55004 "CDS Employee Ext" extends Employee
{
    fields
    {
        // Same shape as base app's "Coupled to Dataverse" on Contact / Customer / Vendor
        // (a FlowField since 26.0 - the older maintained "Coupled to CRM" flag is Removed).
        // Nothing to keep in sync: the coupling table IS the source of truth.
        field(55001; "Coupled to Dataverse"; Boolean)
        {
            FieldClass = FlowField;
            CalcFormula = exist("CRM Integration Record" where("Integration ID" = field(SystemId), "Table ID" = const(Database::Employee)));
            Caption = 'Coupled to Dataverse';
            ToolTip = 'Specifies that the employee is coupled to a worker in Dataverse.';
            Editable = false;
        }
    }
}
