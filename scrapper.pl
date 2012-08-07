###################
# nikolay christov
# 8.6.12
# demo app for scraping the DOM from jboss.org/projects 
###################

#!/usr/bin/perl

use strict;
use warnings;

require LWP::UserAgent;
use Text::CSV;
use HTML::TreeBuilder 5 -weak;

###################
# Function Declaration
###################
sub trim($);

###################
# My Variables
###################
my $html;
my $pageURL = "https://www.jboss.org/projects";
#$pageURL = "https://raw.github.com/nmchristov/DOMscraper/master/source2.html";
my $domain = "https://www.jboss.org";
my @records;
my $i;
my $outputFile = 'data.csv';


my $ua = LWP::UserAgent->new;
$ua->timeout(10);
$ua->env_proxy;
 
 
my $response = $ua->get($pageURL);
 
 if ($response->is_success) {
     #get the DOM
     $html = $response->decoded_content; 
 }
 else {
     die $response->status_line;
 }
 
# parse the DOM into tree 
my $tree = HTML::TreeBuilder->new;
$tree->parse($html);

#get the <table...> with projects and take all the <tr> elems into arr
#my $table = $tree->look_down('_tag' => 'table', 'class' => 'simpletablestyle');
my $table=undef;
my @tables = $tree->look_down('_tag' => 'table', 'class' => 'simpletablestyle');

for my $i (0 .. $#tables){
	if(defined($tables[$i]->look_down('_tag' => 'th'))){
		if($tables[$i]->look_down('_tag' => 'th')->as_text eq "Project"){
			$table = $tables[$i];
			last;
		}
	}
}

if(defined($table) == 0 ){
	print "no qualified table found\n";
	exit 0;
}

my @rows = $table->look_down('_tag', 'tr');

#loop through the rows and isolate requested values in vars
for my $row (@rows){
	my @cols = $row->look_down('_tag', 'td');
	if($cols[0] and $cols[1]){
		#no memory conserns  so we can isolate in separate vars
		my $projectName = trim($cols[0]->as_text);
		my $projectURL = getURL($cols[0]);
		my $downloadURL = getURL($cols[1]);
		my $docURL = getURL($cols[2]);
		my $issueURL = getURL($cols[4]);
		my $codeURL = getURL($cols[5]);
		my $license = getText($cols[6]);
		my $licenseURL = getURL($cols[6]);
		
		#print $i,"\n",$projectName,"\n",$projectURL,"\n",$downloadURL,"\n",$docURL,"\n",$issueURL,"\n",$codeURL,"\n",$license,"\n",$licenseURL;
		#assemble array w/ values from single row and push in the arr of records
		my @record = ($projectName, $projectURL, $downloadURL, $docURL, $issueURL, $codeURL, $license, $licenseURL);
		push(@records, [@record]);
	}
}

#write the content of @records in csv file
writeCSV();

#destroy the tree
$tree->delete;
##############
# END
##############


##############
# Functions
##############

sub writeCSV{
	#if file does not exist create one, if does exist will overwrite
	my $csv = Text::CSV->new ( { always_quote => 1 } );
	open my $fh, '>', $outputFile or die $!;
	
	#number arrays -> columns
	#print scalar(@records);
	$csv->eol("\r\n");
	
	
	for $i ( 0 .. $#records ) {
		$csv->print($fh, $records[$i]);
	}
	
	$csv->eof or $csv->error_diag();
	close $fh;
		 
}


sub getText{
	my $urlObj = shift;
	if(!defined $urlObj->look_down('_tag', 'a')){
		#return "null";
		return "";
	}
	
	return  $urlObj->look_down('_tag', 'a')->as_text;
}


sub getURL{
	my $urlObj = shift;
   
	if(!defined $urlObj->look_down('_tag', 'a')){
		#return "null";
		return "";
	}
   
	my $url = $urlObj->look_down('_tag', 'a')->as_HTML;
   
	if($url){
		my $lindex = index($url, "\"")+1;
		my $rindex = index($url, "\"", $lindex);
		$url = substr($url, $lindex, $rindex-$lindex);
	} else {
		return "";
	}
   
	if(substr($url, 0, 1) eq "/"){
		$url = $domain.$url;
	}
   
	return $url;
}


# Trim (left and right) function to remove leading and trailing whitespaces (uses ltrim and rtrim)
sub trim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	$string =~ s/\s+$//;
	return $string;
}
# Left trim function to remove leading whitespace
sub ltrim($)
{
	my $string = shift;
	$string =~ s/^\s+//;
	return $string;
}
# Right trim function to remove trailing whitespace
sub rtrim($)
{
	my $string = shift;
	$string =~ s/\s+$//;
	return $string;
}
  
  
  
  
  
  
  
  