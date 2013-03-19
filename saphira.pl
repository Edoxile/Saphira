#!/usr/bin/env perl
use warnings;
use strict;
use Config::IniFiles;

END {
    unless ( -e 'saphira.ini' ) {
        print "[E] No configuration file found. Creating one with placeholder variables. Please\n"
          . "\tmodify saphira.ini and restart the bot.\n";

        my $cfg = Config::IniFiles->new();

        $cfg->newval( 'mysql', 'host',     'localhost' );
        $cfg->newval( 'mysql', 'username', 'root' );
        $cfg->newval( 'mysql', 'password', '' );
        $cfg->newval( 'mysql', 'database', 'saphira' );

        $cfg->newval( 'irc', 'autoload', 'manage' );

        $cfg->WriteConfig('saphira.ini');

        exit;
    }

    my $cfg = Config::IniFiles->new( -file => 'saphira.ini' );

    my $wrapper = new Saphira::Wrapper(
        $cfg->val( 'mysql', 'host' ),
        $cfg->val( 'mysql', 'username' ),
        $cfg->val( 'mysql', 'password' ),
        $cfg->val( 'mysql', 'database' ),
        [ split( ',', $cfg->val( 'irc', 'autoload' ) ) ]
    );

}

package Saphira::Bot;
use base 'Bot::BasicBot';
use POE;

my $version = '2.0.0';
my $botinfo =
    'Saphira (v'
  . $version
  . ') by Edoxile. See https://github.com/Edoxile/Saphira for more info, reporting issues, command usage and source code.';

sub new {
    my $class = shift;
    my $self  = bless {
        serv    => shift,
        wrapper => shift,
        thread  => 0
    }, $class;

    $self->{IRCNAME}   = 'SaphiraBot' . int( rand(100000) );
    $self->{ALIASNAME} = 'Saphira' . int( rand(100000) );

    $self->server( $self->{serv}->{address} );
    $self->port( int( $self->{serv}->{port} ) );
    $self->ssl( $self->{serv}->{secure} );
    $self->nick( $self->{serv}->{username} );

    $self->alt_nicks( ["PerlBot"] );
    $self->username('Saphira');
    $self->name('Saphira, a Perl IRC-bot by Edoxile');
    $self->charset('utf8');

    $self->init or die "init did not return a true value - dying";

    return $self;
}

sub said {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'said', $_[1] );
    return;
}

sub emoted {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'emoted', $_[1] );
    return;
}

sub noticed {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'noticed', $_[1] );
    return;
}

sub chanjoin {
    if ( $_[1]->{who} eq $_[0]->nick() ) {
        $_[0]->{serv}->addChannel( $_[1] );
    }
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'chanjoin', $_[1] );
    return;
}

sub chanpart {
    if ( $_[1]->{who} eq $_[0]->nick() ) {
        $_[0]->{serv}->removeChannel( $_[1] );
    }
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'chanpart', $_[1] );
    return;
}

sub topic {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'topic', $_[1] );
    return;
}

sub kicked {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'kicked', $_[1] );
    return;
}

sub userquit {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'userquit', $_[1] );
    return;
}

sub invited {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'invited', $_[1] );
    return;
}

sub nick_change {
    $_[0]->{wrapper}->processHooks( $_[0]->{serv}, 'nick_change', ( $_[1], $_[2] ) );
    return;
}

sub help { return $botinfo; }

sub init {

    return 1;
}

sub connected {
    my $self = shift;
    print '[I] Connected! Identifying if password is present...' . "\n";
    my $nspass = '' . $self->{serv}->{nickservpassword};
    return unless $nspass ne '';
    $self->say(
        who     => 'NickServ',
        channel => 'msg',
        body    => 'IDENTIFY ' . $nspass
    );
}

sub addressed {
    my ( $self, $message ) = @_;
    return (
        (
                 ( defined( $message->{address} ) && ( $message->{address} eq $self->{nick} ) )
              || ( $message->{channel} eq 'msg' )
        ) ? 1 : 0
    );
}

sub addressedMsg {
    my ( $self, $message ) = @_;
    return ( ( $message->{channel} eq 'msg' ) ? 1 : 0 );
}

sub report {
    my ( $self, $text, $message ) = @_;

    if ( defined($message) ) {
        $self->say(
            who     => $message->{who},
            channel => $message->{channel},
            body    => $text,
            address => $message->{address}
        );
    } else {
        print "$text\n";
    }
}

