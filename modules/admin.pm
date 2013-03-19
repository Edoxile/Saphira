#!/usr/bin/env perl

package Saphira::Module::Manage;
use base 'Saphira::Module';

sub init {
    my ( $self, $message, $args ) = @_;

    $self->registerHook( 'said', \&handleSaidKick );

    #$self->registerHook('said', \&handleSaidInvite);
}

sub getAuthLevel {
    my ( $server, $message ) = @_;
    my $user = $server->getUser( $message->{raw_nick} );
    return 0 unless defined $user;
    return 9 if $user->isOperator();
    return 6 if $user->isChannelOperator();
    return $user->getPermission( $message->{channel} );
}

sub handleSaidKick {
    my ( $wrapper, $server, $message ) = @_;

    return unless ( $message->{body} =~ m/^!kick\s(.+?)(?:\s(.+?))$/ );

    $server->getChannel( $message->{channel} )->kick( $1, $2 );
}

1;
