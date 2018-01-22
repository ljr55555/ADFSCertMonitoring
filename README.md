# ADFSCertMonitoring
<B>Monitor ADFS Certificates For Pending Expiry</B>

<b><i>_checkADFSTokenCerts.pl:</i></b> This perl script retrieves Active Directory Federation Services (ADFS) server-side federation certificates
and sends an alert when certificate(s) will expire soon. As we need to schedule the update through 
change management, alert anyone who wishes to perform post-implementation testing, and
ensure the on-call individual is aware of potential call volume ... it is beneficial to get a heads-up
in advance of the certificate expiration and auto-renewal. 