sub reply {
    my ( $self, $text, $message ) = @_;
    $self->say(
        who     => $message->{who},
        channel => $message->{channel},
        body    => $text,
        address => $message->{address}
    );

}

sub join_channel {
    my ( $self, $channel, $key ) = @_;
    $key = '' unless defined($key);
    $poe_kernel->post( $self->{IRCNAME}, 'join', $channel, $key );
}

sub part_channel {
    my ( $self, $channel, $part_msg ) = @_;
    $part_msg ||= ( 'Saphira v' . $version );
    $poe_kernel->post( $self->{IRCNAME}, 'part', $channel, $part_msg );
}

sub _loadChannels {
    my $self     = shift;
    my @channels = ();
    foreach my $channel ( values %{ $self->{serv}->{channels} } ) {
        push( @channels, $channel->getName() ) if $channel->getState();
    }
    $self->channels(@channels);
}

1;

package Saphira::Module;
use warnings;
use strict;

sub new {
    my ( $class, $wrapper, $message, $args ) = @_;

    my $self = bless { wrapper => $wrapper }, $class;

    $self->init( $message, $args );

    return $self;
}

sub registerHook {
    my ( $self, $type, $code ) = @_;

    my $module = ref($self);
    $module =~ s/Saphira::Module::(.*)/$1/;
    $module = lc($module);

    $self->{wrapper}->registerHook( $module, $type, $code );
}

sub init { undef }

1;

package Saphira::API::DBExt;

use DBI;

sub new {
    my $class = shift;
    my $self = bless { wrapper => shift, last_insert_id => -1 }, $class;
    return $self;
}

sub handleQuery {
    my ( $self, $queryType ) = @_;
    my $package = ref $self;
    return unless defined $self->{__queries}->{$queryType}->{query};
    return unless defined $self->{__queries}->{$queryType}->{fields};
    my $dbd = $self->{wrapper}->cloneDBD();
    my $ps  = $dbd->prepare( $self->{__queries}->{$queryType}->{query} );
    my $n   = 1;
    foreach my $field ( @{ $self->{__queries}->{$queryType}->{fields} } ) {
        $ps->bind_param( $n, $self->{$field} );
        $n++;
    }
    $ps->execute();
    $self->{last_insert_id} = $dbd->{q{mysql_insertid}};

    return $ps;
}

1;

package Saphira::API::Channel;

use base 'Saphira::API::DBExt';

sub new {
    my $class = shift;
    my $self  = bless {
        server    => shift,
        id        => shift,
        name      => shift,
        password  => shift,
        state     => shift,
        logging   => shift,
        __queries => {
            insert => {
                query => 'insert into channels (
                server, name, log, password
            ) values (
                ?, ?, ?, ?
            )',
                fields => [ 'server', 'name', 'logging', 'password' ]
            },
            update => {
                query => 'update channels set
                      server = ?,
                      log = ?,
                      password = ?,
                      state = ?
                  where id = ?',
                fields => [ 'server', 'logging', 'password', 'state', 'id' ]
            }
        }
    }, $class;

    return $self;
}

sub getBot {
    my $self = shift;
    return $self->{server}->{bot};
}

sub getServer {
    my $self = shift;
    return $self->{server};
}

sub getId {
    my $self = shift;
    return $self->{id};
}

sub getName {
    my $self = shift;
    return $self->{name};
}

sub getState {
    my $self = shift;
    return $self->{state};
}

sub setPassword {
    my $self     = shift;
    my $password = shift;
    my $noUpdate = shift if @_;
    $self->{password} = $password;
    if ( not defined($noUpdate) || $noUpdate ) {
        my $ps = $self->handleQuery('update');
        if ( $ps->err ) {
            print '[E] MySQL error: ' . $ps->errstr . "\n";
            return 0;
        } else {
            return 1;
        }
    }
    return 1;
}

sub setState {
    my ( $self, $state ) = @_;
    $state = ( $state > 0 ) ? 1 : 0;
    return unless $self->{state} ne $state;
    if ( $self->{state} eq 0 ) {
        return $self->enable();
    } elsif ( $self->{state} eq -1 ) {
        return $self->insert();
    } else {
        return $self->disable();
    }
}

sub _insert {
    my $self = shift;
    my $ps   = $self->handleQuery('insert');
    if ( $ps->err ) {
        return 0;
    } else {
        $self->{id}    = $self->{last_insert_id};
        $self->{state} = 1;
        return 1;
    }
}

