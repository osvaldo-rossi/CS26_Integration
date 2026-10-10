tableextension 55011 "CDS Contact Ext" extends Contact
{
    fields
    {
        // Pattern A, BC side. Note for AppSource: a field added to a base table would
        // normally carry the affix from AppSourceCop.json. This project has no
        // AppSourceCop.json and the name is projected on stage, so it stays unprefixed.
        field(55010; Industry; Text[100])
        {
            Caption = 'Industry';
            DataClassification = CustomerContent;
            ToolTip = 'Specifies the industry this contact operates in. Synchronized with Dataverse.';
        }
    }
}
