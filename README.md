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

*နောက်ထပ် steps တွေ ဆက်ထည့်သွားမယ်...*
