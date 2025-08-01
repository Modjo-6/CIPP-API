function Invoke-CIPPStandardDisableGuestDirectory {
    <#
    .FUNCTIONALITY
        Internal
    .COMPONENT
        (APIName) DisableGuestDirectory
    .SYNOPSIS
        (Label) Restrict guest user access to directory objects
    .DESCRIPTION
        (Helptext) Disables Guest access to enumerate directory objects. This prevents guest users from seeing other users or guests in the directory.
        (DocsDescription) Sets it so guests can view only their own user profile. Permission to view other users isn't allowed. Also restricts guest users from seeing the membership of groups they're in. See exactly what get locked down in the [Microsoft documentation.](https://learn.microsoft.com/en-us/entra/fundamentals/users-default-permissions)
    .NOTES
        CAT
            Global Standards
        TAG
        ADDEDCOMPONENT
        IMPACT
            Low Impact
        ADDEDDATE
            2022-05-04
        POWERSHELLEQUIVALENT
            Set-AzureADMSAuthorizationPolicy -GuestUserRoleId '2af84b1e-32c8-42b7-82bc-daa82404023b'
        RECOMMENDEDBY
            "CIPP"
        UPDATECOMMENTBLOCK
            Run the Tools\Update-StandardsComments.ps1 script to update this comment block
    .LINK
        https://docs.cipp.app/user-documentation/tenant/standards/list-standards
    #>

    param($Tenant, $Settings)
    ##$Rerun -Type Standard -Tenant $Tenant -Settings $Settings 'DisableGuestDirectory'

    try {
        $CurrentInfo = New-GraphGetRequest -Uri 'https://graph.microsoft.com/beta/policies/authorizationPolicy/authorizationPolicy' -tenantid $Tenant
    }
    catch {
        $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
        Write-LogMessage -API 'Standards' -Tenant $Tenant -Message "Could not get the DisableGuestDirectory state for $Tenant. Error: $ErrorMessage" -Sev Error
        return
    }

    If ($Settings.remediate -eq $true) {

        if ($CurrentInfo.guestUserRoleId -eq '2af84b1e-32c8-42b7-82bc-daa82404023b') {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Guest access to directory information is already disabled.' -sev Info
        } else {
            try {
                $body = '{guestUserRoleId: "2af84b1e-32c8-42b7-82bc-daa82404023b"}'
                New-GraphPostRequest -tenantid $tenant -Uri 'https://graph.microsoft.com/beta/policies/authorizationPolicy/authorizationPolicy' -Type patch -Body $body -ContentType 'application/json'
                Write-LogMessage -API 'Standards' -tenant $tenant -message 'Disabled Guest access to directory information.' -sev Info
            } catch {
                $ErrorMessage = Get-NormalizedError -Message $_.Exception.Message
                Write-LogMessage -API 'Standards' -tenant $tenant -message "Failed to disable Guest access to directory information.: $ErrorMessage" -sev 'Error'
            }
        }
    }

    if ($Settings.alert -eq $true) {

        if ($CurrentInfo.guestUserRoleId -eq '2af84b1e-32c8-42b7-82bc-daa82404023b') {
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Guest access to directory information is disabled.' -sev Info
        } else {
            Write-StandardsAlert -message 'Guest access to directory information is not disabled.' -object $CurrentInfo -tenant $tenant -standardName 'DisableGuestDirectory' -standardId $Settings.standardId
            Write-LogMessage -API 'Standards' -tenant $tenant -message 'Guest access to directory information is not disabled.' -sev Info
        }
    }

    if ($Settings.report -eq $true) {
        if ($CurrentInfo.guestUserRoleId -eq '2af84b1e-32c8-42b7-82bc-daa82404023b') { $CurrentInfo.guestUserRoleId = $true } else { $CurrentInfo.guestUserRoleId = $false }
        Set-CIPPStandardsCompareField -FieldName 'standards.DisableGuestDirectory' -FieldValue $CurrentInfo.guestUserRoleId -TenantFilter $Tenant
        Add-CIPPBPAField -FieldName 'DisableGuestDirectory' -FieldValue $CurrentInfo.guestUserRoleId -StoreAs bool -Tenant $tenant
    }
}
