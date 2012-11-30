package Saphira::Module

{
    sub new {
        my ($class, $bot) = shift;
        my $self = bless {}, $class;
        
        $self->{processor} = shift;
        $self->{bot} = $bot;
        
        $self->init();

        return $self;
    }
    
    sub init{
        my $self = shift;
        return undef;
    }
    
    sub registerCommandHook {
        my ($self, $command, $func) = @_;
        
        $self->{processor}->registerCommandHook( getModuleName(), $command, $func );
    }
    
    sub registerMessageHook {
        my ($self, $func) = @_;
        
        $self->{processor}->registerMessageHook( getModuleName(), $func );
    }
    
    sub registerEmotedHook {
        my ($self, $func) = @_;
        
        $self->{processor}->registerEmotedHook( getModuleName(), $func );
    }
    
    sub getModuleName {
        my $self = shift;
        
        my $module = ref($self);
        $module =~ s/Saphira::Module::(.*)/$1/;
        return lc($module);
    }
    
    1;
}