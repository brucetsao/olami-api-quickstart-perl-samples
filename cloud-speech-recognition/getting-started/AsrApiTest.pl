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
use File::Slurp;

my $argc         = @ARGV;
my $API_NAME_ASR = "asr";

my $apiBaseUrl;

# $param appKey the AppKey you got from OLAMI developer console.
my $appKey;

# $param appSecret the AppSecret you from OLAMI developer console.
my $appSecret;

# $param cookie save cookie response from server
my $cookie;

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

# Generate and get a basic HTTP query string
#
# $param api the API name for 'api=xxx' HTTP parameter.
# $param seq the value of 'seq' for 'seq=xxx' HTTP parameter.
sub getBasicQueryString {
	my ( $api, $seq ) = @_;

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
	my $postData = "api="
	  . $api
	  . "&appkey="
	  . $appKey
	  . "&timestamp="
	  . $timestamp
	  . "&sign="
	  . $sign 
	  . "&seq="
	  . $seq;

	return $postData;
}

# Send an audio file to speech recognition service.
#
# $param api the API name for 'api=xxx' HTTP parameter.
# $param seq the value of 'seq' for 'seq=xxx' HTTP parameter.
# $param finished TRUE to finish upload or FALSE to continue upload.
# $param filepath the path of the audio file you want to upload.
# $param compressed TRUE if the audio file is a Speex audio.
sub sendAudioFile {
	my ( $api, $seq, $finished, $filepath, $compressed ) = @_;

	# Read the input audio file
	my $audioData = read_file( $filepath, { binmode => ':raw' } );

	my $compressStopData =
	    "&compress="
	  . ( $compressed eq "True" ? "1" : "0" )
	  . "&stop="
	  . ( $finished eq "True" ? "1" : "0" );
	my $postData = getBasicQueryString( $api, $seq ) . $compressStopData;

	#Request speech recognition service by HTTP POST
	my $ua = LWP::UserAgent->new;

	#composite target url
	my $url = $apiBaseUrl . "?" . $postData;

	#post with binary data
	my $response = $ua->post(
		$url,
		'connection'   => 'Keep-Alive',
		'content-type' => 'application/octet-stream',
		'Content'      => $audioData
	);

	#print Dumper $response;
	my $message;
	if ( $response->is_success ) {
		$message = $response->decoded_content;
	}
	else {
		$message = $response->message;
	}

	# Now you can check the status here.
	print "Sending 'POST' request to URL : ", $apiBaseUrl, "\n";
	print "Post parameters : ",               $postData,   "\n";
	print "Response Code : ", $response->code, "\n";

	# Get cookie
	$cookie = get_headers_field( $response, "Set-Cookie" );
	if ( $cookie eq '' ) {
		print "Failed to get cookies.";
	}
	else {
		print "Cookies : ", $cookie, "\n";
	}

	return $message;
}

# extract value of header field which from response of post.
#
# $param response response handle after send post request.
# $param target_header_field the field name of header.
sub get_headers_field {
	my ( $response, $target_header_field ) = @_;
	my $headers                   = $response->headers;
	my $target_header_field_value = '';
	for my $header_field_name ( $headers->header_field_names ) {
		if ( $header_field_name eq $target_header_field ) {
			$target_header_field_value = $headers->header($header_field_name);
			last;
		}
	}
	return $target_header_field_value;
}

# Get the speech recognition result for the audio you sent.
#
# $param apiName the API name for 'api=xxx' HTTP parameter.
# $param seqValue the value of 'seq' for 'seq=xxx' HTTP parameter.
sub getRecognitionResult {
	my ( $api, $seq ) = @_;

	my $postData = getBasicQueryString( $api, $seq ) . "&stop=1";

	# Request speech recognition service by HTTP GET
	my $ua  = LWP::UserAgent->new;
	my $url = $apiBaseUrl . "?" . $postData;

	my $response = $ua->get( $url, 'Cookie' => $cookie );

	#print Dumper $response;
	my $message;
	if ( $response->is_success ) {
		$message = $response->decoded_content;
	}
	else {
		$message = $response->message;
	}

	# Now you can check the status here.
	print "Sending 'GET' request to URL : ", $apiBaseUrl, "\n";
	print "Query String : ",                 $postData,   "\n";
	print "Response Code : ", $response->code, "\n";

	return $message;
}

# main program
unless ( $argc >= 5 ) {
	print "\n\n[Error] Missing args! Usage:\n";
	print " - args[0]: api_url\n";
	print " - args[1]: your_app_key\n";
	print " - args[2]: your_app_secret\n";
	print " - args[3]: your_audio_file\n";
	print " - args[4]: compress_flag=[0|1]\n";
	print "\n\n";
	exit;
}

if ( $ARGV[4] ne '0' and $ARGV[4] ne '1' ) {
	print "compress_flag must be 0 or 1.\n";
	exit;
}

my $compressed = $ARGV[4] eq '1' ? "True" : "False";

setLocalization( $ARGV[0] );
setAuthorization( $ARGV[1], $ARGV[2] );

# Start sending audio file for recognition
print "\n----- Test Speech API, seq=nli,seg -----\n";
print "\nSend audio file... \n";
my $responseString =
  sendAudioFile( $API_NAME_ASR, "nli,seg", "True", $ARGV[3], $compressed );
print "\n\nResult:\n\n", $responseString, "\n\n";

# Try to get recognition result if uploaded successfully.
# We just check the state by a lazy way :P , you should do it by JSON.
if ( index( lc($responseString), "error" ) == -1 ) {
	print "\n----- Get Recognition Result -----\n";
	sleep(1);

	# Try to get result until the end of the recognition is complete
	while (1) {
		$responseString = getRecognitionResult( $API_NAME_ASR, "nli,seg" );
		print "\n\nResult:\n\n", $responseString, "\n";

		# Well, check by lazy way...again :P , do it by JSON please.
		if ( index( lc($responseString), "\"final\":true" ) == -1 ) {
			print "The recognition is not yet complete.\n";
			if ( index( lc($responseString), "error" ) != -1 ) {
				last;
			}
			sleep(2);
		}
		else {
			last;
		}
	}
}

print "\n\n";