sub _disable {
    my $self = shift;
    $self->{state} = 0;
    my $ps = $self->handleQuery('update');
    if ( $ps->err ) {
        print '[E] MySQL error: ' . $ps->errstr . "\n";
        return 0;
    } else {
        return 1;
    }
}

sub _enable {
    my $self = shift;
    $self->{state} = 1;
    my $ps = $self->handleQuery('update');
    if ( $ps->err ) {
        print '[E] MySQL error: ' . $ps->errstr . "\n";
        return 0;
    } else {
        return 1;
    }
}

1;

package Saphira::API::Server;

use base 'Saphira::API::DBExt';

sub new {
    my $class = shift;
    my $self  = bless {
        id               => shift,
        servername       => shift,
        address          => shift,
        port             => shift,
        secure           => shift,
        username         => shift,
        password         => shift,
        nickservpassword => shift,
        wrapper          => shift,
        active           => shift,
        bot              => 0,
        channels         => {},
        users            => {},
        __queries        => {
            update => {
                query =>
'update servers set address = ?, port = ?, secure = ?, password = ?, nickservpassword = ?, active = ? where id = ?',
                fields => [ 'address', 'port', 'secure', 'password', 'nickservpassword', 'active', 'id' ]
            },
            select_channels => {
                query  => 'select * from channels where server = ?',
                fields => ['id']
            },
            update_active => {
                query  => 'update servers set active = ? where id = ?',
                fields => [ 'active', 'id' ]
            }
        }
    }, $class;

    $self->init();

    return $self;
}

sub init {
    my $self = shift;
    $self->{active} = 1;
    my $ps = $self->handleQuery('select_channels');
    while ( my $result = $ps->fetchrow_hashref() ) {
        $self->{channels}->{ $result->{id} } =
          new Saphira::API::Channel( $self, $result->{id}, $result->{name},
            $result->{password}, $result->{state}, $result->{log} );
    }
}

sub getServerName {
    my $self = shift;
    return $self->{servername};
}

sub getServerAddress {
    my $self = shift;
    return $self->{address};
}

sub getServerPort {
    my $self = shift;
    return $self->{port};
}

sub useSecureConnection {
    my $self = shift;
    return $self->{secure};
}

sub getChannel {
    my ( $self, $channelName ) = @_;
    my $key = $self->_getChannelId($channelName);
    return unless defined $key;
    return $self->{channels}->{$key};
}

sub getWrapper {
    my $self = shift;
    return $self->{wrapper};
}

sub setPassword {
    my ( $self, $password ) = @_;
    $self->{password} = $password;
    $self->_update();
}

sub getUser {
    my ( $self, $raw_nick ) = @_;
    return $self->{users}->{$raw_nick};
}

sub getUsers {
    my $self = shift;
    return @{ values $self->{users} };
}

sub getUserByName {
    my ( $self, $nick ) = @_;

    foreach my $user ( keys %{ $self->{users} } ) {
        return $user if $user->{username} eq $nick;
    }

    return undef;
}

sub getUserByNick {
    my ( $self, $nick ) = @_;

    foreach my $user ( keys %{ $self->{users} } ) {
        return $user if $user->{nickname} eq $nick;
    }

    return undef;
}

sub addUser {
    my ( $self, $user ) = @_;
    return unless not defined $self->{users}->{ $user->getRawUsername() };
    $self->{users}->{ $user->getRawUsername() } = $user;
    return 1;
}

sub removeUser {
    my ( $self, $raw_username ) = @_;
    return unless defined $self->{users}->{$raw_username};
    delete $self->{users}->{$raw_username};
    return 1;
}

sub joinChannel {
    my ( $self, $channel, $key ) = @_;
    $self->{bot}->join_channel( $channel, $key );
}

sub partChannel {
    my ( $self, $channel, $message ) = @_;
    return unless defined $self->{bot}->{serv}->{channels}->{$channel};
    $self->{bot}->part_channel( $channel, $message );
}

sub addChannel {
    my ( $self, $data ) = @_;

    my $key = $self->getChannelId( $data->{channel} );

    if ( defined $key ) {
        $self->{channels}->{$key}->enable();
    } else {
        my $id = 0;
        do {
            $id--;
        } while defined $self->{channels}->{$id};
        $self->{channels}->{$key} = new Saphira::API::Channel( $self->{id}, $id, $data->{channel}, '', -1, 0 );
    }
}

