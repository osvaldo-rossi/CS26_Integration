// Pattern A, Dataverse side. This is what altpgen emits when the proxy table for the
// entity already exists in the base application: not a new table, a table EXTENSION
// carrying only the new column.
//
//   altpgen.exe -project:. -packagecachepath:.\.alpackages -serviceuri:<env>
//               -entities:contact -baseid:55000
//
// The ExternalName below must match the Dataverse column's LOGICAL name exactly.
tableextension 55012 "CDS CRM Contact Ext" extends "CRM Contact"
{
    fields
    {
        field(55011; gbt_Industry; Text[100])
        {
            ExternalName = 'gbt_industry';
            ExternalType = 'String';
            Caption = 'Industry';
            Description = 'Industry the contact operates in.';
        }
    }
}
