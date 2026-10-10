pageextension 55014 "CDS Contact List Ext" extends "Contact List"
{
    layout
    {
        addafter("Job Title")
        {
            field(Industry; Rec.Industry)
            {
                ApplicationArea = All;
                ToolTip = 'Specifies the industry this contact operates in. Synchronized with Dataverse.';
            }
        }
    }
}
