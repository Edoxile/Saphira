package Saphira::Module::Google;

{
    use base 'Saphira::Module';
    use warnings;
    use strict;

    use Google::Search;
    use HTML::Entities;
    use Encode;
    
    sub init {
        my $self = shift;

        # Register hooks
        $self->registerCommandHook('g', \&handleWebSearch);
        $self->registerCommandHook('google', \&handleWebSearch);
        $self->registerCommandHook('gi', \&handleImageSearch);
        $self->registerCommandHook('gimages', \&handleImageSearch);
        $self->registerCommandHook('googleimages', \&handleImageSearch);
        $self->registerCommandHook('y', \&handleYoutubeSearch);
        $self->registerCommandHook('youtube', \&handleYoutubeSearch);
        
        #$self->registerCommandHook(m/^g(oogle)+$/si \&handleWebSearch);
        #$self->registerCommandHook(m/^g(oogle)+i(mages)+$/si, \&handleImageSearch);
        #$self->registerCommandHook(m/^y(outube)+$/si, \&handleYoutubeSearch);
    }

    sub handleWebSearch {
        my ($self, $channel, $who, $searchTerm) = @_;
        
        print '>> Google search term: [ ' . $searchTerm . " ]\n";
        
        my $search = Google::Search->Web( hl => 'nl', query => $searchTerm );
        my $result = $search->first;

        if (!defined($result)) {
            $self->{bot}->say( channel => $channel, who => $who, body => 'I\'m Sorry ' . $who . ', I can\'t find anything for \'' . $searchTerm . '\' on Google.' );
        } else {
            my $message = $who . ': ' . decodeTitle( HTML::Entities::decode( $result->titleNoFormatting ) ) . ' - ' . $result->uri;
            $self->{bot}->say( channel => $channel, who => $who, body => $message );
        }
    }

    sub handleYoutubeSearch {
        my ($self, $channel, $who, $searchTerm) = @_;
        
        print '>> Youtube search term: [ ' . $searchTerm . " ]\n";
        
        my $search = Google::Search->Web( hl => 'nl', query => 'site:youtube.com ' . $searchTerm );
        my $result = $search->first;

        if (!defined($result)) {
            $self->{bot}->say( channel => $channel, who => $who, body => 'I\'m Sorry ' . $who . ', I can\'t find anything for \'' . $searchTerm . '\' on Youtube.' );
        } else {
            my $message = $who . ': ' . decodeTitle( HTML::Entities::decode( $result->titleNoFormatting ) ) . ' - ' . $result->uri;
            $self->{bot}->say( channel => $channel, who => $who, body => $message );
        }
    }

    sub handleImageSearch {
        my ($self, $channel, $who, $searchTerm) = @_;
        
        print '>> Google image search term: [ ' . $searchTerm . " ]\n";
        
        my $search = Google::Search->Image( hl => 'nl', query => $searchTerm );
        my $result = $search->first;

        if (!defined($result)) {
            $self->{bot}->say( channel => $channel, who => $who, body => 'I\'m Sorry ' . $who . ', I can\'t find anything for \'' . $searchTerm . '\' on Google Images.' );
        } else {
            my $message = $who . ': ' . $result->uri;
            $self->{bot}->say( channel => $channel, who => $who, body => $message );
        }
    }
    
    sub decodeTitle {
        my $title = shift;
        $title = decode('utf-8', $title, 1) || $title;
        $title =~ s/\s+$//;
        $title =~ s/^\s+//;
        $title =~ s/\n+//g;
        $title =~ s/\s+/ /g;
        $title = decode_entities($title);
        $title =~ s/(&\#(\d+);?)/chr($2)/eg;
        return $title;
    }

    1;
}