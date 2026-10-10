pageextension 55013 "CDS Contact Card Ext" extends "Contact Card"
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
