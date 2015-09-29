## Next Release

FEATURES:

IMPROVEMENTS:
  - Enforce PowerShell V3 requirement.

BUG FIXES:
  - Removed stray character and corrected grammar in error message.


## 1.0.02 (September 16, 2015)

IMPROVEMENTS:
  - Added Wrappers subdirectory with Start-StaleMonitor and Start-SqlMonitor

BUG FIXES:
  - **Issue #3: Prior data color indicator not reset on data update**
    Fixed so that upon update the prior data color indicator (the row count panel) is reset to neutral.


## 1.0.01 (September 13, 2015)

BUG FIXES:
  - **Issue #2: When running -AsJob, imports are only recognized if terminated with a semicolon**
    Fixed to properly support either line break so semicolon terminators.


## 1.0.00 (September 1, 2015)

  - This project was begun by The PowerShell Guy, aka MoW, several years back and then apparently abandoned
    (at http://thepowershellguy.com/blogs/posh/archive/2007/01/21/powershell-gui-scripblock-monitor-script.aspx).
    I picked it up a couple years later and decided to refurbish, refresh, and enhance it.
	And now I am ready to release it into the wild.
