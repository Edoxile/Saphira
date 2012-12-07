package Saphira::EventProcessor{
    
    use Saphira::Module::Google;
    use Saphira::Module::Admin;
    use Saphira::Module::SimpleMessageHooks;
    use Saphira::Module::WolframAlpha;
    use Saphira::Module::SynchTube;
    # use Saphira::Module::Wikipedia;
    
    sub new {
        my $class = shift;
        my $self = { bot => shift };
        bless $self, $class;
        
        $self->{modules}={};
        
        $self->init();
        
        return $self;
    }
    
    sub init{
        my $self = shift;
        
        new Saphira::Module::Admin($self, $self->{bot});
        new Saphira::Module::Google($self, $self->{bot});
        new Saphira::Module::SimpleMessageHooks($self, $self->{bot});
        new Saphira::Module::WolframAlpha($self, $self->{bot});
        new Saphira::Module::SynchTube($self, $self->{bot});
        # new Saphira::Module::Wikipedia($self, $self->{bot});
    }
    
    sub registerModules {
        my $self = shift;
        my @moduleList = glob('modules/*.pm');
    }
    
    sub processCommand {
        my ($self, $channel, $who, $command, $args) = @_;
        while (my ($module, $moduleHash) = each(%{$self->{modules}})) {
            foreach (@{$moduleHash->{commandHooks}->{$command}}) {
                eval { $self->$_($channel, $who, $args); };
                if ($@) {
                    return "\x02Module '$module' encountered an error:\x0F $@";
                }
            }
        }
        return undef;
    }
    
    sub processMessage{
        my ($self, $channel, $who, $body) = @_;
        while (my ($module, $moduleHash) = each(%{$self->{modules}})) {
            foreach (@{$moduleHash->{messageHooks}}) {
                eval { $self->$_($channel, $who, $body); };
                if ($@) {
                    return "\x02Module '$module' encountered an error:\x0F $@";
                }
            }
        }
        return undef;
    }
    
    sub processEmoted{
        my ($self, $channel, $who, $body) = @_;
        while (my ($module, $moduleHash) = each(%{$self->{modules}})) {
            foreach (@{$moduleHash->{emotedHooks}}) {
                eval { $self->$_($channel, $who, $body); };
                if ($@) {
                    return "\x02Module '$module' encountered an error:\x0F $@";
                }
            }
        }
        return undef;
    }
    
    sub registerCommandHook {
        my ($self, $module, $command, $function) = @_;
        push(@{$self->{modules}->{$module}->{commandHooks}->{$command}}, $function);
    }
    
    sub registerMessageHook {
        my ($self, $module, $function) = @_;
        push(@{$self->{modules}->{$module}->{messageHooks}}, $function);
    }
    
    sub registerEmotedHook {
        my ($self, $module, $function) = @_;
        push(@{$self->{modules}->{$module}->{emotedHooks}}, $function);
    }
    
    1;
}