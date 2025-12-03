# Security Guidelines

## API Key Management

### ⚠️ IMPORTANT: Never Commit API Keys to Git

This project uses sensitive API keys that must be kept secret. Follow these guidelines:

### Current Implementation

1. **Config.swift** - Contains actual API keys (GITIGNORED)
   - This file is in `.gitignore` and will NOT be committed
   - Contains your real RevenueCat API key
   
2. **Config.swift.template** - Template for new developers (COMMITTED)
   - Safe to commit - contains placeholders only
   - New team members copy this to create their own `Config.swift`

### Setup for New Developers

When cloning this repository:

```bash
# 1. Copy the template
cp Config.swift.template Config.swift

# 2. Edit Config.swift and add your API key
# (Get the key from your team lead or RevenueCat dashboard)

# 3. NEVER commit Config.swift
git status  # Should not show Config.swift as changed
```

### What's Protected

The following files are in `.gitignore`:
- `Config.swift` - Contains API keys

### If You Accidentally Committed an API Key

If you accidentally committed an API key to git:

1. **Immediately rotate the key** in your RevenueCat dashboard
2. Generate a new API key
3. Update your local `Config.swift` with the new key
4. Remove the key from git history:
   ```bash
   # Warning: This rewrites git history
   git filter-branch --force --index-filter \
     "git rm --cached --ignore-unmatch Config.swift" \
     --prune-empty --tag-name-filter cat -- --all
   
   # Force push (coordinate with your team first!)
   git push origin --force --all
   ```

5. Have all team members:
   ```bash
   git fetch origin
   git reset --hard origin/main
   ```

### Best Practices

1. ✅ **DO** use `Config.swift` for sensitive data
2. ✅ **DO** keep `Config.swift.template` updated when adding new keys
3. ✅ **DO** use different API keys for development and production
4. ✅ **DO** regularly rotate API keys
5. ❌ **DON'T** commit `Config.swift` to git
6. ❌ **DON'T** share API keys via Slack, email, or other insecure channels
7. ❌ **DON'T** use production API keys in development

### For Production Apps

For production apps, consider:

1. **Use Xcode Configuration Files** (`.xcconfig`)
2. **Environment Variables** in CI/CD pipelines
3. **Key Management Services** (AWS Secrets Manager, Azure Key Vault, etc.)
4. **Backend Proxy** - Never expose API keys in client apps

### Checking Before Commit

Always check before committing:

```bash
# Check what files will be committed
git status

# Make sure Config.swift is NOT in the list
# If it appears, you need to fix .gitignore

# Search for any hardcoded keys
git grep -i "test_" --cached
git grep -i "apikey" --cached
```

## Questions?

If you have questions about security or accidentally exposed a key, contact your team lead immediately.
