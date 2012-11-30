package Saphira::Module::WolframAlpha
{
    use base 'Saphira::Module';
    use warnings;
    use strict;
    use WWW::WolframAlpha;
    
    # APPID: '6H8RLK-25U2TGYJ2U'
    my $appid = '';
    my $wolframAlpha = undef;
    
    sub init {
        my $self = shift;
        
        my $conf = Config::File::read_config_file("bot.conf");
        $appid = $conf->{WAID};
        
        $wolframAlpha = WWW::WolframAlpha->new( appid => $appid );
        
        $self->registerCommandHook('calc', \&handleCalc);
    }
    
    sub handleCalc{
        my ($self, $channel, $who, $input) = @_;
        print '>> WolframAlpha query: [ ' . $input . " ]\n";
        
        my $query = $wolframAlpha->query( input => $input, format => 'plaintext' );
        
        if( $query->success && $query->numpods > 0 ) {
            my @pods = @{$query->pods};
            my $answerPod = $pods[1];
            my @answerSubPods = @{$answerPod->subpods};
            my $response = $answerSubPods[0]->plaintext;
            
            $self->{bot}->say( who => $who, channel => $channel, body => $who . ': ' . $response);
        } else {
            $self->{bot}->say( who => $who, channel => $channel, body => 'I\'m sorry ' . $who . ', I can\'t find anything for \''. $input . '\' on WolframAlpha.');
        }
    }
    
    1;
}