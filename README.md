# CMS – Fastify + TypeScript

> GitLab CI/CD Pipeline တစ်ဆင့်ချင်းစီ တည်ဆောက်မှတ်တမ်း

---

## 🗂️ Project Overview

| Item | Detail |
|------|--------|
| Framework | Fastify (TypeScript) |
| Test Runner | Jest |
| Linter | ESLint + Prettier |
| CI/CD | GitLab CI |

---

## 🚀 Pipeline Overview

```
npm install / cache
       ↓
 ESLint / Test
       ↓
    Build
       ↓
Docker Image Build
```

---

## 📋 Pipeline မှတ်တမ်း (Commit by Commit)

---

### ✅ Step 1 — npm install & Cache Stage
**Commit:** `ci: Step 1 - npm install & cache stage setup`

#### ဘာတွေ လုပ်ခဲ့သလဲ
- Global Docker image ကို `node:18-alpine` သို့ ပြောင်းခဲ့တယ်
- `stages:` ကို pipeline plan အတိုင်း ပြန်ပြင်ခဲ့တယ်: `install → lint → test → build → dockerize`
- `npm install` job ကို `npm:install` ဟု rename လုပ်ခဲ့တယ်
- `npm install` အစား `npm ci` ကို သုံးခဲ့တယ်
- Cache key ကို `$CI_COMMIT_REF_SLUG` (branch name) နဲ့ ချိတ်ဆက်ခဲ့တယ်
- Cache `policy: push` သတ်မှတ်ခဲ့တယ် (upload only)

#### ဘာကြောင့် ဒီလိုလုပ်ရသလဲ

| ရွေးချယ်မှု | အကြောင်းပြချက် |
|-------------|----------------|
| `node:18-alpine` | npm ပါနေပြီးသားဖြစ်လို့ `apk add npm` မလုပ်ရ → pipeline မြန်တယ် |
| `npm ci` | `package-lock.json` ကို တိတိကျကျ follow လုပ်တယ် → reproducible builds |
| `policy: push` | ဒီ job က cache ကို **upload** ပဲလုပ်တယ်၊ download မလုပ်ဘဲ မြန်တယ် |
| `$CI_COMMIT_REF_SLUG` | Branch တစ်ခုချင်းစီ သီးသန့် cache ရတယ် → branch တွေ မထပ်ဆင့်ဘဲ clean |

#### `.gitlab-ci.yml` (Step 1 အနေအထား)

```yaml
image: node:18-alpine

stages:
  - install
  - lint
  - test
  - build
  - dockerize

npm:install:
  stage: install
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - node_modules/
    policy: push
  script:
    - echo "📦 Installing npm dependencies..."
    - npm ci
```

---

---

### ✅ Step 2 — ESLint + Jest Test Stages
**Commit:** `ci: Step 2 - ESLint lint stage & Jest test stage`

#### ဘာတွေ လုပ်ခဲ့သလဲ
- `eslint` job ကို `lint` stage မှာ ထည့်ခဲ့တယ်
- `unit:test` job ကို `test` stage မှာ ထည့်ခဲ့တယ်
- `when: manual` ကို ဖြုတ်ပြီး auto-run ဖြစ်အောင် ပြင်ခဲ့တယ်
- Cache `policy: pull` သတ်မှတ်ခဲ့တယ် (Step 1 ကလုပ်ထားတဲ့ cache ကို download ပဲ လုပ်)
- Coverage report ကို `artifacts` အဖြစ် 7 ရက် သိမ်းထားအောင် သတ်မှတ်ခဲ့တယ်

#### ဘာကြောင့် ဒီလိုလုပ်ရသလဲ

| ရွေးချယ်မှု | အကြောင်းပြချက် |
|-------------|----------------|
| `when: manual` ဖြုတ်တယ် | CI/CD ရဲ့ အဓိကရည်ရွယ်ချက်က auto-run — manual ဆိုရင် အဓိပ္ပာယ်မရှိ |
| `policy: pull` | Step 1 က upload လုပ်ထားပြီ၊ ဒီ job တွေ download ပဲ လုပ်ရတယ် → မြန်တယ် |
| `artifacts: when: always` | Test fail ဖြစ်လည်း coverage report ကြည့်နိုင်အောင် |
| lint → test order | Lint မအောင်ရင် test မပြေး → fail fast principle |

#### `.gitlab-ci.yml` (Step 2 ထည့်ပြီးနောက်)

```yaml
eslint:
  stage: lint
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - node_modules/
    policy: pull
  script:
    - echo "🔍 Running ESLint..."
    - npx eslint . --ext .ts

unit:test:
  stage: test
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - node_modules/
    policy: pull
  script:
    - echo "🧪 Running Jest unit tests..."
    - npm test
  artifacts:
    when: always
    paths:
      - coverage/
    expire_in: 7 days
```

---

---

