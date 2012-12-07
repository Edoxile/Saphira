package Saphira::Module::Wikipedia
{
    use base 'Saphira::Module';
    use warnings;
    use strict;
    use WWW::Wikipedia;
    
    sub init {
        my $self = shift;
        
        # register command hooks
        $self->registerCommandHook('wiki', \&handleWikiSearch);
        $self->registerCommandHook('enwiki', \&handleWikiSearchEn);
        
        $self->{wiki} = WWW::Wikipedia->new( language => 'nl' );
        $self->{enwiki} = WWW::Wikipedia->new( language => 'en' );
    }
    
    sub handleWikiSearch {
        my ($self, $channel, $who, $searchTerm) = @_;
        print '>> Getting Wiki info for [ ' . $searchTerm . " ]\n";
        my $wiki = WWW::Wikipedia->new( language => 'nl' );
        my $entry = $wiki->search( $searchTerm );
        my $message = '';
        
        if( $entry->text() eq '' ) {
            $message = 'I\'m sorry ' . $who . ', I couldn\'t find anything for \'' . $searchTerm . '\'. You migth want to make your search more specific.';
        } else {
            $message = $who . ': ' . $entry->text();
        }
        
        $self->{bot}->say( channel => $channel, who => $who, body => $message );
    }
    
    sub handleWikiSearchEn {
        my ($self, $channel, $who, $searchTerm) = @_;
        print '>> Getting Wiki info for [ ' . $searchTerm . " ]\n";
        my $entry = $self->{enwiki}->search( $searchTerm );
        my $message = '';
        
        if( $entry->text() eq '' ) {
            $message = 'I\'m sorry ' . $who . ', I couldn\'t find anything for \'' . $searchTerm . '\'. You migth want to make your search more specific.';
        } else {
            $message = $who . ': ' . $entry->text();
        }
        
        $self->{bot}->say( channel => $channel, who => $who, body => $message );
    }
    
    1;
}