#!/usr/bin/env perl

#	Copyright 2017, VIA Technologies, Inc. & OLAMI Team.
#
#	Licensed under the Apache License, Version 2.0 (the "License");
#	you may not use this file except in compliance with the License.
#	You may obtain a copy of the License at
#
#	http://www.apache.org/licenses/LICENSE-2.0
#
#	Unless required by applicable law or agreed to in writing, software
#	distributed under the License is distributed on an "AS IS" BASIS,
#	WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#	See the License for the specific language governing permissions and
#	limitations under the License.

use strict;
use warnings;
use Data::Dumper qw(Dumper);
use Time::HiRes qw/gettimeofday/;
use Math::Round;
use Digest::MD5 qw(md5 md5_hex md5_base64);
use LWP::UserAgent;
use Encode qw/encode decode/;
use Devel::CheckOS qw(die_unsupported os_is);

my $argc         = @ARGV;
my $API_NAME_SEG = "seg";
my $API_NAME_NLI = "nli";
my $isWin        = os_is('MicrosoftWindows');

my $apiBaseUrl;

# $param appKey the AppKey you got from OLAMI developer console.
my $appKey;

# $param appSecret the AppSecret you from OLAMI developer console.
my $appSecret;

# Setup localization to select service area, this is related to different
# server URLs or languages, etc.
# $param apiBaseURL URL of the API service.
sub setLocalization {
	my ($url) = @_;
	$apiBaseUrl = $url;
}

# Setup your authorization information to access OLAMI services.
#
# $param appKey the AppKey you got from OLAMI developer console.
# $param appSecret the AppSecret you from OLAMI developer console.
sub setAuthorization {
	my ( $key, $secret ) = @_;
	$appKey    = $key;
	$appSecret = $secret;
}

# Get the NLU recognition result for your input text.
#
# $param inputText the text you want to recognize.
my $inputText;

sub getRecognitionResult {
	my ( $api, $input ) = @_;
	$inputText = $input;

	my $timestamp = gettimeofday;
	$timestamp = round( 1000 * $timestamp );

	# Prepare message to generate an MD5 digest.
	my $signMsg =
	    $appSecret 
	  . "api="
	  . $api
	  . "appkey="
	  . $appKey
	  . "timestamp="
	  . $timestamp
	  . $appSecret;

	# Generate MD5 digest.
	my $sign = md5_hex($signMsg);

	# Assemble all the HTTP parameters you want to send
	my %array_postData;
	$array_postData{'api'}       = $api;
	$array_postData{'appkey'}    = $appKey;
	$array_postData{'timestamp'} = $timestamp;
	$array_postData{'sign'}      = $sign;

	# for windows: it need to decode inputText and encode result to utf8
	my $encoding = "gb2312";
	if ( index( $apiBaseUrl, "cn" ) != -1 ) {

		#inputText is Simplified Chinese
		$encoding = "gb2312";
	}
	elsif ( index( $apiBaseUrl, "tw" ) != -1 ) {

		#inputText is Traditional Chinese
		$encoding = "big5";
	}

	my $utf8_inputText =
	  $isWin eq 1
	  ? encode( "utf-8", decode( $encoding, $inputText ) )
	  : $inputText;

	if ( $api eq $API_NAME_SEG ) {
		$array_postData{'rq'} = $utf8_inputText;
	}
	elsif ( $api eq $API_NAME_NLI ) {
		$array_postData{'rq'} =
		  '{"data_type":"stt","data":{"input_type":1,"text":"'
		  . $utf8_inputText . '"}}';
	}

	# Request NLU service by HTTP POST
	my $ua = LWP::UserAgent->new;

	my $response = $ua->post( $apiBaseUrl, \%array_postData );
	my $message;
	if ( $response->is_success ) {
		$message = $response->content;
	}
	else {
		$message = $response->message;
	}

	# Now you can check the status here.
	print "Sending 'POST' request to URL : ", $apiBaseUrl, "\n";
	print "Post parameters : ", Dumper \%array_postData, "\n";
	print "Response Code : ", $response->code, "\n";

	my $result =
	  $isWin eq 1 ? encode( $encoding, decode( "utf-8", $message ) ) : $message;
	return $result;
}

# main program
unless ( $argc >= 4 ) {
	print "\n\n[Error] Missing args! Usage:\n";
	print " - args[0]: api_url\n";
	print " - args[1]: your_app_key\n";
	print " - args[2]: your_app_secret\n";
	print " - args[3]: your_text_input\n";
	print "\n\n";
	exit;
}

setLocalization( $ARGV[0] );
setAuthorization( $ARGV[1], $ARGV[2] );

print "\n---------- Test NLU API, api=seg ----------\n";
print "\nResult:\n\n", getRecognitionResult( $API_NAME_SEG, $ARGV[3] ), "\n";

print "\n---------- Test NLU API, api=nli ----------\n";
print "\nResult:\n\n", getRecognitionResult( $API_NAME_NLI, $ARGV[3] ), "\n";

