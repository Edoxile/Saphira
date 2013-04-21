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

package Interpreter::Brainfuck;
use Switch;

sub new {
    my $class = shift;
    my $self = bless {
        script => [ split('', shift) ],
        input => [ split('', shift) ],
        output => undef
    }, $class;
    return $self;
}

sub run {
    my ( $self, $ip, $sp, $inp, $size, $stacks )  = ( shift, 0, 0, 0, scalar @{$self->{script}}, () );
    while ( $ip < scalar @{$self->{script}} ) {
        switch ( @{$self->{script}}[$ip] ) {
            case '+' { $stacks[$sp]++; }
            case '-' { $stacks[$sp]--; }
            case '>' { $sp++; }
            case '<' { $sp--; return undef if $sp lt 0 }
            case '[' { $ip = $self->find_loop_end($ip) if $stacks[$sp] eq 0; return undef if not defined $ip; }
            case ']' { $ip = $self->find_loop_start($ip) if $stacks[$sp] ne 0; return undef if not defined $ip; }
            case '.' { $self->{output} .= chr ( $stacks[$sp] ); }
            case ',' { $stacks[$sp] = @{$self->{input}}[$inp]; $inp++; }
        }
        $ip++;
    }
    return $self->{output};
}

sub find_loop_start {
    my ($self, $ip) = @_;
    my ($opens, @part) = ( 0, reverse @{$self->{script}}[0 .. $ip] );
    foreach ( keys @part ) {
        $opens++ if $part[$_] eq ']';
        $opens-- if $part[$_] eq '[';
        return ($ip - $_) if $opens eq 0;
    }
    return undef;
}

sub find_loop_end {
    my ($self, $ip) = @_;
    my ($opens, @part) = ( 0, @{$self->{script}}[$ip .. scalar(@{$self->{script}})] );
    foreach ( keys @part ) {
        $opens++ if $part[$_] eq '[';
        $opens-- if $part[$_] eq ']';
        return ($ip + $_) if $opens eq 0;
    }
    return undef;
}

sub get_output {
    my $self = shift;
    $self->run if not defined $self->{output};
    return $self->{output};
}

package Saphira::Module::Brainfuck;
use base 'Saphira::Module';
use warnings;
no warnings 'redefine';
use strict;

sub init {
    my ( $self, $message, $args ) = @_;
    $self->registerHook( 'said', \&handleSaidBrainfuck );
}

sub handleSaidBrainfuck {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{body} =~ m/^!bfq? ([\[\]\.\+\-<>,]+)(?: (.+?))?/ );
    my $script = $1;
    my $input = $2 || '';
    my $brainfuck = new Interpreter::Brainfuck($script, $input);
    my $output = $brainfuck->run();
    my $msg = $message->{real_who} . ': ' . ( ( defined $output ) ? $output : 'Interpreter returned nothing. Invalid syntax?' );
    $server->{bot}->reply($msg, $message);
}

1;