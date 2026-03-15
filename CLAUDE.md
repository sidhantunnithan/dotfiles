# Setup Scripts

Setup scripts (setup.bash) are designed to be curl-piped (`curl | bash`). They must:
- Download config files from the GitHub repo using raw URLs, NOT symlink to local paths
- Never assume the dotfiles repo is cloned locally

# Post-Work Cleanup

After completing the work and all changes are committed:

1. Merge changes into main
2. Clean the worktree
3. Clean the branch
4. Push to remote
