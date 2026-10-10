permissionset 55001 CS_INT_PermissionSet
{
    Caption = 'Community Summit 2026 - Dataverse Integration';
    Assignable = true;
    Permissions = tabledata "CDS gbt_Worker" = RIMD,
        table "CDS gbt_Worker" = X,
        page "CDS gbt_Worker List" = X,
        codeunit "CDS Worker Integration Setup" = X,
        codeunit "CDS Contact Integration Setup" = X;
}
