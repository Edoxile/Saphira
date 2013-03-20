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

package Saphira::Module::Google;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

use Google::Search;
use HTML::Entities;
use Encode;

sub handleWebSearch {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ($message->{body} =~ m/^!g(?:oogle)? (.+?)$/);
    
    print '>> Google search term: [ ' . $1 . " ]\n";
    
    my $search = Google::Search->Web( hl => 'nl', query => $1 );
    my $result = $search->first;

    if (!defined($result)) {
        $server->{bot}->reply( 'I\'m Sorry ' . $message->{who} . ', I can\'t find anything for \'' . $1 . '\' on Google.', $message );
    } else {
        my $reply = $message->{who} . ': ' . decodeTitle( HTML::Entities::decode( $result->titleNoFormatting ) ) . ' - ' . $result->uri;
        $server->{bot}->reply( $reply, $message );
    }
}

sub handleYoutubeSearch {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ($message->{body} =~ m/^!y(?:outube)? (.+?)$/);
    
    print '>> Youtube search term: [ ' . $1 . " ]\n";
    
    my $search = Google::Search->Web( hl => 'nl', query => 'site:youtube.com ' . $1 );
    my $result = $search->first;

    if (!defined($result)) {
        $server->{bot}->reply( 'I\'m Sorry ' . $message->{who} . ', I can\'t find anything for \'' . $1 . '\' on Youtube.', $message );
    } else {
        my $reply = $message->{who} . ': ' . decodeTitle( HTML::Entities::decode( $result->titleNoFormatting ) ) . ' - ' . $result->uri;
        $server->{bot}->reply( $reply, $message );
    }
}

sub handleImageSearch {
    my ( $wrapper, $server, $message ) = @_;
    
    return unless ($message->{body} =~ m/^!g(?:oogle)?i(?:mages) (.+?)$/);
    
    print '>> Google image search term: [ ' . $1 . " ]\n";
    
    my $search = Google::Search->Image( hl => 'nl', query => $1 );
    my $result = $search->first;

    if (!defined($result)) {
        $server->{bot}->reply( 'I\'m Sorry ' . $message->{who} . ', I can\'t find anything for \'' . $1 . '\' on Google Images.', $message );
    } else {
        my $reply = $who . ': ' . $result->uri;
        $server->{bot}->reply( $reply, $message );
    }
}
    
sub decodeTitle {
    my $title = shift;
    $title = decode('utf-8', $title, 1) || $title;
    $title =~ s/\s+$//;
    $title =~ s/^\s+//;
    $title =~ s/\n+//g;
    $title =~ s/\s+/ /g;
    $title = decode_entities($title);
    $title =~ s/(&\#(\d+);?)/chr($2)/eg;
    return $title;
}

1;
