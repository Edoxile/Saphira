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

package Saphira::Module::Wikipedia;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

use LWP::Simple;
use JSON::XS;

our $parser = undef;
our $wiki   = undef;

sub init {
    my ( $self, $message, $args ) = @_;

    $parser = JSON::XS->new->ascii->pretty->allow_nonref;

    $self->registerHook( 'said', \&handleSaidWikipedia );
}

sub handleSaidWikipedia {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!w(?:iki(?:pedia)?)? (.+)/ );
    my $page = $1;
    my $lang  = 'nl';

    if ( $input =~ m/^--lang=(\w{2}) (.+)/ ) {
        $lang = $1;
        $page = $2;
    }

    print '>> Wikipedia query: [' . $page . '] using language: ' . $lang . "\n";

    my $url =
      'http://' . $lang . '.wikipedia.org/w/api.php?format=json&action=query&prop=revisions&rvprop=content&titles=';
    my $reply = "I'm sorry $message->{who}, but I can't find anything for '$input' on Wikipedia...";

    my $raw_data = get( $url . $page );
    my $data     = $parser->decode($raw_data);
    my @pageID   = keys( $data->{query}->{pages} );

    if ( int( $pageID[0] ) gt 0 ) {
        my $revision = shift $data->{query}->{pages}->{ $pageID[0] }->{revisions};
        if ( $revision->{'*'} =~ m/^#REDIRECT \[\[(.+?)\]\]/ ) {
            $page     = $1;
            $raw_data = get( $url . $page );
            $data     = $parser->decode($raw_data);
            @pageID   = keys( $data->{query}->{pages} );
            $revision = shift $data->{query}->{pages}->{ $pageID[0] }->{revisions};
        }
        my $wikidata = $revision->{'*'};
        $wikidata =~ s/\{\{.+?\}\}//gs;
        if ( $wikidata =~ m/'''$data->{query}->{pages}->{$pageID[0]}->{title}''' may refer to:\n\n(.+?)$/s ) {
            $wikidata = $1;
            $wikidata =~ s/==.+?==\n//gs;
            $wikidata =~ s/\n+/\n/gs;
            $wikidata =~ s/\[\[([^\|\]]+)(?:|(.+?))?\]\]/\[$1\]/g;
            $wikidata =~ s/^\*//gm;
            $wikidata =~ s/(\S)\n(\S)/$1; $2/g;
            $wikidata = $page . ' may refer to: ' . $wikidata;
        } else {
            $wikidata =~ s/^\s+(.+?)\n\n.+$/$1/gs;
            $wikidata =~ s/<ref(.+?)\/ref>//gi;
            $wikidata =~ s/\[\[([^\|\]]+)(?:|(.+?))?\]\]/$1/g;
            $wikidata =~ s/'''(.+?)'''/\x02$1\x0F/g;
            $wikidata =~ s/''/"/g;
        }
        $wikidata = ( ( length($wikidata) > 296 ) ? ( substr( $wikidata, 0, 293 ) . '...' ) : $wikidata );
        $url      = $data->{query}->{pages}->{ $pageID[0] }->{title};
        $url      = s/\s/_/g;
        $reply = $message->{who} . ": Wikipedia entry for '$page' (http://$lang.wikipedia.org/wiki/$url): $wikidata";
    }
    $server->{bot}->reply( $reply, $message );
}

1;