sub removeChannel {
    my ( $self, $data ) = @_;

    my $key = $self->getChannelId( $data->{channel} );

    return unless defined $key;
    if ( $key gt 0 ) {
        $self->{channels}->{$key}->disable();
    } else {
        delete $self->{channels}->{$key};
    }
}

sub isActive {
    my $self = shift;
    return $self->{active};
}

sub setActive {
    my ( $self, $active ) = @_;
    $self->{active} = ( $active > 0 );

}

sub _getServerId {
    my $self = shift;
    return $self->{id};
}

sub _getChannelId {
    my ( $self, $channelName ) = @_;
    foreach my $key ( keys %{ $self->{channels} } ) {
        if ( $self->{channels}->{$key}->{name} eq $channelName ) {
            return $key;
        }
    }
    return undef;
}

sub _setBot {
    my ( $self, $bot ) = @_;
    return unless $self->{bot} eq 0;
    $self->{bot} = $bot;
}

1;

package Saphira::Wrapper;

use DBI;
use threads(
    'yield',
    'stack_size' => 64 * 4096,
    'exit'       => 'threads_only',
    'stringify'
);

sub new {
    my $class = shift;
    my $self  = bless {
        mysql_host       => shift,
        mysql_username   => shift,
        mysql_password   => shift,
        mysql_database   => shift,
        autoload_modules => shift,
        servers          => {},
        bots             => {}
    }, $class;

    $self->{dbd} = DBI->connect(
        sprintf( 'DBI:mysql:%s;host=%s', $self->{mysql_database}, $self->{mysql_host} ),
        $self->{mysql_username},
        $self->{mysql_password},
        { 'mysql_enable_utf8' => 1 }
    );

    if ( not $self->{dbd} ) {
        print '[E] MySQL connect error: ' . $DBI::errstr . "\n";
        return undef;
    }

    $self->{dbd}->do('SET NAMES utf8');

    if ( $self->init() ) {
        return $self;
    } else {
        return undef;
    }
}

sub cloneDBD {
    my $self = shift;

    my $dbd = DBI->connect(
        sprintf( 'DBI:mysql:%s;host=%s', $self->{mysql_database}, $self->{mysql_host} ),
        $self->{mysql_username},
        $self->{mysql_password},
        { 'mysql_enable_utf8' => 1 }
    );

    if ( not $dbd ) {
        print '[E] MySQL connect error: ' . $DBI::errstr . "\n";
        return undef;
    }

    return $dbd;
}

sub init {
    my $self = shift;
    my $ps   = $self->{dbd}->prepare(
        'select
            *
        from
            servers
        where
            active = TRUE'
    );
    $ps->execute();
    if ( $ps->err ) {
        print '[E] MySQL select error: ' . $ps->errstr . "\n";
        return 0;
    }

    print "[I] Loading Modules...\n";
    foreach my $mod ( @{ $self->{autoload_modules} } ) {
        print ">> Loading module $mod\n";
        my $status = $self->loadModule($mod);
        print "\t$status->{string} [Status: $status->{status}, Code: $status->{code}]\n";
        die( 'Couldn\'t load module ' . $mod . '...' ) if $status->{status} eq 0;
    }

    while ( my $result = $ps->fetchrow_hashref() ) {
        $self->{servers}->{ $result->{id} } = new Saphira::API::Server(
            $result->{id},     $result->{servername}, $result->{address},  $result->{port},
            $result->{secure}, $result->{username},   $result->{password}, $result->{nickservpassword},
            $self,             1
        );
        $self->{bots}->{ $result->{id} } =
          new Saphira::Bot( $self->{servers}->{ $result->{id} }, $self );
        $self->{servers}->{ $result->{id} }->_setBot( $self->{bots}->{ $result->{id} } );
        $self->{bots}->{ $result->{id} }->_loadChannels();
        print
"[I] Connecting to server $result->{servername} [host:$result->{address}, port:$result->{port}, ssl:$result->{secure}] {"
          . join( ', ', $self->{bots}->{ $result->{id} }->channels() ) . "}\n";
        threads->create( 'runThread', $self->{bots}->{ $result->{id} } )->join();
    }

    return 1;
}

sub runThread {
    $_[0]->run();
}

