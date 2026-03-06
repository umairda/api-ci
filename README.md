# Jenkins + Kubernetes + Make + GCC + Google Test + GCOV Demo

This project is a simple C++ HTTP API with one endpoint:

- `GET /health` -> `{"status":"ok"}`

It demonstrates:

- Build with `make` + `gcc`
- Unit tests with `google test`
- Coverage with `gcov`
- Containerization with Docker
- Kubernetes deployment to `alpha`, `beta`, `prod`
- Jenkins pipeline with environment stages

## Prerequisites

- `g++` / `gcc`
- `make`
- `gcov`
- Google Test headers/libs (`gtest`)
- Docker Desktop running
- `kind`
- `kubectl`

Install Google Test:

```bash
# Ubuntu/Debian
sudo apt-get update && sudo apt-get install -y libgtest-dev cmake

# macOS (Homebrew)
brew install googletest
```

## Run API locally

```bash
make all
./build/health_api
```

In another shell:

```bash
curl -i http://localhost:8080/health
```

## Unit tests and coverage

```bash
make test
./scripts/run_coverage.sh
```

Coverage gate in `scripts/run_coverage.sh` requires at least 80% line coverage.

## Docker (local app test)

```bash
make docker-build
make docker-run
make docker-test
make docker-stop
```

## Local CI/CD stack (kind + local registry + Jenkins)

This project includes scripts and `make` targets to stand up a complete local pipeline environment.

Start stack:

```bash
make local-ci-up
```

This creates:

- kind cluster: `jenkins-kube`
- local registry: `localhost:5001`
- Jenkins container: `http://localhost:8081`

Get Jenkins admin password:

```bash
make local-ci-password
```

Set up a dedicated Jenkins agent (recommended):

1. In Jenkins UI:
   - `Manage Jenkins` -> `Nodes` -> `New Node`
   - Name: `local-agent`
   - Type: `Permanent Agent`
   - Remote root directory: `/home/jenkins/agent`
   - Labels: `local-agent`
   - Launch method: `Launch agent by connecting it to the controller`
   - Save and copy the generated secret from the node page
2. Start agent container from this repo:
   ```bash
   JENKINS_SECRET=<copied-secret> make jenkins-agent-up
   ```
3. Pipeline now runs on this agent label (`local-agent`) instead of the Jenkins controller.

Stop and remove everything:

```bash
make local-ci-down
```

Stop agent only:

```bash
make jenkins-agent-down
```

If `make local-ci-up` fails with a kind kubelet/control-plane timeout:

1. Ensure Docker Desktop is running and has at least 4 CPUs and 6+ GB memory.
2. Retry with pinned node image (already defaulted in script):
   ```bash
   make local-ci-down
   KIND_NODE_IMAGE=kindest/node:v1.30.8 make local-ci-up
   ```

## Configure Jenkins job

1. Open Jenkins at `http://localhost:8081`.
2. Install suggested plugins.
3. Create a **Pipeline** job.
4. Point it to this repo and use [Jenkinsfile](./Jenkinsfile).
5. Run with defaults:
   - `IMAGE_REPO=localhost:5001/health-api`
   - `K8S_CONTEXT=kind-jenkins-kube`

Pipeline stages run `Alpha -> Beta -> Prod`. Each stage:

- builds (`make all`)
- runs tests (`make test`)
- runs coverage gate (`./scripts/run_coverage.sh`)
- builds and pushes image to local registry
- deploys Kubernetes manifest and waits for rollout

## Kubernetes manifests

Manifests are in `k8s/`:

- `k8s/alpha.yaml` -> namespace `health-alpha`
- `k8s/beta.yaml` -> namespace `health-beta`
- `k8s/prod.yaml` -> namespace `health-prod`

Image names are injected at deploy time by Jenkins by replacing `REPLACE_IMAGE`.
