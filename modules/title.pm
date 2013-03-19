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

package Saphira::Module::Title;
use base 'Saphira::Module';
use warnings;
use strict;

use URI::Title 'title';

sub init {
    my ( $self, $message, $args ) = @_;
    
    $self->registerHook('said', \&handleSaid);
}

sub handleSaid {
    my ($bot, $message) = @_;
    
    return unless ($message->{body} =~ /((?:https?:\/\/|www\.)[-~=\\\/a-zA-Z0-9\.:_\?&%,#\+]+)/);
    return if ($1 eq '');
    
    my $title = title($1);
    return unless defined($title);
    
    $bot->say(
        who     => $message->{who},
        channel => $message->{channel},
        body    => "[ $title ]",
        address => $message->{address}
    );
}

1;