sub getServer {
    my ( $self, $id ) = @_;
    return $self->{servers}->{$id};
}

sub removeServer {
    my ( $self, $id ) = @_;
    return unless not $self->{servers}->{$id}->isActive();
    delete $self->{servers}->{$id};
}

sub getAvailableModules {
    my $self = shift;

    my @availableModules = glob('modules/*.pm');
    foreach (@availableModules) {
        $_ =~ s/modules\/(.*)\.pm/$1/;
    }

    return @availableModules;
}

sub getLoadedModules {
    my $self = shift;
    return @{ $self->{moduleList} };
}

sub getActiveModules {
    my $self = shift;

    my @activeModules;
    foreach my $module ( @{ $self->{moduleList} } ) {
        next if ( $self->{modules}->{$module}->{enabled} == 0 );

        push( @activeModules, $module );
    }

    return @activeModules;
}

sub loadModule {
    my $self    = shift;
    my $module  = shift;
    my $message = shift;
    my $args    = ( defined( $_[0] ) ? join( ' ', @_ ) : '' );

    my $moduleKey = lc($module);
    $moduleKey =~ s/^\s+//;
    $moduleKey =~ s/\s+$//;

    if ( $self->{modules}->{$moduleKey} ) {
        return {
            status => 0,
            code   => 0,
            string => "Module '$module' already loaded (try reloading)"
        };
    }

    unless ( -e './modules/' . $moduleKey . '.pm' ) {
        return {
            status => 0,
            code   => 1,
            string => "Module '$module' not found"
        };
    }

    my $modulePackage = ( "Saphira::Module::" . ucfirst($module) );

    delete $INC{ './modules/' . $moduleKey . '.pm' };

    eval {
        require( './modules/' . $moduleKey . '.pm' );

        $self->{modules}->{$moduleKey}->{object} =
          $modulePackage->new( $self, $message, $args );
        $self->{modules}->{$moduleKey}->{enabled} = 1;

        push( @{ $self->{moduleList} }, $moduleKey );
    };

    if ($@) {
        return { status => 0, code => 2, string => $@ };
    }

    return { status => 1, code => -1, string => "Module '$module' loaded" };
}

sub reloadModule {
    my $self    = shift;
    my $module  = shift;
    my $message = shift;
    my $args    = ( defined( $_[0] ) ? join( ' ', @_ ) : '' );

    $self->unloadModule($module);
    return $self->loadModule( $module, $message, $args );
}

sub unloadModule {
    my ( $self, $module ) = @_;
    my $moduleKey = lc($module);

    unless ( $self->{modules}->{$moduleKey} ) {
        return {
            status => 0,
            code   => 0,
            string => "Module '$module' not loaded"
        };
    }

    delete( $self->{modules}->{$moduleKey} );
    @{ $self->{moduleList} } =
      grep { $_ ne $moduleKey } @{ $self->{moduleList} };

    return { status => 1, code => -1, string => "Module '$module' unloaded" };
}

sub enableModule {
    my ( $self, $module ) = @_;
    my $moduleKey = lc($module);

    unless ( $self->{modules}->{$moduleKey} ) {
        return {
            status => 0,
            code   => 0,
            string => "Module '$module' not loaded"
        };
    }

    if ( $self->{modules}->{$moduleKey}->{enabled} == 1 ) {
        return {
            status => 0,
            code   => 1,
            string => "Module '$module' already enabled"
        };
    }

    $self->{modules}->{$moduleKey}->{enabled} = 1;

    return { status => 1, code => -1, string => "Module '$module' enabled" };
}

sub disableModule {
    my ( $self, $module ) = @_;
    my $moduleKey = lc($module);

    unless ( $self->{modules}->{$moduleKey} ) {
        return {
            status => 0,
            code   => 0,
            string => "Module '$module' not loaded"
        };
    }

    if ( $self->{modules}->{$moduleKey}->{enabled} == 0 ) {
        return {
            status => 0,
            code   => 1,
            string => "Module '$module' already disabled"
        };
    }

    $self->{modules}->{$moduleKey}->{enabled} = 0;

    return { status => 1, code => -1, string => "Module '$module' disabled" };
}

sub registerHook {
    my ( $self, $module, $type, $function ) = @_;

    push( @{ $self->{modules}->{$module}->{hooks}->{$type} }, $function );

    return {
        status => 1,
        code   => -1,
        string => "Hook with type '$type' for module '$module' registered"
    };
}

