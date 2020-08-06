Import-Module ActiveDirectory
Get-ADUser -Filter * -SearchBase '>>DN from AD<<' | `
    ForEach-Object {
    $mhcemail = $_.userprincipalname
    $usernomhc = $mhcemail -replace "@domain" -replace ""
    Set-ADUser -EmailAddress ($usernomhc + '@contoso.com') -Identity $_ }
    
# Changes current email to userlogon@domain.com
# example: user logon: John.Doe, current email: jdoe@domain.com
# Result would be John.Doe@contoso.com
