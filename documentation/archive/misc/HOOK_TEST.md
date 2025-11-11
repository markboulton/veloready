# Pre-Commit Hook Test

This file tests that the pre-commit hook works with GitHub Desktop.

When you commit this file via GitHub Desktop:
1. The pre-commit hook will automatically run
2. It will execute `./Scripts/quick-test.sh`
3. All 35 tests will run
4. If tests pass, the commit succeeds
5. If tests fail, the commit is blocked

You'll see the test output in GitHub Desktop's commit dialog.

**Expected behavior:**
- Tests run automatically (you don't trigger them)
- Takes ~68 seconds
- Commit succeeds when tests pass

**Try it:**
1. Open GitHub Desktop
2. Stage this file
3. Write a commit message
4. Click "Commit to iOS-Error-Handling"
5. Watch the pre-commit hook run!
