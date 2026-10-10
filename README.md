# CS26_Integration

Sample code from the Community Summit NA 2026 session **"Advanced Integration Patterns Between
Business Central and Dataverse"** (Level 301).

Two custom Dataverse integrations, built the way the session argues you should build them: one
extra field on a mapping Microsoft owns, and one brand-new entity end to end — both registered
from events so that **Use Default Synchronization Setup** rebuilds them instead of wiping them.

If you only read one thing here, read
[`src/Codeunit/Cod55010.CDSContactIntegrationSetup.al`](src/Codeunit/Cod55010.CDSContactIntegrationSetup.al).
It is the whole of Pattern A: one subscriber, one call.

| | |
|---|---|
| Target | `application` 28.0.0.0 · `runtime` 17.0 |
| Object range | 55001–55150 |
| Dependencies | none — base application only |
| Dynamics 365 Sales | not required, and not used |

## What's in here

**Pattern A — add one field to a mapping Microsoft owns.** `Contact.Industry` ↔
`contact.gbt_industry`. A table extension on the Business Central side, a table extension on the
*proxy* table, and a single subscriber that appends one field mapping. No table mapping of our
own, so Microsoft's `CONTACT` mapping keeps owning the relationship.

**Pattern B — wire a custom entity end to end.** `Employee` ↔ `gbt_worker`. Our own proxy table,
our own integration table mapping with five field mappings, our own job queue entry, and the
coupling experience — lookup, deep link, Synchronize, Set Up Coupling, Delete Coupling — so a
custom entity feels the same as Customer or Contact.

### Reading order

| Start here | Why |
|---|---|
| `src/Codeunit/Cod55010.CDSContactIntegrationSetup.al` | Pattern A in ~15 lines |
| `src/Codeunit/Cod55001.CDSWorkerIntegrationSetup.al` | Pattern B: the mapping, the filters, the job queue, the coupling events, the CompanyId stamping |
| `src/Table/Tab55001.CDSgbt_Worker.al` | A generated proxy table, after the lookups were retargeted to the CDS-side tables |
| `src/PageExt/PagExt55002.CDSEmployeeCardExt.al` | The five coupling/sync actions and the two state variables that drive their visibility |
| `src/TableExt/TabExt55004.CDSEmployeeExt.al` | The `Coupled to Dataverse` FlowField |

### Every object

| Object | ID | Purpose |
|---|---|---|
| `CDS gbt_Worker` (table) | 55001 | Proxy table for the `gbt_worker` entity, `TableType = CDS` |
| `CDS gbt_Worker List` (page) | 55001 | Read-only list of live Dataverse rows inside Business Central |
| `CDS Worker Integration Setup` (codeunit) | 55001 | Pattern B |
| `CDS Contact Integration Setup` (codeunit) | 55010 | Pattern A |
| `CDS Employee Ext` (tableextension) | 55004 | `Coupled to Dataverse` FlowField on Employee |
| `CDS Employee Card Ext` / `List Ext` | 55002 / 55003 | Dataverse action group |
| `CDS Contact Ext` (tableextension) | 55011 | `Industry` on Contact |
| `CDS CRM Contact Ext` (tableextension) | 55012 | `gbt_Industry` on the `CRM Contact` proxy |
| `CDS Contact Card Ext` / `List Ext` | 55013 / 55014 | Surfaces `Industry` |
| `CS_INT_PermissionSet` | 55001 | Assignable; the proxy table, its page and both codeunits |

## The events it hangs off

Base application objects cannot be modified — that is the extension model, not a choice — so a
published event is the only hook there is. No event, no pattern. Every integration point below
exists because Microsoft raises it.

| Event | Publisher | What it does here |
|---|---|---|
| `OnAfterResetConfiguration` | CDS Setup Defaults (7204) | Creates `WORKER AL`, its five field mappings, filters and job queue entry |
| `OnAfterResetContactContactMapping` | CDS Setup Defaults (7204) | Appends `Industry` ↔ `gbt_Industry` to Microsoft's `CONTACT` mapping |
| `OnGetCDSTableNo` | CRM Setup Defaults (5334) | Maps `Employee` to its proxy table so coupling works |
| `OnAddEntityTableMapping` | CRM Setup Defaults (5334) | Registers the entity **logical name** `gbt_worker` for *both* table IDs — this is what makes the deep link resolve |
| `OnLookupCRMTables` | Lookup CRM Tables (5332) | Supplies the lookup page behind *Set Up Coupling* |
| `OnHasCompanyIdField` | CDS Integration Mgt. (7200) | Declares that the proxy table carries a CompanyId |
| `OnBeforeInsertRecord` · `OnBeforeModifyRecord` | Integration Rec. Synch. Invoke (5345) | Stamps CompanyId on the Dataverse row being written |
| `OnAfterInsertRecord` | Integration Rec. Synch. Invoke (5345) | Stamps CompanyId on the *source* row when the record came from Dataverse |
| `OnAfterCoupleRecord` | Int. Rec. Couple Invoke (5361) | Stamps CompanyId on manual and match-based couplings |

