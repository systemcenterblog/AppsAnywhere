
#
DISCLAIMER:
This script is provided "as is" without warranty of any kind, either expressed or implied, including but not limited to the implied warranties of merchantability and fitness for a particular purpose. Use of this script is at your own risk.

Sections of this script have been adapted from or borrow code and concepts from public scripts authored by the OSD and AppsAnywhere communities. Full credit is given to the original authors for their contributions.

Please review and test this script in your environment before deploying to production.

Author of script:  https://www.syswow64.co.uk
#>


function Save-WebFile {
    [CmdletBinding()]
    [OutputType([System.IO.FileInfo])]
    param
    (
        [Parameter(Position=0, Mandatory, ValueFromPipelineByPropertyName)]
        [Alias('FileUri')]
        [System.String]
        $SourceUrl,

        [Parameter(ValueFromPipelineByPropertyName)]
        [Alias('FileName')]
        [System.String]
        $DestinationName,

        [Alias('Path')]
        [System.String]
        $DestinationDirectory = (Join-Path $env:TEMP 'OSD'),

        #Overwrite the file if it exists already
        #The default action is to skip the download
        [System.Management.Automation.SwitchParameter]
        $Overwrite,

        [System.Management.Automation.SwitchParameter]
        $WebClient
    )
    #=================================================
    #	Values
    #=================================================
    Write-Verbose "SourceUrl: $SourceUrl"
    Write-Verbose "DestinationName: $DestinationName"
    Write-Verbose "DestinationDirectory: $DestinationDirectory"
    Write-Verbose "Overwrite: $Overwrite"
    Write-Verbose "WebClient: $WebClient"
    #=================================================
    #	DestinationDirectory
    #=================================================
    if (Test-Path "$DestinationDirectory")
    {
        Write-Verbose "Directory already exists at $DestinationDirectory"
    }
    else {
        New-Item -Path "$DestinationDirectory" -ItemType Directory -Force -ErrorAction Stop | Out-Null
    }
    #=================================================
    #	Test File
    #=================================================
    $DestinationNewItem = New-Item -Path (Join-Path $DestinationDirectory "$(Get-Random).txt") -ItemType File

    if (Test-Path $DestinationNewItem.FullName) {
        $DestinationDirectory = $DestinationNewItem | Select-Object -ExpandProperty Directory
        Write-Verbose "Destination Directory is writable at $DestinationDirectory"
        Remove-Item -Path $DestinationNewItem.FullName -Force | Out-Null
    }
    else {
        Write-Warning "Unable to write to Destination Directory"
        Break
    }
    #=================================================
    #	DestinationName
    #=================================================
    if ($PSBoundParameters['DestinationName']) {
    }
    else {
        $DestinationNameUri = $SourceUrl -as [System.Uri] # Convert to Uri so we can ignore any query string
        $DestinationName = $DestinationNameUri.AbsolutePath.Split('/')[-1]
    }
    Write-Verbose "DestinationName: $DestinationName"
    #=================================================
    #	WebFileFullName
    #=================================================
    $DestinationDirectoryItem = (Get-Item $DestinationDirectory -Force).FullName
    $DestinationFullName = Join-Path $DestinationDirectoryItem $DestinationName
    #=================================================
    #	OverWrite
    #=================================================
    if ((-NOT ($PSBoundParameters['Overwrite'])) -and (Test-Path $DestinationFullName)) {
        Write-Verbose "DestinationFullName already exists"
        Get-Item $DestinationFullName -Force
    }
    else {
        #=================================================
        #	Download
        #=================================================
        $SourceUrl = [Uri]::EscapeUriString($SourceUrl.Replace('%', '~')).Replace('~', '%') # Substitute and replace '%' to avoid escaping os Azure SAS tokens
        Write-Verbose "Testing file at $SourceUrl"
        #=================================================
        #	Test for WebClient Proxy
        #=================================================
        $UseWebClient = $false
        if ($WebClient -eq $true) {
            $UseWebClient = $true
        }
        elseif (([System.Net.WebRequest]::DefaultWebProxy).Address) {
            $UseWebClient = $true
        }
        elseif (!(Test-CommandCurlExe)) {
            $UseWebClient = $true
        }

        if ($UseWebClient -eq $true) {
            [Net.ServicePointManager]::SecurityProtocol = [Net.ServicePointManager]::SecurityProtocol -bor [Net.SecurityProtocolType]::Tls1
            $WebClient = New-Object System.Net.WebClient
            $WebClient.DownloadFile($SourceUrl, $DestinationFullName)
            $WebClient.Dispose()
        }
        else {
            Write-Verbose "cURL Source: $SourceUrl"
            Write-Verbose "Destination: $DestinationFullName"
    
            if ($host.name -match 'ConsoleHost') {
                Invoke-Expression "& curl.exe --insecure --location --output `"$DestinationFullName`" --url `"$SourceUrl`""
            }
            else {
                #PowerShell ISE will display a NativeCommandError, so progress will not be displayed
                $Quiet = Invoke-Expression "& curl.exe --insecure --location --output `"$DestinationFullName`" --url `"$SourceUrl`" 2>&1"
            }
        }
        #=================================================
        #	Return
        #=================================================
        if (Test-Path $DestinationFullName) {
            Get-Item $DestinationFullName -Force
        }
        else {
            Write-Warning "Could not download $DestinationFullName"
            $null
        }
        #=================================================
    }
}
function Test-CommandCurlExe {
    [CmdletBinding()]
    param ()
    
    if (Get-Command 'curl.exe' -ErrorAction SilentlyContinue) {
        Return $true
    }
    else {
        Return $false
    }
}