sub unregisterHook {
    my ( $self, $module, $type, $function ) = @_;

    unless ( grep( $function, @{ $self->{modules}->{$module}->{hooks}->{$type} } ) ) {
        return {
            status => 0,
            code   => 0,
            string => "Hook with type '$type' for module '$module' does not exist"
        };
    }

    @{ $self->{modules}->{$module}->{hooks}->{$type} } =
      grep { $_ != $function } @{ $self->{modules}->{$module}->{hooks}->{$type} };

    return {
        status => 1,
        code   => -1,
        string => "Hook with type '$type' for module '$module' unregistered"
    };
}

sub unregisterHooks {
    my ( $self, $module, $type ) = @_;

    $self->{modules}->{$module}->{hooks}->{$type} = ();

    return {
        status => 1,
        code   => -1,
        string => "All hooks with type '$type' for module '$module' unregistered"
    };
}

sub getHooks {
    my ( $self, $module, $type ) = @_;

    return @{ $self->{modules}->{$module}->{hooks}->{$type} };
}

sub hookRegistered {
    my ( $self, $module, $type ) = @_;

    return @{ $self->{modules}->{$module}->{hooks}->{$type} };
}

sub processHooks {
    my ( $self, $server, $type, $data ) = @_;
    while ( my ( $module, $moduleHash ) = each( %{ $self->{modules} } ) ) {
        next if ( $moduleHash->{enabled} == 0 );
        foreach ( @{ $moduleHash->{hooks}->{$type} } ) {
            eval { $self->$_( $server, $data ); };
            if ($@) {
                $server->{bot}->notice(
                    who     => $data->{who},
                    channel => $data->{channel},
                    body    => "\x02Module '$module' encountered an error and will be unloaded:\x0F $@",
                    address => $data->{address}
                );
                $self->unloadModule($module);
            }
        }
    }
}

sub moduleLoaded {
    my ( $self, $module ) = @_;
    return ( exists( $self->{modules}->{ lc($module) } ) ? 1 : 0 );
}

sub moduleActive {
    my ( $self, $module ) = @_;
    return ( ( $self->moduleLoaded($module) && ( $self->{modules}->{ lc($module) }->{enabled} == 1 ) ) ? 1 : 0 );
}

sub module {
    my ( $self, $module ) = @_;
    unless ( $self->moduleLoaded($module) ) {
        return undef;
    }
    return $self->{modules}->{ lc($module) }->{object};
}

sub moduleFunc {
    my ( $self, $module, $func, @args ) =
      @_[ $_[0], $_[1], $_[2], $_[3] .. $#_ ];
    return $self->module($module)->$func();
}

1;

package Saphira::API::User;

use base 'Saphira::API::DBExt';
use Digest::SHA 'sha512_hex';

sub new {
    my $class = shift;
    my $self  = bless {
        wrapper      => shift,
        server       => shift,
        id           => shift,
        nickname     => shift,
        username     => shift,
        raw_username => shift,
        op           => shift,
        permissions  => {},
        __queries    => {
            update_op => {
                query => 'update
                users
            set
                op = ?
            where
                id = ?',
                fields => [ 'op', 'id' ]
            }
          }

    }, $class;

    $self->loadPermissions();

    return $self;
}

sub getUsername {
    my $self = shift;
    return $self->{username};
}

sub getNickname {
    my $self = shift;
    return $self->{nickname};
}

sub setNickname {
    my ( $self, $nick ) = @_;
    $self->{nickname} = $nick;
}

sub getRawUsername {
    my $self = shift;
    return $self->{raw_username};
}

sub getPermission {
    my ( $self, $chan ) = @_;
    return 9 if $self->{op};
    return 6 if $self->isChannelOperator($chan);
    my $chanId = undef;
    if ( $chan =~ /^\d+$/ ) {
        $chanId = int($chan);
    } elsif ( $chan =~ /^#\w+$/ ) {
        $chanId = $self->{server}->getChannel($chan);
    } elsif ( ref $chan eq 'Saphira::API::Channel' ) {
        $chanId = $chan->getId();
    }
    return 0 unless defined $chanId and defined $self->{permissions}->{$chanId};
    return $self->{permissions}->{$chanId};
}

sub setPermission {
    my ( $self, $chan, $permissionLevel ) = @_;
    my $chanId = undef;
    if ( $chan =~ /^\d+$/ ) {
        $chanId = int($chan);
    } elsif ( $chan =~ /^#\w+$/ ) {
        $chanId = $self->{server}->getChannel($chan);
    } elsif ( ref $chan eq 'Saphira::API::Channel' ) {
        $chanId = $chan->getId();
    }
    return 0 unless defined $chanId;
    $self->{permissions}->{$chanId} = int($permissionLevel);
    $self->_storePermission( $self->{id}, $chanId, $permissionLevel );
    return 1;
}

sub isChannelOperator {
    my ( $self, $chan ) = @_;
    my $state = $self->{server}->{bot}->pocoirc();
    return
         $state->is_channel_operator( $chan, $self->{nickname} )
      || $state->is_channel_owner( $chan, $self->{nickname} )
      || $state->is_channel_halfop( $chan, $self->{nickname} );
}

sub _reloadPermissions {
    my $self = @_;
    $self->{permissions} = {};
    $self->loadPermissions();
}

sub _storePermission {
    my ( $self, $userId, $chanId, $level ) = @_;
    my $ps = $self->{wrapper}->{dbh}->prepare(
        'insert into permissions (
            userid, channelid, level
        ) values (
            ?, ?, ?
        )
        on duplicate key update level = ?'
    );
    $ps->execute( $userId, $chanId, $level, $level );
    if ( $ps->err ) {
        print "[E] Error accessing the MySQL database...\n\t$ps->errstr)";
        return 0;
    } else {
        $self->{server}->{users}->{$userId}->{$chanId} = $level;
        return 1;
    }
}

