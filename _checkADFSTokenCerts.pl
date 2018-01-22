################################################################################
##      This script sends an email notification when SSL certificates will
## soon be expiring.  It reads the certificate data from the ADSF
## federation metadata URL.
## V1.0 2018-01-22      LJR     Initial code
################################################################################
# Editable variables
# URL to Federationmetadata.xml for your ADFS instance
$strMetaDataURL = 'https://ADFSHost.whatever.gTLD/FederationMetadata/2007-06/FederationMetadata.xml';

# Number of days prior to cert expiry to send warn msgs
my $iDaysForWarning = 30;

# Connection details for SMTP relay server 
my $strSMTPRelay = "mailhost.whatever.gTLD";
my $iSMTPPort = '25';

# Email addresses of warning recipients
my $strDestEmailAddresses = 'devnull@whatever.gTLD';
# Email address from which alert is sent
my $strSenderEmailAddress = 'someone@whatever.gTLD';
# Alert message subject
my $strAlertSubject = "Certificate Expiration Notification";

# Enable/disable debugging output
my $boolDebug = 1;
################################################################################
##      DO NOT EDIT BELOW THIS LINE UNLESS YOU REALLY MEAN IT
################################################################################
use strict;
# Modules needed for script
use File::Spec;						# Dynamically determining script name and path
use Sys::Hostname;					# Dynamically determining hostname where script is executing

use Time::Local;					# Get current time
use Date::Calc qw(Delta_Days Add_Delta_Days);		# Calculate difference between two dates

use LWP::Simple;					# Fetching Federation Metadata in XML
use XML::Twig;						# Parsing XML data
use Crypt::OpenSSL::X509;				# Parsing certificate

use Email::Sender::Simple qw(sendmail);			# Sending e-mail cert expiry alert
use Email::Simple;
use Email::Simple::Creator;
use Email::Sender::Transport::SMTP;

my %mon2num = qw(
  jan 1  feb 2  mar 3  apr 4  may 5  jun 6
  jul 7  aug 8  sep 9  oct 10 nov 11 dec 12
);

my $iAlertsFound = 0;
my @strExpiryingCerts = ();

my $strAutomationHost = hostname;

# Determine script file name and path
my $strDirectoryName = File::Spec->rel2abs(__FILE__);
my $strScriptFileName =$0;

if(length($strDirectoryName) < length($strScriptFileName)){
        $strDirectoryName =~ s/$strScriptFileName$//;
}
else{
        $strDirectoryName =~ s/[^\/]+$//;
        $strScriptFileName =~ s/^$strDirectoryName//;
}

if($boolDebug == 1){
	print "Current path is $strDirectoryName and the file is $strScriptFileName on host $strAutomationHost\n";
}

my $strScriptDirectory = $strDirectoryName;
my $strScriptFile = $strScriptFileName;
my $strScriptFullPath = $strScriptDirectory . $strScriptFile;

# Figure out what today is
my $strDate = gmtime(time);
my ($sec,$min,$hour,$strTodayDate,$strTodayMonth,$strTodayYear,$wday,$yday,$isdst) = gmtime(time);
$strTodayMonth = $strTodayMonth+1;				# Month is zero indexed
$strTodayYear = $strTodayYear + 1900;

my $twig = XML::Twig->new(pretty_print => 'indented', empty_tags => 'html',);

$twig->parse_html(get($strMetaDataURL));

my $root = $twig->root;
if($boolDebug == 1){
	print $root->print;
}

for my $node($root->findnodes('//x509certificate')){
	my $strCertText = $node->text;
	# Wrap base 64 data from XML in appropriate X509 format
	$strCertText = "-----BEGIN CERTIFICATE-----\n" . $strCertText . "\n-----END CERTIFICATE-----";
	$strCertText =~ s/(.{64})/$1\n/g;

	&getCertExpiry($strCertText);

}

if($iAlertsFound > 0){
        &sendWarning;
}

exit(0);

sub getCertExpiry{
	my $strCertText = $_[0];
	my $x509Certificate = Crypt::OpenSSL::X509->new_from_string ($strCertText);
	my $strExpDate = $x509Certificate->notAfter();
	
	if($boolDebug == 1){
		print "$strCertText\n";
		print "$strExpDate is the expiry date for this cert\n";
	}

	my ($strExpMonthName,$strExpDate,$strHour,$strMinute,$strSecond,$strExpYear,$strTZ) = split(/[\s.:]+/, $strExpDate);
        my $strExpMonth = $mon2num{ lc substr($strExpMonthName, 0, 3) };

	if($boolDebug == 1){
		print "\tToday is $strTodayYear-$strTodayMonth-$strTodayDate\n";
		print "\tCert expires $strExpYear-$strExpMonth-$strExpDate\n";
	}

	my $iDeltaToExpiry = Delta_Days($strTodayYear,$strTodayMonth,$strTodayDate,$strExpYear,$strExpMonth,$strExpDate);
	if($boolDebug == 1){
		print "\t $iDeltaToExpiry days from now\n";
	}
        if($iDeltaToExpiry <= $iDaysForWarning){
		my $strCertSubject = $x509Certificate->subject();
        	@strExpiryingCerts[$iAlertsFound] = "<tr><td>$strCertSubject</td><td>Cert expires in $iDeltaToExpiry days.</td></tr>\n";
        	$iAlertsFound++;
        }
}

sub sendWarning{
	my $strMsgBody = "\<font face\=arial color\=navy link\=blue alink\=blue vlink\=blue\>\<b\>SSL Certificates Pending Expiry\<\/b\>\<p\>\nThe following SSL certificates will expire soon; The certificates should automatically renew themselves 20 days prior to expiry. At that time, update Azure and ensure that all federation partners have been notified.<P><table border=1 cellpadding=2><tr><th>Host Name</th><th>Comments</th></tr>";
	foreach my $strEmailLine(@strExpiryingCerts){
                $strMsgBody = $strMsgBody . "$strEmailLine\n";
        }
        $strMsgBody = $strMsgBody . "</table>\<p\>\n\n";
	$strMsgBody = $strMsgBody . "<font size=-1><i>This email was generated on $strAutomationHost via script $strScriptFullPath.</i></font></p>\n";

	my $transport = Email::Sender::Transport::SMTP->new({host => $strSMTPRelay, port => $iSMTPPort,}); 
	my $email = Email::Simple->create(	header => [
							'To'      	=> $strDestEmailAddresses,
							'From'    	=> $strSenderEmailAddress,
							'Subject' 	=> $strAlertSubject,
							'Content-Type' 	=> 'text/html'],
						body => $strMsgBody,);
    
	sendmail($email, { transport => $transport });
}