# Variables
$stpUrl              = "https://packages.appsanywhere.com/automated/English/"
$stpUrlApp           ="MATLAB_R2025a_64bit_x64_Auto_Server_English_rel1.stp"
$stpDownloadPath     = "C:\ProgramData\Numecent\StreamingCore\STP_Download_Temp"
$LocalPath           = "C:\ProgramData\Numecent\StreamingCore\Cache"

# Load the required .NET assembly
Add-Type -AssemblyName System.IO.Compression.FileSystem

# Import Cloudpaging module
try {
    Import-Module Cloudpaging
    Write-Host "Cloudpaging module, successfully imported"
}
catch {
    Write-Host "Cloudpaging module, failed to import. Error: $_"
    exit 1
}

# Ensure STP_Download_Temp folder exists
if (-not (Test-Path $stpDownloadPath)) {
    New-Item -Path $stpDownloadPath -ItemType Directory | Out-Null
}

# Ensure destination folder exists
if (-not (Test-Path $LocalPath)) {
    New-Item -Path $LocalPath -ItemType Directory | Out-Null
}

# Download the STP file
Save-WebFile -SourceUrl ($stpUrl + $stpUrlApp) -DestinationDirectory $stpDownloadPath -DestinationName ($stpUrlApp) -verbose



# Get all .stp files in the directory
$stpFiles = Get-ChildItem -Path $stpDownloadPath  -Filter *.stp -File
$stpFiles



Foreach($stp in $stpFiles){

#Start of Loop

# Open the STP (ZIP) archive
$zip = [System.IO.Compression.ZipFile]::OpenRead((Join-Path $stpDownloadPath $stp)) 

###

# Find the entry for the XML file
$entry = $zip.Entries | Where-Object { $_.Name -like '*.xml' }

if ($entry) {
    # Open a stream to the entry
    $stream = $entry.Open()
    # Create a file stream to write to
    $fileStream = [System.IO.File]::Open((Join-Path $stpDownloadPath $entry.FullName), [System.IO.FileMode]::Create)
    # Copy the entry stream to the file stream
    $stream.CopyTo($fileStream)
    # Close the streams
    $fileStream.Close()
    $stream.Close()
    Write-Host "Extracted $entry.FullName XML to $stpDownloadPath"
} else {
    Write-Host "XML not found in $stpDownloadPath"
}

$content = Get-Content (Join-Path $stpDownloadPath $entry.FullName) -Raw
if ($content -match '<app-id>(.*?)</app-id>') {
    $AppsID = $matches[1]
}
if ($content -match '<app-name>(.*?)</app-name>') {
    $AppsName = $matches[1]
}
$AppsID #=""
$AppsName #=""

###

# Find the entry for the STC file
$entry = $zip.Entries | Where-Object { ($_.Name -eq "$AppsName.stc") }

if ($entry) {
    # Open a stream to the entry
    $stream = $entry.Open()
    # Create a file stream to write to
    $fileStream = [System.IO.File]::Open((Join-Path $stpDownloadPath $AppsID'_'$AppsName'.stc'), [System.IO.FileMode]::Create)
    # Copy the entry stream to the file stream
    $stream.CopyTo($fileStream)
    # Close the streams
    $fileStream.Close()
    $stream.Close()
    Write-Host "Extracted stc to $stpDownloadPath"
} else {
    Write-Host "stc not found in $stpDownloadPath"
}

# Dispose of the zip archive
$zip.Dispose()

# Add-CloudpagingMultiCache
try {

Add-CloudpagingMultiCache -CopyToCache (Join-Path $stpDownloadPath $AppsID'_'$AppsName'.stc') -ErrorAction Stop
Get-CloudpagingPrecache
$DeleteSTP_STCDownload=$TRUE
#$DeleteSTP_STCDownload=$FALSE
}
catch {
    Write-Host "Add-CloudpagingMultiCache, failed to import. Error: $_"
    exit 1
}

if($DeleteSTP_STCDownload) {
# Delete the original .stp file
Remove-Item (Join-Path $stpDownloadPath $AppsName'.stp') -Force
Remove-Item (Join-Path $stpDownloadPath $AppsID'_'$AppsName'.stc') -Force
Remove-Item (Join-Path $stpDownloadPath $AppsName'.xml') -Force
Write-Host "Deleted downloaded STP/STC/XML file"
}

#End of foreach loop
}

<#Reset
$entry =""
$zip=""
$AppsName=""
$AppsID=""
$stp=""
$stpFiles=""

Remove-CloudpagingPrecache -id 79C42890-7778-4E2B-8F48-86CAD1080ADC
#>
