# SkillMate App

## Overview
SkillMate is a modern Flutter application with a web front‑end hosted on Vercel. It includes a comprehensive **end‑to‑end Selenium test suite** that generates a styled Excel report and a **GitHub Actions CI pipeline** that runs tests, performs a vulnerability scan (`npm audit`), and uploads the report.

## Prerequisites
- **Flutter SDK** (latest stable) – for mobile development.
- **Node.js** (v20+) and **npm** – for the E2E test runner.
- **Git** – to clone the repository.
- A **GitHub account** with write access to the repo (for CI badges, pushes, etc.).

## Getting Started
1. **Clone the repository**
   ```bash
   git clone https://github.com/vishnuvardhanreddymaram/skillmate_app.git
   cd skillmate_app
   ```
2. **Install Flutter dependencies**
   ```bash
   flutter pub get
   ```
3. **Run the app locally**
   ```bash
   flutter run
   ```
   The app will launch on a connected device or emulator.

## Running the E2E Test Suite
The Selenium tests live in the `e2e_tests` folder.
1. Install Node dependencies:
   ```bash
   cd e2e_tests
   npm ci
   ```
2. Execute the tests:
   ```bash
   node run_tests.js
   ```
   - The script starts a head‑less Chrome driver, runs **115 test cases** (including UI/UX, functional, validation, unit, and security tests), and generates an Excel report named like `E2E_Test_Report_SkillMate_2026-06-18T04-25-19-605Z.xlsx`.
3. Open the report in Excel to view the dashboard summary and detailed test logs.

## CI / CD Workflow (GitHub Actions)
The workflow defined in `.github/workflows/e2e_tests.yml` automatically runs on every push or pull request:
- **Setup Node** → **Install dependencies** → **Run `npm audit`** (fails on high‑severity vulnerabilities) → **Execute Selenium tests** → **Upload the Excel report** as an artifact.
- The workflow uses a glob pattern `E2E_Test_Report_SkillMate_*.xlsx` to pick up the timestamped report.

## Security Scanning
A dedicated step runs:
```bash
npm audit --audit-level=high
```
Any high‑ or critical‑severity CVEs will cause the CI job to fail, ensuring you catch vulnerable dependencies early.

## Deploying the Web Front‑end
The web version is hosted on Vercel (URL: `https://skillmate-app.vercel.app`). After merging to `main`, Vercel automatically builds and deploys the web app.

## Useful Commands Summary
| Action | Command |
|--------|----------|
| Clone repo | `git clone <repo‑url>` |
| Install Flutter deps | `flutter pub get` |
| Run app (mobile) | `flutter run` |
| Install Node deps (E2E) | `cd e2e_tests && npm ci` |
| Run E2E tests | `node run_tests.js` |
| Run security audit | `npm audit --audit-level=high` |

---
*Happy coding!*
