package Saphira::Bot;
{
    use base 'Bot::BasicBot';
    use DateTime;
    use Saphira::EventProcessor;
    
    sub getDateTime {
        my $self = shift;
        my $currDate = DateTime->now;
        return $currDate->ymd.' ' . $currDate->hms;
    }
    
    sub init {
        my $self = shift;
        $self->{eventProcessor} = new Saphira::EventProcessor($self);
        
        return 1;
    }

    sub said {
        my $self = shift;
        my $data = shift;
        
        if ( $data->{body} =~ m/^(\S\d*<\S{1,}>\s+)*!(.+?)$/si ) { #m/^!(.+?)$/si ){
            
            my $fullCommand = $2;
            if( $fullCommand =~ /^(.+?)\s+(.+?)$/si ) {
                $self->{eventProcessor}->process_command($data->{channel}, $data->{who}, $1, $2);
            } else {
                $self->{eventProcessor}->process_command($data->{channel}, $data->{who}, $fullCommand, '');
            }               
            return undef;
        } else {
            $self->{eventProcessor}->process_message($data->{channel}, $data->{who}, $data->{body});
            return undef;
        }
    }
    
    sub invited {
        $self = shift;
        $data = shift;
        print '>> Invited to channel ' . $data->{channel} . ' by ' . $data->{who} . "\n";
        $self->join( channel => $data->{channel} );
    }

    sub emoted {
        my $self = shift;
        my $data  = shift;
        
        $self->{eventProcessor}->process_emoted($data->{channel}, $data->{who}, $data->{body});
        return undef;
    }

    sub noticed {
        my $self = shift;
        my $data  = shift;
        #print 'N: [' . $self->getDateTime() . '] {' . $data->{channel} . '} <' . $data->{who} . '> ' . $data->{body} . "\n";
        return undef;
    }

    sub chanjoin {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{who} . ' joined channel ' . $data->{channel}."\n";
        return undef;
    }

    sub chanquit {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{who} . ' quit channel ' . $data->{channel} . ' : ' . $data->{body} . "\n";
        return undef;
    }

    sub chanpart {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{who} . ' parted channel ' . $data->{channel} . ' : ' . $data->{body} . "\n";
        return undef;
    }

    sub userquit {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{who} . ' quit: ',$data->{body} . "\n";
    }

    sub topic {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{who} . ' changed topic of {' . $data->{channel} . '}: ' . $data->{topic} . "\n";
        
        return undef;
    }

    sub nick_change {
        my $self = shift;
        my($old, $new) = @_;
        #print ' * [' . $self->getDateTime() . '] ' . $old . ' is now called ' . $new . "\n";
        return undef;
    }

    sub kicked {
        my $self = shift;
        my $data  = shift;
        #print ' * [' . $self->getDateTime() . '] ' . $data->{kicked} . ' was kicked from channel by ' . $data->{who} . ' ' . $data->{channel} . ' : ' . $data->{reason} . "\n";
        return undef;
    }

    sub help {
        my $self = shift;
        return "This is an irc bot written in perl.";
    }
    
    1;
}