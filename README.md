# ADFSCertMonitoring
<B>Monitor ADFS Certificates For Pending Expiry</B>
<P>
<b><i>_checkADFSTokenCerts.pl:</i></b> This perl script retrieves Active Directory Federation Services (ADFS) server-side federation certificates
and sends an alert when certificate(s) will expire soon. As we need to schedule the update through 
change management, alert anyone who wishes to perform post-implementation testing, and
ensure the on-call individual is aware of potential call volume ... it is beneficial to get a heads-up
in advance of the certificate expiration and auto-renewal. 
</P>
<P>
<b><i>_checkRelyingPartyCerts.ps1</i></b> This powershell script runs on the Active Directory Federation Services (ADFS) server to check the 
expiry dates in relying party trust objects. If expired or soon-to-expire certificates are found, an 
e-mail alert is sent to the ADFS management team for follow-up with partners.
</P>