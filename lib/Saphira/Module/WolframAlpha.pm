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
        my $response = '';
        
        if( $query->success && $query->numpods > 0 ) {
            my @pods = @{$query->pods};
            my $answerPod = $pods[1];
            my @answerSubPods = @{$answerPod->subpods};
            if(!defined( $answerSubPods[0] ) || $answerSubPods[0] eq ''){
                $response = 'I\'m sorry ' . $who . ', I can\'t find anything for \''. $input . '\' on WolframAlpha.';
            } else {
                $response = $who . ': ' . $answerSubPods[0]->plaintext;
            }
        } else {
            $response = 'I\'m sorry ' . $who . ', I can\'t find anything for \''. $input . '\' on WolframAlpha.';
        }
        $self->{bot}->say( who => $who, channel => $channel, body => $response);
    }
    
    1;
}