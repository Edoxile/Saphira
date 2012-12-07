package Saphira::Module::SynchTube
{
    use base 'Saphira::Module';
    use warnings;
    use strict;
    use LWP::Simple;
    
    sub init {
        my $self = shift;
        
        # register command hooks
        $self->registerCommandHook('st', \&handleSynchTube);
        $self->registerCommandHook('synchtube', \&handleSynchTube);
    }
    
    sub handleSynchTube {
        my ($self, $channel, $who, $room) = @_;
        
        $room =~ s/^(\w+)\s*(.*?)$/$1/;
        
        print '>> Getting SynchTube info for room [ ' . $room . " ]\n";
        
        my $data = get( 'http://synchtube.com/api/1/room/' . $room );
        my $media = $data;
        my $listeners = $data;
        $media =~ s/^(.*?)"current_media":{"title":"(.+?)"(,|})(.*?)$/$2/;
        $listeners =~ s/^(.*?)"current_users":\s*(\d+)(,|})(.*?)$/$2/si;
        
        $self->{bot}->say( channel => $channel, who => $who, body => 'Synchtube room [ ' . $room . ' ] is now playing: ' . $media . ' ('.$listeners.' listener(s)). http://synchtu.be/' . $room );
    }
    
    1;
}
