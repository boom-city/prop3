### Unified Synchronization Workflow

The entire synchronization process is managed by a single, unified GitHub Actions workflow. This approach provides a centralized view of all automation. The workflow is designed to be robust and efficient, using dependent jobs and conditional logic to execute the correct tasks based on the trigger event.

- **Triggers**:
  - **`on: push`**: When developers push to the monorepo's `main` branch, the *Upstream Sync* jobs are triggered.
  - **`on: schedule`**: A cron schedule (e.g., hourly) triggers the *Downstream Sync* job.
  - **`on: workflow_dispatch`**: Allows for manual runs of the *Downstream Sync* job.

---

### Upstream Synchronization Jobs (On Push)

This sequence of dependent jobs is responsible for distributing changes from the monorepo out to the various sub-repositories. It runs only when `github.event_name == 'push'`.

#### Job 1: Push Analysis & Execution Planning

This initial job acts as the workflow's control center. It analyzes the incoming changes from the push and generates a precise execution plan.

The process is as follows:

1.  **Identify Changed Files**: Inspects the push event's commits to find all modified files.
2.  **Map to Subrepos**: Cross-references changed files with `subrepo-config.json` to identify affected subrepos.
3.  **Assess Affected Subrepos**:
    *   **Bootstrap Check**: To determine if a subrepo requires initialization, the workflow first verifies if its remote repository exists (as defined in `config.subrepo.remote`) and if a local `.git` directory is present at its prefix path. A subrepo is then marked for the "bootstrap" action if its remote repository is either missing or empty.
    *   **Divergence Check**: Flags existing subrepos where the remote `HEAD` has changed unexpectedly, preventing overwrites.
4.  **Generate Execution Plan**: Outputs an "Execution Matrix" detailing the required action (`bootstrap`, `sync`, or `report_divergence`) for each affected subrepo.

#### Job 2: Main Workflow - The Split & Sync

This is the core execution job, running as a parallel matrix for each subrepo flagged for a `sync` or `bootstrap` action in the execution plan.

- **For New Subrepos (`action: bootstrap`)**:
  - Creates the remote repository using the `gh` CLI if it does not already exist.
  - Initializes a temporary local `.git` repository within the subrepo's prefix directory on the runner to prepare it for the split.
  - Performs a `git subtree split`.
  - Pushes the complete history directly to the `main` branch of the new sub-repository.
- **For Existing Subrepos (`action: sync`)**:
  - Performs a `git subtree split`.
  - Pushes the new commits to a temporary branch on the sub-repository.
  - Creates a Pull Request for review.

#### Job 3: Post-Sync Cleanup

This job runs only after all matrix jobs in the previous stage succeed. It creates a single Pull Request in the monorepo to remove the directories that have been successfully split and pushed. This provides a safe, reviewable way to clean up the monorepo.

#### Job 4: Post-Checks & Summary

The final job in the push sequence. It validates that all PRs were created successfully and posts a summary comment on the triggering commit, linking to the new subrepo PRs and the monorepo cleanup PR.

---

### Downstream Synchronization Job (On Schedule / Manual)

This standalone job is responsible for pulling changes from the sub-repositories back into the monorepo. It runs only when `github.event_name == 'schedule'` or `github.event_name == 'workflow_dispatch'`.

The process is as follows:

1.  **Iterate Subrepos**: The workflow loops through every sub-repository defined in `subrepo-config.json`.
2.  **Pull Changes**: For each subrepo, it runs `git subtree pull` to fetch history and apply it to the correct prefix directory in the monorepo.
3.  **Commit & Propose Changes**: If new changes are pulled, the workflow commits them to a new branch and opens a single Pull Request to the monorepo's `main` branch.
4.  **Conflict Handling**: If a `subtree pull` results in a merge conflict, the job will fail, and the logs will indicate the need for manual developer intervention to resolve the conflict.