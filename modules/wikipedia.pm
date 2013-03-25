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
our $wiki = undef;

sub init {
    my ( $self, $message, $args ) = @_;
    
    $wiki = WWW::Wikipedia->new( language => 'en' );
    $parser = HTML::Strip->new();
    
    $self->registerHook( 'said', \&handleSaidWikipedia );
}

sub handleSaidWikipedia {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ( $message->{body} =~ m/^!w(?:iki(?:pedia)?)? (.+)/ );
    $input = $1;
    
    if ( $input =~ m/^--lang=(\w{2}) (.+)/ ) {
        $wiki->language($1);
    }
    
    my $result = $wiki->search( $input );
    my $response = "Sorry $message->{who}, there is no article with titel '$input' on wikipedia.";
    
    if ( defined $result ) {
        my $raw = $result->raw();
        #print $raw . "\n\n\n";
        if( $raw =~ m/^\{\{dpintro\}\}/) {
            #verschillende entries!
            $raw =~ s/(\n|\r)//g;
            $raw =~ s/\{\{dpintro\}\}(.+?)\{\{dp\}\}/$1/gi;
            $raw =~ s/\[\[([^(\||\])]+|[^]]+)(?:.*?)\]\]/\[$1\]/gi;
            $raw =~ s/(==[\w\s]+==)/\* /;
            $raw = $stripper->parse($raw);
            $raw =~ tr/ / /s;
            $raw =~ s/ \./\./g;
            $raw =~ s/''/"/g;
            my @entries = split ( '\* ' , $raw );
            @entries = grep(/\S/, @entries);
            $response = join (", ", @entries);
        } else {
            $response = $result->text_basic();
            $response =~ s/\n//g;
            $response =~ s/\{\{.+?\}\}//g;
            $response =~ s/\[\[(.+?)\]\]/$1/g;
            $response = $stripper->parse($response);
            
            $response =~ tr/ / /s;
            $response =~ s/ \./\./g;
            $response =~ s/''/"/g;
        }
    }
    
    $wiki->language( 'en' );
    
    $server->{bot}->reply( $response, $message );
}