sub login {
    my ( $wrapper, $server, $nickname, $username, $raw_nick, $password ) = @_;
    $password = sha512_hex($password);
    my $ps = $wrapper->cloneDBD()->prepare(
        'select
            op, lastlogin, id
        from
            users
        where
            username = ? AND password = ?'
    );
    $ps->execute( $username, $password );
    if ( $ps->err ) {
        print "[E] Error accessing the MySQL database...\n\t$ps->errstr)";
        return 0;
    } else {
        my $result = $ps->fetchrow_hashref();
        return 0 unless defined $result;
        my $user =
          new Saphira::API::User( $wrapper, $server, $result->{id}, $nickname, $username, $raw_nick, $result->{op} );
        $user->loadPermissions();
        $server->addUser($user);
        return 1;
    }
}

sub register {
    my ( $wrapper, $server, $nickname, $username, $raw_nick, $password ) = @_;
    $password = sha512_hex($password);
    my $ps = $wrapper->cloneDBD()->prepare('insert into users(username,password) values(?,?)');
    $ps->execute( $username, $password );
    if ( $ps->err ) {
        print "[E] Error accessing the MySQL database...\n\t$ps->errstr)";
        return 0;
    } else {
        return login( $wrapper, $server, $nickname, $username, $raw_nick, $password );
    }
}

sub loadPermissions {
    my $self = shift;
    my $ps   = $self->{wrapper}->cloneDBD()->prepare(
        'select
            channelid,level
        from
            permissions
        where
            channelid in (
                select
                    id
                from
                    channels
                where
                    server = ?
            ) and userid = ?'
    );
    $ps->execute( $self->{id}, $self->{server}->{id} );
    return 0 unless not $ps->err;
    while ( my $result = $ps->fetchrow_hashref() ) {
        $self->{permissions}->{ $result->{channelid} } = $result->{level};
    }
    return 1;
}

sub logout {
    my $self = shift;
    return $self->{server}->removeUser($self);
}

sub isOperator {
    my $self = shift;
    return $self->{op};
}

sub setOperator {
    my ( $self, $op ) = @_;
    $self->{op} = ( int($op) gt 0 );
    my $ps = $self->handleQuery('update_op');

    if ( $ps->err ) {
        print '[E] MySQL error: ' . $ps->errstr . "\n";
    }

    return $ps->rows;
}

sub setPassword {
    my ( $self, $oldPassword, $newPassword ) = @_;

    my $ps = $self->{wrapper}->cloneDBD()->prepare(
        'update
            users
        set
            password = ?
        where
            id = ? and password = ?'
    );

    $ps->execute( $self->{id}, sha512_hex($newPassword), sha512_hex($oldPassword) );

    if ( $ps->err ) {
        print '[E] MySQL error: ' . $ps->errstr . "\n";
    }

    return $ps->rows;
}

1;
