package Saphira::Module::Admin;

{
    use base 'Saphira::Module';
    use warnings;
    use strict;
    use Config::File;
    
    my $admins = {};
    my $password = '';
    
    sub init {
        my $self = shift;
        
        my $conf = Config::File::read_config_file("bot.conf");
        $password = $conf->{NICKSERVPASS};
        
        foreach ( split m/\s*,\s*/, $conf->{ADMINS} ) {
            if( $_ =~ m/(.+?)\s+(.+?)/ ) {
                $admins->{$1} = $2;
            }
        }
        
        print '>> Admins: ' . join( ', ', keys $admins ) . "\n";
        
        #$self->registerCommandHook(m/^join$/si, \&handleJoin);
        #$self->registerCommandHook(m/^part$/si, \&handlePart);
        #$self->registerCommandHook(m/^l(s|ist)admins$/si, \&handleListAdmins);
        #$self->registerCommandHook(m/^quit$/si, \&handleQuit);
        #$self->registerCommandHook(m/^kick$/si, \&handleKick);
        #$self->registerCommandHook(m/^help$/si, \&handleHelp);
        
        $self->registerCommandHook('join', \&handleJoin);
        $self->registerCommandHook('part', \&handlePart);
        $self->registerCommandHook('listadmins', \&handleListAdmins);
        $self->registerCommandHook('quit', \&handleQuit);
        $self->registerCommandHook('kick', \&handleKick);
        $self->registerCommandHook('help', \&handleHelp);
    }
    
    sub handleJoin {
        my ($self, $channel, $who, $join) = @_;
        print '>> Joining channel ' . $join . "\n";
        $self->{bot}->join( channel => $join );
    }
    
    sub handlePart {
        my ($self, $channel, $who, $part) = @_;
        if( $part eq '' ){
            print '>> Parting channel ' . $channel . ' (command called by ' . $who . " )\n";
            $self->{bot}->part( channel => $channel );
        } elsif ( getAccessLevel($who) > 0 ) {
            print '>> Parting channel ' . $channel . ' (command called by ' . $who . ', accesslevel: [' . $admins->{$who} . "])\n";
            print '>> Parting channel ' . $part . "\n";
            $self->{bot}->part( channel => $part );
        } else {
            print '>> Part command called by ' . $who . ', but he/she\'s no admin!' . "\n";
        }
    }
    
    sub handleQuit {
        my ($self, $channel, $who, $message) = @_;
        if( getAccessLevel($who) == 5 ) {
            print '>> Quitting (command called by ' . $who . ', accesslevel: [' . $admins->{$who} . '])...' . "\n";
            $self->{bot}->shutdown( $message || $self->{bot}->quit_message() );
        } elsif( getAccessLevel($who) > 0 ) {
            print '>> Quit command called by ' . $who . ', but unsufficient permission: [' . $admins->{$who} . ']...' . "\n";
        } else {
            print '>> Quit command called by ' . $who . ', but he/she\'s no admin!' . "\n";
        }
    }
    
    sub handleListAdmins {
        my ($self, $channel, $who, $message) = @_;
        my @a;
        while( my ($admin, $level) = each ($admins) ) {
            push( @a, $admin . ' [' . $level . ']' ); 
        }
        $self->{bot}->say( channel => $channel, who => $who, body => 'Admins: ' . join(', ', @a) );
    }
    
    sub handleKick {
        my ($self, $channel, $who, $args) = @_;
        if( getAccessLevel($who) > 0 ) {
            if( $args =~ m/(\w+)\s*(.*?)/si ) {
                my $kicked = $1;
                my $message = $2 || 'Bye!';
                print '>> Kick command called by ' . $who . '; kicking ' . $kicked . ' [' . $message . ']' . "\n";
                $self->{bot}->kick(channel => $channel, who => $kicked, body => $message );
            }
        } else {
            print '>> Kick command called by ' . $who . ', but he/she\'s no admin!' . "\n";
        }
    }
    
    sub handleHelp {
        my ($self, $channel, $who, $args) = @_;
        my $message = '';
        $message .= "Available commands:\n";
        $message .= "|==============================================================|\n";
        $message .= "| Command                 | Function                           |\n";
        $message .= "|-------------------------|------------------------------------|\n";
        $message .= "| !help                   | Show this help                     |\n";
        $message .= "| !join <channel>         | Join channel <channel>             |\n";
        $message .= "| !part                   | Part channel                       |\n";
        $message .= "| !g <query>              | Search <query> on Google           |\n";
        $message .= "| !gi <query>             | Search <query> on Google Images    |\n";
        $message .= "| !y <query>              | Search <query> on Youtube          |\n";
        $message .= "| !calc <query>           | Parse <query> with WolframAlpha    |\n";
        $message .= "| !listadmins             | List admins and their accesslevels |\n";
        if( getAccessLevel($who) > 0 ) {
            $message .= "|-------------------------|------------------------------------|\n";
            $message .= "| Admin commands          | Function                           |\n";
            $message .= "|-------------------------|------------------------------------|\n";
            $message .= "| !kick <user>  <message> | Kicks <user> out of channel        |\n";
            if ( getAccessLevel($who) > 1 ) {
                $message .= "| !part [channel]         | Part from [channel]                |\n";
            }
            if ( getAccessLevel($who) > 4 ) {
                $message .= "| !quit [message]         | Close connection and quit          |\n";
                
            }
        }
        $message .= "|==============================================================|\n";
        
        $self->{bot}->say(channel => 'msg', who => $who, body => $message);
    }
    
    sub getAccessLevel{
        my $who = shift;
        if( defined( $admins->{$who} ) ) {
            return $admins->{$who};
        } else {
            return 0;
        }
    }
    
    1;
}
