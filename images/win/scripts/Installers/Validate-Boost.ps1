################################################################################
##  File:  Validate-Boost.ps1
##  Desc:  Validate Boost
################################################################################

function Validate-BoostVersion
{
    Param
    (
        [String]$BoostRootPath,
        [String]$BoostRelease
    )

    $ReleasePath = Join-Path -Path $BoostRootPath -ChildPath $BoostRelease

    if (Test-Path "$ReleasePath\b2.exe")
    {
        Write-Host "Boost.Build $BoostRelease is successfully installed"

        return
    }

    Write-Host "$BoostRelease not found"
    exit 1
}

# Verify that Boost is on the path
if (Get-Command -Name 'b2')
{
    Write-Host "Boost is on the path"
}
else
{
    Write-Host "Boost is not on the path"
    exit 1
}

# Adding description of the software to Markdown
$tmplMark = @"
#### {0} [{2}]

_Environment:_
* {1}: root directory of the Boost version {0} installation

"@

$tmplMarkRoot = @"
#### {0} [{2}]

_Environment:_
* PATH: contains the location of Boost version {0}
* BOOST_ROOT: root directory of the Boost version {0} installation
* {1}: root directory of the Boost version {0} installation
"@

$SoftwareName = 'Boost'
$Description = New-Object System.Text.StringBuilder
$BoostRootDirectory = Join-Path -Path $env:AGENT_TOOLSDIRECTORY -ChildPath "Boost"
$BoostVersionsToInstall = $env:BOOST_VERSIONS.split(",")

foreach($BoostVersion in $BoostVersionsToInstall)
{
    Validate-BoostVersion -BoostRootPath $BoostRootDirectory -BoostRelease $BoostVersion
    $BoostVersionTag = "BOOST_ROOT_{0}" -f $BoostVersion.Replace('.', '_')

    if ([Version]$BoostVersion -ge "1.70.0")
    {
        $BoostToolsetName = "msvc-14.2"
    }
    else
    {
        $BoostToolsetName = "msvc-14.1"
    }

    if($BoostVersion -eq $env:BOOST_DEFAULT)
    {
        $null = $Description.AppendLine(($tmplMarkRoot -f $BoostVersion, $BoostVersionTag, $BoostToolsetName))
    }
    else
    {
        $null = $Description.AppendLine(($tmplMark -f $BoostVersion, $BoostVersionTag, $BoostToolsetName))
    }
}

$CMakeFindBoostInfo = @"

#### _Notes:_
Link: https://cmake.org/cmake/help/latest/module/FindBoost.html

If Boost was built using the ``boost-cmake`` project or from ``Boost 1.70.0`` on it provides a package
configuration file for use with find\_package's config mode. This module looks for the package
configuration file called BoostConfig.cmake or boost-config.cmake and stores the result in CACHE entry "Boost_DIR".
If found, the package configuration file is loaded and this module returns with no further action.
See documentation of the Boost CMake package configuration for details on what it provides.

Set ``Boost_NO_BOOST_CMAKE to ON``, to disable the search for boost-cmake.
"@

$null = $Description.AppendLine($CMakeFindBoostInfo)
Add-SoftwareDetailsToMarkdown -SoftwareName $SoftwareName -DescriptionMarkdown $Description.ToString()
