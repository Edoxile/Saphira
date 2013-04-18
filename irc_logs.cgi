#!/usr/bin/env perl

=begin comment
Copyright (c) 2013.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.

=end comment
=cut

use warnings;
use strict;
use Config::IniFiles;
use JSON::XS;
use IRC::Formatting::HTML 'irc_to_html';
use DBI;

print "Content-type: text/html\n\n";

my $channel = $ENV{'QUERY_STRING'} || exit;
$channel =~ s/(?:.*?)channel=(.+?)&?(?:.*?)/$1/;

die ( 'No config file found... Returning...' ) unless ( -e '/srv/perl/config.ini' );

my $cfg = Config::IniFiles->new( -file => '/srv/perl/config.ini' );
my $dbd = DBI->connect(
    sprintf( 'DBI:mysql:%s;host=%s', $cfg->val('mysql', 'database'), $cfg->val('mysql', 'host') ),
    $cfg->val('mysql', 'username'),
    $cfg->val('mysql', 'password'),
    { 'mysql_enable_utf8' => 1 }
);
$dbd->do('SET NAMES utf8');
my $parser = JSON::XS->new->ascii->allow_nonref;

my $ps = $dbd->prepare("SELECT type,DATE_FORMAT(posttime,'%d/%c/%Y %H:%i:%s') as posttime,who,raw_body FROM Tweakers_logs WHERE channel = ? ORDER BY posttime DESC LIMIT 100");
$ps->execute( '#' . $channel );
if ( $ps->err ) {
    print "MySQL error: $ps->errno\n";
    exit;
}

my $data = $ps->fetchall_arrayref({});

while (my ($key, $value) = each $data ) {
    @{$data}[$key]->{raw_body} = irc_to_html($value->{raw_body});
}

my $output = $parser->encode($data);

print "{\"logs\":$output}\n";

1;
__END__;
