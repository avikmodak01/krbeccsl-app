# KRBECCSL — 100 Years Memento Distribution System

## Project Structure

```
krbeccsl-app/
├── public/
│   └── index.html          ← The entire frontend app
├── netlify/
│   └── functions/
│       └── db.js           ← Secure Supabase proxy (runs server-side)
├── netlify.toml            ← Netlify build config
├── .gitignore              ← Keeps secrets out of git
└── README.md
```

## How secrets are protected

- `SUPABASE_URL` and `SUPABASE_KEY` are stored **only** in Netlify's environment variables dashboard
- They are **never** in the HTML or JavaScript that gets sent to browsers
- The frontend calls `/.netlify/functions/db` (our own server)
- That server function calls Supabase using the secret keys
- Only whitelisted tables (`members`, `tokens`, `logs`, `app_users`) can be accessed

---

## Step 1 — Push to GitHub

### First time setup (do this once on your PC)

1. Install **Git**: https://git-scm.com/download/win
2. Install **GitHub Desktop** (easier): https://desktop.github.com  
   Or use the command line below.

### Using GitHub Desktop
1. Open GitHub Desktop → **File → Add Local Repository**
2. Choose the `krbeccsl-app` folder
3. Click **Publish repository** → set name `krbeccsl-app` → **Private** → Publish

### Using command line
```bash
cd krbeccsl-app
git init
git add .
git commit -m "Initial commit"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/krbeccsl-app.git
git push -u origin main
```

---

## Step 2 — Deploy on Netlify

1. Go to https://netlify.com → Log in → **Add new site → Import from Git**
2. Choose **GitHub** → select `krbeccsl-app` repository
3. Build settings are auto-detected from `netlify.toml`:
   - Publish directory: `public`
   - Functions directory: `netlify/functions`
4. Click **Deploy site**

---

## Step 3 — Add Environment Variables in Netlify

This is the critical step — without this, the app cannot connect to Supabase.

1. In Netlify → your site → **Site configuration → Environment variables**
2. Click **Add a variable** and add these two:

   | Key | Value |
   |-----|-------|
   | `SUPABASE_URL` | `https://your-project.supabase.co` |
   | `SUPABASE_KEY` | `eyJhbGciOiJIUzI1NiIsInR5cCI6...` (your anon key) |

3. After adding, go to **Deploys → Trigger deploy → Deploy site**
   (Environment variables only take effect after a redeploy)

### Where to find your Supabase keys
Supabase dashboard → Your project → **Project Settings → API**
- Copy **Project URL** → paste as `SUPABASE_URL`
- Copy **anon public** key → paste as `SUPABASE_KEY`

---

## Step 4 — Every future update

Whenever you change `index.html` or `db.js`:

### GitHub Desktop
1. GitHub Desktop shows changed files
2. Write a commit message (e.g. "Fix dashboard report")
3. Click **Commit to main** → **Push origin**
4. Netlify auto-deploys within ~30 seconds

### Command line
```bash
git add .
git commit -m "Your change description"
git push
```

---

## Default Login Credentials (change after setup)

| Username   | Password   | Role           |
|------------|------------|----------------|
| admin      | Admin@123  | Admin          |
| issue.op1  | Issue@123  | Token Issue    |
| issue.op2  | Issue@123  | Token Issue    |
| issue.op3  | Issue@123  | Token Issue    |
| gift.op1   | Gift@123   | Gift Counter   |
| gift.op2   | Gift@123   | Gift Counter   |
| sweet.op1  | Sweet@123  | Sweet Counter  |
| sweet.op2  | Sweet@123  | Sweet Counter  |
| viewer     | View@123   | Dashboard only |
