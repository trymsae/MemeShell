function Get-Placeholder {
    <#
        .SYNOPSIS
            This is a function to test release-pipeline
        .DESCRIPTION
            This is a function to test release-pipeline
        .PARAMETER input
            string input
        .EXAMPLE
            Find-Placeholder -input "test"
    #>
    [CmdletBinding()]
    param (
        [parameter(Position = 0, Mandatory = $true)]
        [string]$input
    )
    begin {
        if (-not $input){
            Write-host "how did you end up here?"
        }
    }
    process {
        $output = $input + " very nice."
    }
    end {
        # ur mom gae x3
        return $output
    }
}