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

use WWW::Wikipedia;
use HTML::Strip;

our $parser = undef;
our $wiki   = undef;

sub init {
    my ( $self, $message, $args ) = @_;

    $wiki = WWW::Wikipedia->new( language => 'nl' );
    $parser = HTML::Strip->new();

    $self->registerHook( 'said', \&handleSaidWikipedia );
}

sub handleSaidWikipedia {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!w(?:iki(?:pedia)?)? (.+)/ );
    my $input = $1;
    my $lang  = 'nl'

      if ( $input =~ m/^--lang=(\w{2}) (.+)/ ) {
        $lang = $1;
        $wiki->language($lang);
        $input = $2;
    }

    print '>> Wikipedia query: [' . $input . '] using language: ' . $lang . "\n";

    my $result   = $wiki->search($input);
    my $response = "Sorry $message->{who}, there is no article with titel '$input' on wikipedia.";

    if ( defined $result ) {
        my $raw = $result->raw();
        if ( $raw =~ m/^\{\{dpintro\}\}/ ) {
            $raw =~ s/(\n|\r)//g;
            $raw =~ s/\{\{dpintro\}\}(.+?)\{\{dp\}\}/$1/gi;
            $raw =~ s/\[\[([^(\||\])]+|[^]]+)(?:.*?)\]\]/\[$1\]/gi;
            $raw =~ s/(==[\w\s]+==)/\* /;
            $raw = $parser->parse($raw);
            $raw =~ tr/ / /s;
            $raw =~ s/ \./\./g;
            $raw =~ s/''/"/g;
            my @entries = split( '\* ', $raw );
            @entries = grep( /\S/, @entries );
            $response = join( ", ", @entries );
        } else {
            $response = $result->text_basic();
            $response =~ s/\n//g;
            $response =~ s/\{\{.+?\}\}//g;
            $response =~ s/\[\[(.+?)\]\]/$1/g;
            $response = $parser->parse($response);

            $response =~ tr/ / /s;
            $response =~ s/ \./\./g;
            $response =~ s/''/"/g;
        }
    }

    $wiki->language('nl') if $lang ne 'nl';

    $server->{bot}->reply( $response, $message );
}

1;