## Four things that cost us time

Worth knowing before you write your own, because none of them produce a useful error message.

**1. `CreateRecord` is what makes mappings reconcile — not the field-mapping helper.**
`IntegrationTableMapping.CreateRecord` opens with `if Get(Name) then Delete(true)`, and table
5335's `OnDelete` deletes that mapping's field mappings. `IntegrationFieldMapping.CreateRecord`
has no duplicate check at all. So register from an event that recreates the parent — if you
register from one that doesn't, you accumulate duplicates on every reset.

**2. `Insert(true)` does not schedule a job queue entry.** It writes a row with `Status = Ready`
and an empty **System Task ID**, and the job never runs. Finish with
`Codeunit.Run(Codeunit::"Job Queue - Enqueue", JobQueueEntry)`. Base app's
`RecreateJobQueueEntryFromIntTableMapping` is `internal`, which is why this repo hand-rolls it.

**3. The CompanyId field must be called `CompanyId` in AL.**
`CDS Integration Impl.FindCompanyIdField` matches on the AL field name and the GUID type. The
`ExternalName` is irrelevant. Four paths set it — insert, modify, inbound insert, and coupling —
and the base application clears it on uncouple without any code of ours.

**4. The coupled indicator must be called `Coupled to Dataverse`.**
`CRM Integration Management.FindCoupledToCRMField` looks that field up *by name*.

## Try it yourself

1. Set up the Dataverse connection in a **Business Central 28.x sandbox**.
2. In Dataverse, create a table **`gbt_worker`** with columns `gbt_workercode`, `gbt_firstname`,
   `gbt_middlename`, `gbt_lastname`, `gbt_jobtitle` and a `gbt_companyid` GUID column, and add a
   **`gbt_industry`** text column to the stock `contact` table.
3. Clone this repo, open it in VS Code with the AL Language extension, add a `.vscode/launch.json`
   for your sandbox, download symbols and publish.
4. **Dataverse Connection Setup → Use Default Synchronization Setup.** Publishing alone does
   nothing visible; this is the step that creates the mappings.
5. Assign `CS_INT_PermissionSet`, then open **Workers – Dataverse** and the **Employees** list.

Then the experiment the session is built around:

6. Open **Integration Table Mappings → WORKER AL → Fields**. Count them: five.
7. Run **Use Default Synchronization Setup** twice more and count again. Still five.
8. Now build the same Employee ↔ `gbt_worker` mapping through **New Table Mapping** instead —
   you have to delete `WORKER AL` first, because the wizard skips tables that are already mapped
   — reset three times, and compare the two field lists.

That last comparison is the argument of the whole session.

## Caveats

- **This is demo code.** Comments explain *why* a line exists rather than what it does, because
  it was written to be read from a stage.
- **`WORKER AL` is deliberately permissive** so the demo keeps working:
  `Synch. Only Coupled Records = false`, `Create New in Case of No Match = true`, a two-minute
  recurrence, and an integration-table filter of `CompanyId = <company> | <empty GUID>`. Tighten
  all four before you copy this into anything real.
- **The `CRM` prefix is history, not function.** `CRM Setup Defaults`, `Lookup CRM Tables` and
  `CRM Integration Record` are named for the Dynamics CRM era and serve any Dataverse
  integration. Nothing here needs Dynamics 365 Sales.
- To regenerate the proxy table against a different schema, use the AL Table Proxy Generator —
  now distributed as the NuGet package
  `Microsoft.Dynamics.BusinessCentral.Development.Tools.Altpgen`, no longer inside the AL VS Code
  extension.

## Licence

MIT — see [LICENSE](LICENSE). Take it, change it, ship it; just keep the copyright notice.

## Questions

Osvaldo B. Rossi · Gambito · [linkedin.com/in/osvaldo-b-rossi](https://www.linkedin.com/in/osvaldo-b-rossi)

Slides and the full step-by-step walkthrough are on the Community Summit session page.
