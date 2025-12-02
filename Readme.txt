Introduction

This idea / script was inspired by my experience piloting AppsAnywhere. During the pilot, I noticed the potential to simplify Pre-Cache application deployment by downloading STP files directly from the official AppsAnywhere repository, rather than relying on internal file shares.

If this script proves valuable, I plan to develop it further to automatically compare the list of STP files defined and currently cached locally against the latest versions available on the AppsAnywhere site. If any files are outdated, the script could download and cache the newest versions on a scheduled basis. However, I’d appreciate feedback from the community before moving forward with these enhancements.



Script Overview

This PowerShell script automates the process of downloading STP application packages directly from https://packages.appsanywhere.com. It streamlines application deployment by eliminating the need to host STP files on internal file shares.

https://github.com/systemcenterblog/AppsAnywhere/blob/main/Precache_AutoLicenseSTP.ps1 


Key Steps

Download STP Files:
The script fetches specified STP files from the AppsAnywhere public repository.

Extract STC Content:
After downloading, the script extracts the STC (Streaming Core) file from the STP package.

Add to Cache:
The extracted STC file is then added to the local Cloudpaging cache, making the application available for deployment.

Cleanup:
Once caching is complete, the script deletes the downloaded STP file to conserve disk space.

Benefits

No Internal Hosting Required:
All application packages are sourced directly from the official AppsAnywhere repository, removing the need for internal file shares or manual file management.

Efficient Deployment:
Automates extraction and caching, reducing manual steps and potential errors.

Disk Space Optimization:
Cleans up temporary files after use.
