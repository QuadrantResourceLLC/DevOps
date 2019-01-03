Param(
	[Parameter(Mandatory=$true, HelpMessage="Enter source path for the folder" )]
	[string] $Build_LocalPath,
    [Parameter (Mandatory=$true, HelpMessage="Enter the name of the ZipFolder to be created")]
    $BuildZip_FolderName,
    [Parameter (Mandatory=$true, HelpMessage="Enter list of folders that you want to Zip")]
    $Folder_List,
	[Parameter (Mandatory=$true, HelpMessage="Enter the Build Name 'Service' or 'Framework'")]	
	[string]$Build
)
function Create-Zip{
	<#  
		.SYNOPSIS  
		   Add Files or Folders to a ZIP file.     
		.DESCRIPTION  
		   Add Files or Folders to a ZIP file using the native feature in Windows    
		   Will create the zip file if it does not already exist 
    
		   There is zip file support for powershell using things like DotNetZip 
		   But in my opinion it is neater to use pure code (if you can)   
		.Parameter source 
		   Enter file or folder to be zipped - Use full path. 
		.Parameter zipFileName 
		   Enter zip file name - Full path to create the .zip. 
		.EXAMPLE  
		   Create-ZIP -source "c:\scripts\notes.txt" -zipFileName "c:\destination\x.zip" 
	#>
	[Cmdletbinding()]
    param(
        [Parameter(Mandatory=$true, HelpMessage="Enter list of folders that you want to Zip")] 
        [string[]] $folderList,    
        [Parameter(Mandatory=$true, HelpMessage="Enter source path for the folder")]
        [string] $source,
        [Parameter(Mandatory=$true, HelpMessage="Enter the zip file name - Enter the full path")]
        [string]$destination,
		[Parameter (Mandatory=$true, HelpMessage="Enter the name of the ZipFolder to be created")]
        [string]$zipFolderName
    )    
	$zipFolder = Join-Path -path $destination -ChildPath $zipFolderName
	$destZip = Join-Path -Path $destination -ChildPath "$zipFolderName.zip"
	$destFolder = $zipFolder 	
    foreach($folder in $folderList)
    {   			
        if((Test-Path $source) -eq $false)
        {
            Write-Error "Error Reading the Source:"$source
        }
        else
        {			
            $sourcePath = Join-Path -Path $source -ChildPath $folder
            if((Test-Path $sourcePath) -eq $false)
            {
                Write-Host "The Folder $folder does not exist at the location $source" -ForegroundColor Red
            }
            else
            {
				Write-Host "Starting to copy the $folder to $destination" -ForegroundColor Green				   
				Write-Host "Starting the File Compression"   	
				$7zip ="$env:ProgramFiles\7-Zip\7z.exe"
				$7zipArgs = "a -tzip -mx=0 $destZip $sourcePath"
				Start-Process $7zip $7zipArgs -Wait
				Write-Host "File Compression Completed Successfully" 
            }
        }
    }
    
}
#####################################################################################################################################################
#
# PowerShell configurations
#

# NOTE: Because the $ErrorActionPreference is "Stop", this script will stop on first failure.
#       This is necessary to ensure we capture errors inside the try-catch-finally block.
$ErrorActionPreference = "Stop"

# Configure strict debugging.
Set-PSDebug -Strict

#####################################################################################################################################################

function Handle-LastError
{
    $message = $error[0].Exception.Message
    if ($message)
    {
        Write-Host -Object "ERROR: $message" -ForegroundColor Red
    }
    
    # IMPORTANT NOTE: Throwing a terminating error (using $ErrorActionPreference = "Stop") still
    # returns exit code zero from the PowerShell script when using -File. The workaround is to
    # NOT use -File when calling this script and leverage the try-catch-finally block and return
    # a non-zero exit code from the catch block.
    exit -1
}
#####################################################################################################################################################
#
# Main execution block.
#
#####################################################################################################################################################
Create-Zip -folderList $Folder_List -source $source -destination $destination -zipFolderName $BuildZip_FolderName