### ✅ Step 3 — TypeScript Build Stage
**Commit:** `ci: Step 3 - TypeScript build stage`

#### ဘာတွေ လုပ်ခဲ့သလဲ
- `ts:build` job ကို `build` stage မှာ ထည့်ခဲ့တယ်
- `npm run build:ts` (= `tsc`) ဖြင့် `src/*.ts` → `dist/*.js` compile လုပ်တယ်
- `dist/` folder ကို artifact အဖြစ် 1 ရက် သိမ်းထားပြီး နောက် stage ကို pass လုပ်တယ်
- Cache `policy: pull` သုံးတယ် (node_modules download ပဲ)

#### ဘာကြောင့် ဒီလိုလုပ်ရသလဲ

| ရွေးချယ်မှု | အကြောင်းပြချက် |
|-------------|----------------|
| `npm run build:ts` | `tsc` ကို run တာ — TypeScript → JavaScript compile လုပ်တယ် |
| `artifacts: dist/` | Docker build stage က ဒီ `dist/` ကို လိုတယ် — pass မလုပ်ရင် Docker stage မှာ files မရှိဘူး |
| `expire_in: 1 day` | Docker build ပြီးရင် မလိုတော့တဲ့ temporary artifact |

#### `.gitlab-ci.yml` (Step 3 ထည့်ပြီးနောက်)

```yaml
ts:build:
  stage: build
  cache:
    key: "$CI_COMMIT_REF_SLUG"
    paths:
      - node_modules/
    policy: pull
  script:
    - echo "🔨 Compiling TypeScript..."
    - npm run build:ts
  artifacts:
    paths:
      - dist/
    expire_in: 1 day
```

---

---

### ✅ Step 4 — Docker Image Build & Push Stage
**Commit:** `ci: Step 4 - Docker image build & push stage`

#### ဘာတွေ လုပ်ခဲ့သလဲ
- `Dockerfile` (multi-stage) ကို ဆောက်ခဲ့တယ်
- `docker:build` job ကို `dockerize` stage မှာ ထည့်ခဲ့တယ်
- GitLab Container Registry (`$CI_REGISTRY`) ကို push လုပ်အောင် configure လုပ်ခဲ့တယ်
- `rules: if: main` — main branch push တိုင်းသာ Docker build ဖြစ်မယ်
- Image ကို commit SHA tag နဲ့ `latest` tag နှစ်ခုတပ်တယ်

#### ဘာကြောင့် ဒီလိုလုပ်ရသလဲ

| ရွေးချယ်မှု | အကြောင်းပြချက် |
|-------------|----------------|
| Multi-stage Dockerfile | builder stage မှာ devDependencies မပါပဲ production deps ပဲ ယူ → image size သေး |
| `docker:24-dind` service | CI runner ထဲမှာ Docker engine run ဖို့ Docker-in-Docker လိုတယ် |
| `$CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA` | Commit SHA tag — ဘယ် commit မှ build လာတာ ဆိုတာ track လုပ်နိုင်တယ် |
| `rules: if: main` | Feature branch တိုင်း Docker build မဖြစ်ဘဲ main push တိုင်းသာ → resource ချွေတာ |

#### Dockerfile Structure

```dockerfile
# Stage 1: Builder
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci --only=production
COPY dist/ ./dist/

# Stage 2: Runner (final image)
FROM node:18-alpine AS runner
WORKDIR /app
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/dist ./dist
COPY package*.json ./
EXPOSE 3000
CMD ["node", "dist/app.js"]
```

#### `.gitlab-ci.yml` (Step 4 ထည့်ပြီးနောက်)

```yaml
docker:build:
  stage: dockerize
  image: docker:24
  services:
    - docker:24-dind
  variables:
    IMAGE_TAG: $CI_REGISTRY_IMAGE:$CI_COMMIT_SHORT_SHA
    LATEST_TAG: $CI_REGISTRY_IMAGE:latest
  before_script:
    - docker login -u $CI_REGISTRY_USER -p $CI_REGISTRY_PASSWORD $CI_REGISTRY
  script:
    - docker build -t $IMAGE_TAG -t $LATEST_TAG .
    - docker push $IMAGE_TAG
    - docker push $LATEST_TAG
  rules:
    - if: $CI_COMMIT_BRANCH == "main"
```

---

## 🎉 Pipeline ပြည့်စုံပြီ!

```
npm:install  →  eslint  →  unit:test  →  ts:build  →  docker:build
  (install)     (lint)      (test)        (build)      (dockerize)
```

| Step | Job | Stage | Cache Policy |
|------|-----|-------|-------------|
| 1 | `npm:install` | install | push (upload) |
| 2a | `eslint` | lint | pull (download) |
| 2b | `unit:test` | test | pull (download) |
| 3 | `ts:build` | build | pull (download) |
| 4 | `docker:build` | dockerize | — (artifact) |
