/// <summary>
/// Pattern A - add one field to a mapping Microsoft already owns.
///
/// This is the whole pattern. No table mapping is created here: CONTACT already exists,
/// Microsoft creates it, and we only append one field mapping to it.
///
/// It reconciles across every Use Default Synchronization Setup, and the reason is worth
/// knowing. ResetContactContactMapping calls IntegrationTableMapping.CreateRecord at the
/// top, which does "if Get(Name) then Delete(true)"; table 5335's OnDelete then runs
/// IntegrationFieldMapping.DeleteAll for that name. Only after that clean slate does it
/// raise OnAfterResetContactContactMapping. So the subscriber below always lands on an
/// empty set and can never accumulate duplicates.
///
/// IntegrationFieldMapping.CreateRecord itself has no duplicate check at all - it is
/// Init / "No." := 0 / Insert on an autoincrement key. Subscribe to an event that does
/// NOT recreate the parent and this same call accumulates copies on every reset.
/// </summary>
codeunit 55010 "CDS Contact Integration Setup"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"CDS Setup Defaults", OnAfterResetContactContactMapping, '', false, false)]
    local procedure "CDS Setup Defaults_OnAfterResetContactContactMapping"(IntegrationTableMappingName: Code[20])
    var
        IntegrationFieldMapping: Record "Integration Field Mapping";
        Contact: Record Contact;
        CRMContact: Record "CRM Contact";
    begin
        IntegrationFieldMapping.CreateRecord(
            IntegrationTableMappingName,
            Contact.FieldNo(Industry),
            CRMContact.FieldNo(gbt_Industry),
            IntegrationFieldMapping.Direction::Bidirectional,
            '', true, false);
    end;
}