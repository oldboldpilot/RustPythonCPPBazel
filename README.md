# RustPythonCPPBazel

Multiparadigm workspace: **Bazel**, **C++23** (nanobind extension), **Rust** (PyO3), **Python**, and **SWI-Prolog** solvers (Sudoku + maze).

## GitHub, Gitea, and NAS

Use **GitHub** as `origin` for the public tree. Optionally **mirror to Gitea** and **rsync a copy to a NAS** (or any SSH/rsync host). Put URLs, tokens, and host paths in **`config/.env`** (gitignored—never commit it).

1. **`cp config/.env.example config/.env`**
2. Edit **`config/.env`**: set **`GITEA_PUSH_URL`** if you want a second remote named `gitea`. For NAS, optional overrides **`NAS_BACKUP_HOST`**, **`NAS_BACKUP_PATH`**, **`NAS_SSH_USER`** (defaults match **`config/update_policy.txt`**).

After tests pass:

```bash
bash scripts/push_remotes.sh    # pushes origin, then gitea if GITEA_PUSH_URL is set
bash scripts/backup_to_nas.sh   # rsync via SSH per update_policy (see script for defaults)
```

NAS sync follows **`config/update_policy.txt`**: ensure the NAS mount is available and **passwordless SSH** to **`oluwasanmi-fedora-server`** works; backup directory defaults to **`/home/muyiwa/PrimaryNAS/DataFolder/PycharmProjects/RustPythonCPPBazel`** on that host.

SSH keys or other credentials are read from your environment / `config/.env` as you configure them; the scripts do not print secret values.

## Policies (local Git, copied to NAS)

**`config/update_policy.txt`** and **`config/cpp_details.txt`** are gitignored (not on GitHub). Keep them locally; **`scripts/backup_to_nas.sh`** always **rsyncs them to the NAS** under **`config/`** when they exist, so the NAS mirror has your policy and C++ notes.

## Build and test

```bash
bazel build //...
bazel test //:all_tests //cpp:cppm_demo_test
```

## Demo

```bash
bazel run //python:demo
```
