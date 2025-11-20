# NPM Token Setup Guide

This guide explains how to configure the NPM_TOKEN secret required for automated npm publishing.

## Prerequisites

- npm account with access to publish under `@loqalabs` scope
- Repository administrator access to configure GitHub secrets

## Step 1: Generate npm Access Token

1. Log in to [npmjs.com](https://www.npmjs.com)
2. Click on your profile icon → **Access Tokens**
3. Click **Generate New Token** → **Classic Token**
4. Configure the token:
   - **Token Type**: Automation
   - **Description**: `GitHub Actions - loqa-audio-bridge publishing`
   - **Permissions**: Select **Publish** (write:packages scope)
5. Click **Generate Token**
6. **Copy the token immediately** (it will only be shown once)

## Step 2: Add Token to GitHub Repository Secrets

1. Navigate to the repository on GitHub
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Configure the secret:
   - **Name**: `NPM_TOKEN`
   - **Secret**: Paste the token from Step 1
5. Click **Add secret**

## Step 3: Verify Secret Configuration

The publish workflow at [.github/workflows/publish-npm.yml](../.github/workflows/publish-npm.yml) will automatically use this secret when publishing.

The secret is referenced as:
```yaml
env:
  NODE_AUTH_TOKEN: ${{ secrets.NPM_TOKEN }}
```

## Token Security Best Practices

### Scope Limitations
- ✅ Use **Automation** token type (not Classic token with full access)
- ✅ Grant only **Publish** permission (principle of least privilege)
- ❌ Never grant admin or user management permissions

### Token Rotation
- **Frequency**: Rotate every 90 days
- **Process**:
  1. Generate new token at npmjs.com
  2. Update GitHub secret with new value
  3. Delete old token from npmjs.com
- **Calendar Reminder**: Set reminder for rotation date

### Security Monitoring
- Review npm account **Access Tokens** page monthly
- Revoke any tokens that are:
  - Unused for 90+ days
  - Associated with deprecated workflows
  - Showing unexpected usage patterns

### Emergency Revocation
If token is compromised:
1. **Immediately** revoke token at npmjs.com
2. Generate new token with different permissions
3. Update GitHub secret
4. Review recent npm publish history for unauthorized releases
5. If unauthorized version published, run: `npm deprecate @loqalabs/loqa-audio-bridge@<version> "Unauthorized release"`

## Troubleshooting

### Error: 401 Unauthorized
**Cause**: Invalid or expired NPM_TOKEN

**Solution**:
1. Verify token exists in GitHub Secrets
2. Generate new token at npmjs.com
3. Update GitHub secret

### Error: 403 Forbidden
**Cause**: Token lacks publish permissions or not authorized for @loqalabs scope

**Solution**:
1. Verify you're a member of the @loqalabs organization on npm
2. Request organization owner to grant publish access
3. Regenerate token with correct permissions

### Error: Package name already exists
**Cause**: Attempting to publish version that already exists

**Solution**:
- npm prevents overwriting published versions
- Increment version in package.json
- Create new git tag matching new version
- Republish

## Testing the Workflow

### Dry Run (Without Publishing)

To test the workflow without actually publishing:

1. Create a test tag: `git tag v0.3.0-test`
2. Push the tag: `git push origin v0.3.0-test`
3. Monitor workflow at: GitHub Actions → Publish to npm
4. Workflow will run validation but skip publish (non-semantic tag pattern)

### Full Publishing Test

For first-time setup validation:

1. Update version in package.json to `0.3.0` (or appropriate version)
2. Commit: `git commit -am "Release v0.3.0"`
3. Create tag: `git tag v0.3.0`
4. Push tag: `git push origin v0.3.0`
5. Monitor workflow execution
6. Verify package appears on npm: https://www.npmjs.com/package/@loqalabs/loqa-audio-bridge

## Workflow Trigger Pattern

The publish workflow triggers on tags matching `v*.*.*` (semantic versioning):

✅ **Valid triggers**:
- `v0.3.0`
- `v1.0.0`
- `v2.1.3`

❌ **Invalid triggers** (workflow will NOT run):
- `0.3.0` (missing 'v' prefix)
- `v0.3` (missing patch version)
- `v0.3.0-beta` (pre-release tags not supported in v0.3.0)

## Additional Resources

- [npm Access Tokens Documentation](https://docs.npmjs.com/creating-and-viewing-access-tokens)
- [GitHub Actions Secrets Documentation](https://docs.github.com/en/actions/security-guides/encrypted-secrets)
- [npm Publishing Guide](https://docs.npmjs.com/cli/v8/commands/npm-publish)
