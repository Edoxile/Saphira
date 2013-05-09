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
        raw_script => shift,
        raw_input => shift,
        output => ''
    }, $class;
    
    $self->{script} = [ split '', $self->{raw_script} ];
    $self->{input} = [ split '', $self->{raw_input} ];
    
    return $self;
}

sub run {
    my ( $self, $ip, $sp, $inp )  = ( shift, 0, 0, 0 );
    my @stacks = ();
    while ( $ip < scalar ( @{$self->{script}} ) ) {
        switch ( @{$self->{script}}[$ip] ) {
            case '+' { $stacks[$sp]++; }
            case '-' { $stacks[$sp]--; }
            case '>' { $sp++; }
            case '<' { $sp--; return undef if $sp lt 0 }
            case '[' { $ip = $self->find_loop_end($ip) if $stacks[$sp] eq 0; return undef if not defined $ip; }
            case ']' { $ip = $self->find_loop_start($ip) if $stacks[$sp] ne 0; return undef if not defined $ip; }
            case '.' { $self->{output} .= chr ( $stacks[$sp] ); }
            case ',' { $stacks[$sp] = ($inp < ( scalar @{$self->{input}} ) ) ? ord ( @{$self->{input}}[$inp++] ) : 0 ; }
        }
        $ip++;
    }
    return $self->{output};
}

sub find_loop_start {
    my ($self, $ip) = @_;
    my $opens = 0;
    my @part = reverse @{$self->{script}}[0 .. $ip];
    foreach ( keys @part ) {
        $opens++ if $part[$_] eq ']';
        $opens-- if $part[$_] eq '[';
        return ($ip - $_) if $opens eq 0;
    }
    return undef;
}

sub find_loop_end {
    my ($self, $ip) = @_;
    my $opens = 0;
    my @part = @{$self->{script}}[$ip .. scalar(@{$self->{script}})];
    foreach ( keys @part ) {
        $opens++ if $part[$_] eq '[';
        $opens-- if $part[$_] eq ']';
        return ($ip + $_) if $opens eq 0;
    }
    return undef;
}

sub get_output {
    my $self = shift;
    $self->run() if $self->{output} eq '';
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
    $self->registerHook( 'said', \&handleSaidBrainify );
}

sub handleSaidBrainfuck {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{body} =~ m/^!bfq? ([\[\]\.\+\-<>,]+)(?: (.+?))?$/ );
    my $script = $1;
    my $input = $2 || '';
    print '>> Running brainfuck ' . ( $input ? 'with' : 'without' ) . " input, called by $message->{who} ( $message->{real_who} )\n";
    my $brainfuck = new Interpreter::Brainfuck($script, $input);
    my $output = $brainfuck->get_output();
    my $msg = $message->{real_who} . ': ' . ( ( defined $output and $output ne '' ) ? $output : 'Interpreter returned nothing. Invalid syntax?' );
    $server->{bot}->reply($msg, $message);
}

sub handleSaidBrainify {
    my ( $wrapper, $server, $message ) = @_;
    return unless ( $message->{body} =~ m/^!b(?:raini)?fy (.+?)$/ );
    
    my $input = $1;
    
    my $brainfuck = '';
    my $array_initializer = '';
    my $total_stacks = 0;
    my @stacks = ();
    my $stackPointer = 0;
    my $lookupPointer = -1;

    my @text = split '', $input;
    foreach my $char (@text) {
        my $ord = ord $char;
        while(my ($key,$value) = each(@stacks)) {
            if ( abs($value - $ord) <= 4 ) {
                if ( $lookupPointer == -1 ) {
                    $lookupPointer = $key;
                } elsif ( abs($stacks[$lookupPointer] - $ord) > abs($value - $ord) ) {
                    $lookupPointer = $key;
                }
            }
        }
        if ($lookupPointer lt 0) {
            $total_stacks++;
            my $plusses = int ( $ord / 8 );
            my $leftover = $ord % 8;
            my $sign = '+';
            if ($leftover gt 4) {
                $plusses++;
                $leftover = 8 - $leftover;
                $sign = '-';
            }
            $array_initializer .= '>' . ('+' x $plusses);
            my $stackdiff = scalar(@stacks) - $stackPointer;
            $brainfuck .= '>' x $stackdiff . $sign x $leftover . '.';
            push @stacks, $ord;
            $stackPointer = scalar(@stacks) - 1;
        } else {
            my $stackdiff = $lookupPointer - $stackPointer;
            my $leftover = $ord - $stacks[$lookupPointer];
            $brainfuck .= (($stackdiff gt 0?'>':'<')x abs($stackdiff)) . (($leftover lt 0?'-':'+') x abs($leftover)) . '.';
            $stackPointer = $lookupPointer;
            $stacks[$stackPointer] = $ord;
        }
        $lookupPointer = -1;
    }
    $brainfuck = '++++++++[' . $array_initializer . ('<'x$total_stacks) . '-]>' . $brainfuck;
    
    my $msg = $message->{real_who} . ": $brainfuck";
    
    if ( ( $message->{channel} ne 'msg' ) and ( length ( $brainfuck ) > 250 ) ) {
       $msg = "I'm sorry $message->{real_who}, but your program is too long [".length($brainfuck)."] and to prevent spam I can't post it. You could ask me in a private message though!";
    }
    
    $server->{bot}->reply($msg, $message);
}

1;