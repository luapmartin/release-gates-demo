# Release gates demo

A GitHub Actions workflow that releases with humans in the loop: build, QA spot
check, publish, announce. Each step is a job gated by a GitHub environment, so
the run pauses before it until a reviewer approves, and stops if they reject.

The workflow is [`.github/workflows/release.yml`](.github/workflows/release.yml).
It only prints what it would do; the gates are the point.

## How a gate works

A job that names an `environment` with required reviewers does not start until
one of them approves it on the run page. The reviewer sees which job is waiting,
can leave a comment, and chooses **Approve** or **Reject**.

- Approve: the job runs.
- Reject: the job fails and every job that `needs` it is skipped.

A run can wait up to 30 days for an approval. An environment can list up to 6
reviewers (users or teams); one approval is enough. Environments with
protection rules are free on public repositories and need a paid plan on
private ones.

## Environments to set up

Create these four environments, each with you (or your team) as required
reviewer:

| Environment  | Gates          | Approving means                           |
|--------------|----------------|-------------------------------------------|
| `dev`        | the build      | start building this version               |
| `qa`         | the spot check | QA looked at the build and it is fine     |
| `production` | the publish    | put it on the GitHub release and the site |
| `social`     | the announce   | post about it                             |

### In the web UI

1. Settings > Environments > **New environment**, name it `dev`.
2. Tick **Required reviewers**, add yourself, save.
3. To approve your own runs, untick **Prevent self-review** (it is ticked by
   default).
4. Leave **Deployment branches and tags** on "No restriction" for the demo.
5. Repeat for `qa`, `production` and `social`.

### With the GitHub CLI

Same result from a terminal. Find your user id with `gh api user --jq .id`.

```sh
for env in dev qa production social; do
  gh api --method PUT "repos/OWNER/REPO/environments/${env}" \
    --input - <<EOF
{ "reviewers": [{ "type": "User", "id": YOUR_USER_ID }],
  "prevent_self_review": false,
  "deployment_branch_policy": null }
EOF
done
```

An environment that is not created beforehand is created on first use with no
protection, and the job runs straight through, so set them up before the first
run.

## Running it

Actions > Release > **Run workflow**, enter a version, run. Then:

1. The run shows `Build` as "Waiting" with a **Review deployments** button.
   Approve `dev`. The build runs and uploads a small artifact.
2. `QA spot check` waits. Download the artifact from the run page if you want
   to look at it, then approve or reject `qa`.
3. `Publish` and `Announce` wait in turn.

Try one run approving everything, and one rejecting at `qa`: the QA job fails,
and publish and announce are skipped.

## What does not fit a gate

A gate is approve or reject, nothing more. If the decision has more outcomes,
such as "minor issues: publish to the safe places only", use one of these:

- One environment per outcome, each gating its own job. The reviewer approves
  the job that applies and rejects the other.
- A second workflow started by hand with an input that carries the decision.
- Reading the approval comment through the API (`GET
  /repos/OWNER/REPO/actions/runs/RUN_ID/approvals`) in a later job.

Other things an environment can do: delay a job with a wait timer, restrict
which branches or tags may deploy, and hold secrets that only its job can read,
so social media tokens live in `social` and the build job never sees them.
