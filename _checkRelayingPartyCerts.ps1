################################################################################
## Editable variables
################################################################################
# Email components
$strFromAddress = "sender@something.gTLD"
$strToAddress = "recipient@something.gTLD"
$strMessageSubject = "ADFS Relaying Party Certificates Pending Expiry"
$strSendingServer = "mail.relay.gTLD"

$iAlertHoursBeforeExpiry = 30 * 24
################################################################################
$strTableBody = ""
$iExpiringSoon = 0

Get-AdfsRelyingPartyTrust | ForEach-Object {
#	write-host $_.Identifier
	$strRPIdentity = $_.Identifier
	$certRelayingPartySigning = (Get-AdfsRelyingPartyTrust -Identifier $strRPIdentity).RequestSigningCertificate
	
	$certRelayingPartySigning | ForEach-Object {
		$dateExpiryDate = $_.NotAfter
		$strThumbprint = $_.Thumbprint
		$strSubject = $_.Subject

		if($dateExpiryDate){
			$dtdiff = New-TimeSpan $(Get-Date) $dateExpiryDate
#			write-host $dtdiff.TotalHours
			if ($dtdiff.TotalHours -lt $iAlertHoursBeforeExpiry){
				$iExpiringSoon = $iExpiringSoon + 1
				$strTableBody = "$strTableBody <tr><td>$strSubject</td><td>$dateExpiryDate</td></tr>"
				write-host "$dateExpiryDate is when $strSubject expires"
				write-host $dtdiff.TotalHours
				write-host "."
			}
		}		
	}
}

if($iExpiringSoon -gt 0){
	$strMessageBody = "<table><tr><th>Cert Subject</th><th>Cert Expires</th></tr>\n$strTableBody\n</table>"

	# Email objects
	$objSMTPMessage = New-Object System.Net.Mail.MailMessage $strFromAddress, $strToAddress, $strMessageSubject, $strMessageBody
	$objSMTPMessage.IsBodyHTML = $true
	$objSMTPClient = New-Object System.Net.Mail.SMTPClient $strSendingServer
	$objSMTPClient.Send($objSMTPMessage)
}
