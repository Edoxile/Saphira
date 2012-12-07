package Saphira::Module::SimpleMessageHooks;

{
    use base 'Saphira::Module';
    use warnings;
    use strict;
    use Switch;
    
    use URI::Title qw( title );
    
    sub init {
        my $self = shift;

        # Register hooks
        $self->registerMessageHook(\&handleUriTitle);
        $self->registerEmotedHook(\&handleGreetings);
    }

    sub handleUriTitle {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ /((?:https?:\/\/|www\.)[-~=\\\/a-zA-Z0-9\.:_\?&%,#\+]+)/);
        return if ($1 eq '');

        my $title = title( $1 );
        return unless defined($title);

        $self->{bot}->say( channel => $channel, who => $who, body => "[ $title ]" );
    }
    
    sub handleCommands {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ /^Saphira(,|:)?\s+(.+?)$/si);
        
        my $args = '';
        my $command = $2;
        if( $command =~ /^(\w+)\s+(.+?)$/si ) {
            $command = $1;
            $args = $2;
        }
        
        # run command through the eventProcessor
        $self->{bot}->{eventProcessor}->processCommand($channel, $who, $command, $args);
    }
    
    sub handleGreetings {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ /(greets|kicks|hits|spanks) Saphira/si);
        return if ($1 eq '');
        
        my $message = '';
        
        switch($1) {
            case /greets/si              { $message = 'Hey there ' . $who . '!'; }
            case /(hits|spanks|kicks)/si { $message = 'That\'s not nice ' . $who . '...'; }
        }

        $self->{bot}->say( channel => $channel, who => $who, body => $message );
    }

    1;
}