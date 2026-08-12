# Approval-stage picture workflow

Use this reference when an NCC/NCCloud bill requires different pictures at maker, section-leader, expert-group, or other approval stages.

## Establish one mapping contract

Write the approved mapping before editing code. Keep four concepts separate:

- metadata field code, such as `def9`;
- visible template label;
- business stage, such as section leader;
- attachment directory suffix, such as `qrwztp`.

Do not infer any one from another. Existing attachment suffixes may carry historical compatibility requirements even when field codes or labels change.

Example contract:

| Stage | Field 1 | Field 2 | Suffix 1 | Suffix 2 |
|---|---|---|---|---|
| Maker | `def7` | `def8` | `bfwz` | `bfsw` |
| Expert group | `def9` | `def10` | `zjzqrwztp` | `zjzqrswtp` |
| Section leader | `def25` | `def26` | `qrwztp` | `qrswtp` |

Treat this table as an example, not a universal EMS convention. Confirm it from the current requirement and historical data.

## Trace both frontend pages

An approval bill may have separate React entries:

- normal bill page, commonly `.../sparepartscrap_details/main/index.js`;
- approval/link page, commonly `.../sparepartscrap_detailsp/main/index.js`.

Changing only the normal page does not change Approval Center. Locate page registration and runtime URLs before editing. Search both source and deployed bundles for every affected field and suffix.

For each picture field, verify:

1. `initMeta` installs a renderer.
2. Empty and non-empty states both open `NCUploader`.
3. The base bill primary key is present.
4. `billId` is exactly `billPk + suffix`.
5. The deployed `index.html` references the new hashed bundle.

## Do not mutate uploader state in place

`NCUploader` may retain its first `billId`. Directly mutating a nested uploader object can display one field while uploading into a previously opened field's directory.

Prefer a new state object and remount on directory change:

```jsx
this.setState({
    uploader: {
        ...this.state.uploader,
        visible: true,
        billId: billPk + suffix
    }
});

<NCUploader key={uploader.billId} {...uploader} />
```

Prove the upload destination in `sm_pub_filesystem`; do not trust the label or open dialog alone.

## Understand attachment storage

Picture contents and URLs are normally not stored in the bill's `def*` columns. Those fields can be template entry points only. Attachment metadata is stored in `sm_pub_filesystem`, keyed by a synthetic `filepath` prefix.

Query in two steps to avoid an expensive `LIKE` join:

```sql
SELECT pk_scrap
  FROM ems_sparepartscrap_details
 WHERE scrapcode = :scrapcode;
```

```sql
SELECT pk_doc, filepath, filedesc, filetype, isfolder, isdoc, dr
  FROM sm_pub_filesystem
 WHERE filepath LIKE :bill_pk || '%'
 ORDER BY filepath;
```

An uploader commonly creates both a folder row and a file row. Validation must require a real file, not just the folder:

```sql
NVL(dr, 0) = 0
AND isfolder = 'n'
AND isdoc = 'z'
AND filepath LIKE :bill_pk || :suffix || '%'
```

Check longer suffixes before shorter suffixes when one contains the other.

## Resolve approval stage from workflow state

Do not identify a stage from user roles alone. One user may own multiple roles. Resolve the current unfinished task for the current bill and current user, then map `activitydefid` through controlled configuration such as a custom archive.

Verify these workflow facts:

- bill primary key matches `pub_workflownote.billid`;
- current user matches `checkman`;
- task is unfinished (`dealdate IS NULL`, `ischeck = 'N'`);
- task joins the correct `pub_wf_task` row;
- activity ID maps to exactly one supported business stage.

If multiple different target stages are simultaneously pending for one user and bill, fail explicitly instead of guessing.

## Cover every backend entry

Approval can enter through more than the business Action class. Inspect:

- bill-type `checkclassname` implementations;
- `IPfBeforeAction` callbacks;
- `N_<billtype>_APPROVE` scripts;
- service submit methods;
- save/submit Actions;
- workflow gadgets only when actually bound.

Centralize suffix selection in one small rule class. Both approval callbacks and Action scripts must use the same mapping. Add a small executable test that asserts stage-to-suffix arrays.

Never assume a class is active because its source exists. Verify registration, deployed class, restart, and logs.

## Build and deploy safely

NCC runtimes may require Java 8 bytecode. Verify class major version 52 before deployment. Include anonymous processor classes such as `$1`, `$2`, and `$3`.

Check both possible class locations:

- `modules/<module>/classes/...`;
- `modules/<module>/META-INF/classes/...`.

If duplicate class names exist, synchronize them or prove class-loader precedence. A stale duplicate can silently override the patched class.

For each React page, deploy both:

- generated `index.<hash>.js`;
- matching `index.html`.

Keep old hashed bundles unless cleanup is separately authorized. Verify source/deployment hashes and confirm the deployed HTML references the new hash.

## Test matrix

Test each approval stage independently:

1. neither picture uploaded: first-picture error;
2. only first uploaded: second-picture error;
3. both uploaded: approval succeeds;
4. files land under the expected two suffixes;
5. pictures from another stage do not satisfy this stage;
6. historical attachments retain their original meaning;
7. same person holding multiple roles follows workflow task stage, not role membership;
8. Approval Center and normal bill page both show correct upload/view links.

Use a fresh bill when an earlier node is already completed. A completed workflow node cannot test that stage's interception.

## Diagnostic lessons

- Label correct, upload directory wrong: inspect runtime `attrcode`, uploader `billId`, component reuse, and `sm_pub_filesystem.filepath`.
- Upload succeeds but validation fails: distinguish folder rows from file rows; compare exact bill primary key and suffix.
- Normal page works, Approval Center fails: inspect the approval-specific React entry and its deployed HTML.
- New class appears ineffective: inspect duplicate class locations, bytecode version, registration, cache, and restart.
- `BusinessException` has a null message after deployment: check unsupported class bytecode before changing business logic.
- Database client and application appear inconsistent: verify `USER`, `CURRENT_SCHEMA`, service name, and datasource configuration; connection labels alone are insufficient.

## Patch handoff

Report patch contents by runtime target, not source extension alone:

- both React hashed bundles and matching HTML files;
- central rule class;
- validator class plus anonymous inner classes;
- active approval callback/check class;
- approval Action class when changed;
- submit/save/service classes only when maker validation changed.

State which files require NCC restart and which require browser hard refresh.
