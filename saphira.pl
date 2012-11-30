#!/usr/bin/env perl
use warnings;
use strict;
use Config::File;
use Saphira::Bot;

package Saphira;

my $conf = Config::File::read_config_file(shift @ARGV || "bot.conf");
my $nick = shift @ARGV || $conf->{NICK} || "Saphira";
my $nspassword = $conf->{NICKSERVPASS} || undef;
my $server = $conf->{SERVER} || "irc.tweakers.net";
my $port = $conf->{PORT} || 6697;
my $ssl = int($conf->{SSL}) || 1;
my $channels = [ split m/\s+/, $conf->{CHANNEL}];

my $sarah = Saphira::Bot->new(
    server     => $server,
    port       => $port,
    ssl        => $ssl,
    channels   => $channels,
    nick       => $nick,
    nspassword => $nspassword,
    alt_nicks  => ["PerlBot"],
    username   => "saphira",
    name       => "Saphira, a Perl IRC Bot by Edoxile",
    charset    => "utf-8", 
);
$sarah->run();