# PHANTOM cycle 04 — repository delivery and native compile gate

## Implementation

The owning account jajabinkio-commits is now connected, with push permission on jajabinkio-commits/qUnleashed. Prepare a feature branch and draft PR; retain main unchanged. Add a pull_request trigger targeting main to the existing unsigned macOS compile workflow, since workflow_dispatch alone requires a workflow on the default branch.

Local tested source remains bc96ccd, based on audited upstream 975e3ebd810091a31212abb2998ffb7628363069. Destination main was 90ca7621cdaf56c996e2fddacf126fa71d64d6f5. Git merge-tree found no conflicts with the newer upstream localization fixes. Do not label those newer fixes tested in the PHANTOM branch snapshot.

## Evidence and limitations

Prior frozen-source checks: 1,914 application tests passed, five skipped; analyzer and format clean; Linux Dart/assets bundle compiled (cycle 03). This cycle changes only workflow triggering and delivery documentation; workflow lint and whitespace checks are required. No native iOS compile, signing or hardware success is claimed until observed. Actions permission-settings lookup returned HTTP 403 (integration restriction); repository push permission is separately confirmed. An automatic PR check may still need GitHub's fork workflow approval.

Exact changed files: .github/workflows/phantom-ios.yml, docs/IMPLEMENTATION_CYCLE_04.md, docs/evidence-ledger.md, docs/RELEASE_READINESS.md. Next executable task: upload feature branch, open draft PR and inspect available checks for the unsigned Mac compile. Source workflow uses no Apple keys, private provider key or publishing step.

## Observed delivery results

- actionlint 1.7.12: workflow passed, exit 0. git diff --check passed.
- Git HTTPS push of the new feature branch: HTTP 403, permission denied to jajabinkio-commits.
- Independent connector create-branch call: HTTP 403, Resource not accessible by integration. No branch was created, no PR opened and no remote native build started. These are GitHub integration authorization errors, not local approval-review rejections.
- The repository metadata push=true describes account permission, but actual authenticated write operations were denied. Do not treat metadata as proof of effective credential write scope. Inspect the GitHub app installation/repository authorization before retrying; platform connection support may be required if no write grant is offered.
- Local code stays committed. Main is unchanged remotely. Source archive prepared at /workspace/PHANTOM-cycle-04.zip including recursive tracked source and an incremental commit patch series.
