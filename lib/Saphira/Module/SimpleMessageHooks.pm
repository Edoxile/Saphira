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
        #$self->registerMessageHook(\&handleHighlightedCommands);
        #$self->registerMessageHook(\&handleLogging);
    }
    
    sub handleLogging {
        my ($self, $channel, $who, $body) = @_;
        my $chanFile = substr($channel,1);
    }

    sub handleUriTitle {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ /((?:https?:\/\/|www\.)[-~=\\\/a-zA-Z0-9\.:_\?&%,#\+]+)/);
        return if ($1 eq '');

        my $title = title( $1 );
        return unless defined($title);

        $self->{bot}->say( channel => $channel, who => $who, body => "[ $title ]" );
    }
    
    sub handleHighlightedCommands {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ m/^Saphira[\,\!\:]?\s{1,}(.+?)$/si);
        
        my $args = '';
        my $command = $1;
        if ($command =~ m/^(.+?)\s*(.*?)$/si) {
            $command = $1;
            $args = $2;
        }
        
        #$self->{bot}->{eventProcessor}->processCommand($channel, $who, $command, $args);
        
        return undef;
    }
    
    sub handleGreetings {
        my ($self, $channel, $who, $body) = @_;
        
        return unless ($body =~ /(greets|kicks|hits|spanks|thanks) Saphira/si);
        return if ($1 eq '');
        
        my $message = '';
        
        switch($1) {
            case /thanks/si        { $message = 'No problem ' . $who . '!'; }
            case /greets/si        { $message = 'Hey there ' . $who . '!'; }
            case /(hits|spanks)/si { $message = 'That\'s not nice ' . $who . '...'; }
            case /kicks/si {
                #TODO: check if we can kick first before spouting nonsense
                $self->{bot}->say( channel => $channel, who => $who, body => 'Thanks ' . $who . '! Let me return the favour!' );
                $self->{bot}->kick(who => $who, channel => $channel, body => 'Bye bye!' )
            }
        }

        $self->{bot}->say( channel => $channel, who => $who, body => $message );
    }

    1;
}
