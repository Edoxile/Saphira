#!/usr/bin/env perl
use warnings;
use strict;
use Config::IniFiles;

package Saphira::Bot;
use base 'Bot::BasicBot';
my $version = '2.0.0';
my $botinfo =
    'Saphira (v'
  . $version
  . ') by Edoxile. See https://github.com/Edoxile/Saphira for more info, reporting issues, command usage and source code.';

sub new {
    my $class = shift;
    my $self  = bless {
        server  => shift,
        wrapper => shift
    }, $class;

    $self->{IRCNAME}   = 'SaphiraBot' . int( rand(100000) );
    $self->{ALIASNAME} = 'Saphira' . int( rand(100000) );

    $self->server( $self->{server}->{serveraddress} );
    $self->port( $self->{server}->{port} );
    $self->ssl( $self->{server}->{secure} );
    $self->nick( $self->{server}->{username} );

    $self->alt_nicks( ["PerlBot"] ), $self->username('Saphira');
    $self->name('Saphira, a Perl IRC-bot by Edoxile');
    $self->charset('utf-8');

    $self->channels($channels);

    $self->init or die "init did not return a true value - dying";

    return $self;
}

sub said     { $_[0]->processHooks( 'said',     $_[1] ); return; }
sub emoted   { $_[0]->processHooks( 'emoted',   $_[1] ); return; }
sub noticed  { $_[0]->processHooks( 'noticed',  $_[1] ); return; }
sub chanjoin { $_[0]->processHooks( 'chanjoin', $_[1] ); return; }
sub chanpart { $_[0]->processHooks( 'chanpart', $_[1] ); return; }
sub topic    { $_[0]->processHooks( 'topic',    $_[1] ); return; }
sub nick_change {
    $_[0]->processHooks( 'nick_change', ( $_[1], $_[2] ) );
    return;
}
sub kicked   { $_[0]->processHooks( 'kicked',   $_[1] ); return; }
sub userquit { $_[0]->processHooks( 'userquit', $_[1] ); return; }
sub invited  { $_[0]->processHooks( 'invited',  $_[1] ); return; }
sub help     { return $botinfo; }

sub init {

    return 1;
}

sub getAvailableModules {
    my $self = shift;

    my @availableModules = glob('modules/*.pm');
    foreach (@availableModules) {
        $_ =~ s/modules\/(.*)\.pm/$1/;
    }

    return @availableModules;
}

# Returns an array of currently loaded modules (both active and inactive ones)
sub getLoadedModules {
    my $self = shift;
    return @{ $self->{moduleList} };
}

# Returns an array of active modules
sub getActiveModules {
    my $self = shift;

    my @activeModules;
    foreach my $module ( @{ $self->{moduleList} } ) {
        next if ( $self->{modules}->{$module}->{enabled} == 0 );

        push( @activeModules, $module );
    }

    return @activeModules;
}

# Loads a module. The require() part is done in an eval{} block to catch parse
# errors (Perl ftw!) so the mane thread doesn't break when reloading broken
# module files.
sub loadModule {
    my $self    = shift;
    my $module  = shift;
    my $message = shift;
    my $args    = ( defined( $_[0] ) ? join( ' ', @_ ) : '' );

    # Lowercase and trim whitespace
    my $moduleKey = lc($module);
    $moduleKey =~ s/^\s+//;
    $moduleKey =~ s/\s+$//;

    # Check if module already loaded
    if ( $self->{modules}->{$moduleKey} ) {
        return {
            status => 0,
            code   => 0,
            string => "Module '$module' already loaded (try reloading)"
        };
    }

    # Check if module file exists
    unless ( -e './modules/' . $moduleKey . '.pm' ) {
        return {
            status => 0,
            code   => 1,
            string => "Module '$module' not found"
        };
    }

    my $modulePackage = ( "PinkieBot::Module::" . ucfirst($module) );

    # Remove package from %INC if it exists so we don't get the cached version.
    # This forces require() to actually re-parse the file again.
    delete $INC{ './modules/' . $moduleKey . '.pm' };

    # Include file and set up object in an eval{} block so we can catch parse
    # errors in module files
    eval {
        require( './modules/' . $moduleKey . '.pm' );

        $self->{modules}->{$moduleKey}->{object} =
          $modulePackage->new( $self, $message, $args );
        $self->{modules}->{$moduleKey}->{enabled} = 1;

        push( @{ $self->{moduleList} }, $moduleKey );
    };

    # Return error if the eval{} block above failed (due parse error most
    # likely)
    if ($@) {
        return { status => 0, code => 2, string => $@ };
    }

    # No perse errors, return success. Huzzah!
    return { status => 1, code => -1, string => "Module '$module' loaded" };
}

# Unloads a module (if loaded) and reloads it. Note that non-stored variables
# are not kept and the whole init()itialization function is called again.
sub reloadModule {
    my $self    = shift;
    my $module  = shift;
    my $message = shift;
    my $args    = ( defined( $_[0] ) ? join( ' ', @_ ) : '' );

    $self->unloadModule($module);
    return $self->loadModule( $module, $message, $args );
}

# Unloads a module from memory.
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

# Enables or activates a module
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

# Disables a module. Note that it stays active in memory, including any
# variables that might have changed. Disabled modules can be reenabled again,
# using the same state (including variables) prior to disabling if other modules
# didn't mess with it.
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

# Registers code to be executed on certain IRC events of type $type. Valid types
# are: connected, said, emoted, noticed, chanjoin, chanpart, topic, nick_change,
# kicked, userquit, invited andmode. See CPAN pages for Bot::BasicBot for
# parameter details and general usage. Event invited isn't in Bot::BasicBot and
# is built in here. Code hooks are usually registered through module's init()
# function,  but can theoretically be called on the fly from wherever inside a
# module.
sub registerHook {
    my ( $self, $module, $type, $function ) = @_;

    push( @{ $self->{modules}->{$module}->{hooks}->{$type} }, $function );

    return {
        status => 1,
        code   => -1,
        string => "Hook with type '$type' for module '$module' registered"
    };
}

# Unregisters a code hook from a module. $function must contain the exact same
# code used to register to unregister it.
sub unregisterHook {
    my ( $self, $module, $type, $function ) = @_;

    unless (
        grep( $function, @{ $self->{modules}->{$module}->{hooks}->{$type} } ) )
    {
        return {
            status => 0,
            code   => 0,
            string =>
              "Hook with type '$type' for module '$module' does not exist"
        };
    }

    @{ $self->{modules}->{$module}->{hooks}->{$type} } =
      grep { $_ != $function }
      @{ $self->{modules}->{$module}->{hooks}->{$type} };

    return {
        status => 1,
        code   => -1,
        string => "Hook with type '$type' for module '$module' unregistered"
    };
}

# Unregisters all hooks from a module
sub unregisterHooks {
    my ( $self, $module, $type ) = @_;

    $self->{modules}->{$module}->{hooks}->{$type} = ();

    return {
        status => 1,
        code   => -1,
        string =>
          "All hooks with type '$type' for module '$module' unregistered"
    };
}

# Returns an array of functions with registered hooks for a module
sub getHooks {
    my ( $self, $module, $type ) = @_;

    return @{ $self->{modules}->{$module}->{hooks}->{$type} };
}

# todo
sub hookRegistered {
    my ( $self, $module, $type ) = @_;

    return @{ $self->{modules}->{$module}->{hooks}->{$type} };
}

# Process hooks of type $type. Loops through every active (!) module and calls
# hooked function(s), if any. Function calls are done in an eval{} block to
# catch logic errors and unloads the module if it happens to find an error.
sub processHooks {
    my ( $self, $type, $data ) = @_;

    # For each module
    while ( my ( $module, $moduleHash ) = each( %{ $self->{modules} } ) ) {
        next if ( $moduleHash->{enabled} == 0 );

        # For each hook of said type
        foreach ( @{ $moduleHash->{hooks}->{$type} } ) {
            eval { $self->$_($data); };

            # Complain and unload module on error
            if ($@) {
                $self->notice(
                    who     => $data->{who},
                    channel => $data->{channel},
                    body =>
"\x02Module '$module' encountered an error and will be unloaded:\x0F $@",
                    address => $data->{address}
                );

                $self->unloadModule($module);
            }
        }
    }
}

# Returns whether module $module is loaded
sub moduleLoaded {
    my ( $self, $module ) = @_;
    return ( exists( $self->{modules}->{ lc($module) } ) ? 1 : 0 );
}

# Returns whether module $module is both loaded and active
sub moduleActive {
    my ( $self, $module ) = @_;
    return (
        (
            $self->moduleLoaded($module)
              && ( $self->{modules}->{ lc($module) }->{enabled} == 1 )
        ) ? 1 : 0
    );
}

# Returns a module
sub module {
    my ( $self, $module ) = @_;
    unless ( $self->moduleLoaded($module) ) {
        return undef;
    }
    return $self->{modules}->{ lc($module) }->{object};
}

sub moduleFunc {
    my ( $self, $module, $func, @args ) = @_[ ARG0, ARG1, ARG2, ARG3 .. $#_ ];
    return $self->module($module)->$func();
}

1;

package Saphira::Wrapper;

use DBI;

sub new {
    my $class = shift;
    my $self  = bless {
        mysql_host     => shift,
        mysql_username => shift,
        mysql_password => shift,
        mysql_database => shift,
        servers        => {},
        bots           => {}
    }, $class;

    $self->{dbd} = DBI->connect(
        sprintf(
            'DBI:mysql:%s;host=%s',
            $self->{mysql_database},
            $self->{mysql_host}
        ),
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
    }
    else {
        return undef;
    }
}

sub init {
    my $self = @_;
    $ps = $self->{dbd}->prepare(
        'select
            *
        from
            servers'
    );
    $ps->execute();
    if ( $ps->err ) {
        print '[E] MySQL select error: ' . $ps->errstr . "\n";
        return 0;
    }
    while ( $result = $ps->fetchrow_hashref() ) {
        $self->{servers}->{ $result->{id} } = new Saphira::API::Server(
            $result->{id},       $result->{servername},
            $result->{address},  $result->{port},
            $result->{secure},   $result->{username},
            $result->{password}, $result->{nickservpassword},
            $self
        );
        $self->{bots}->{ $result->{id} } =
          new Saphira::Bot( $self->{servers}->{ $result->{id} }, $self );
    }

    return 1;
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

1;

package Saphira::API::DBExt;

use DBI;

our $__queries = {};

sub new {
    my $class = shift;
    my $self = bless { wrapper => shift }, $class;
    return $self;
}

sub handleQuery {
    my ( $self, $queryType ) = @_;
    return unless defined $__queries{$queryType}->{query};
    return unless defined $__queries{$queryType}->{fields};
    return unless $__queries{$queryType}->{fields} gt 0;
    my $ps =
      $self->{wrapper}->{dbd}->prepare( $__queries{$queryType}->{query} );
    my $n = 1;
    foreach $field ( @{ $__queries->{fields} } ) {
        $ps->bind_param( $n, $self->{$field} );
        $n++;
    }
    $ps->execute();
    return $ps;
}

1;

package Saphira::API::Server;

use base 'Saphira::API::DBExt';

our $__queries = {
    insert => {
        query =>
'update servers set address = ?, port = ?, secure = ?, password = ?, nickservpassword = ? where id = ?',
        fields =>
          ( 'address', 'port', 'secure', 'password', 'nickservpassword', 'id' )
    },
    select_channels {
        query  => 'select * from channels where state = 1 and server = ?',
        fields => ('id')
    }
  } sub new {
    my $class = shift;
    my $self  = bless {
        id           => shift,
        servername   => shift,
        address      => shift,
        port         => shift,
        secure       => shift,
        username     => shift,
        password     => shift,
        nickpassword => shift,
        wrapper      => shift,
        bot          => 0,
        active       => 0,
        channels     => {},
        users        => {}
    }, $class;

    $self->init();

    return $self;
}

sub init {
    $self->{active} = 1;
    my $ps = $self->handleQuery('select_channels');
    while ( $result = $ps->fetchrow_hashref() ) {
        $self->{channels}->{ $result->{id} } =
          new Saphira::API::Channel( $self, $result->{id}, $result->{name},
            $result->{password}, $result->{state}, 1, $result->{log} );
    }
    $self->{bot} = new Saphira::Bot( $self, $self->{wrapper} );
}

sub getServerName {
    my $self = @_;
    return $self->{servername};
}

sub getServerAddress {
    my $self = @_;
    return $self->{address};
}

sub getServerPort {
    my $self = @_;
    return $self->{port};
}

sub useSecureConnection {
    my $self = @_;
    return $self->{secure};
}

sub getChannel {
    my ( $self, $channelName ) = @_;
    my $key = $self->getChannelId($channelName);
    return unless defined $key;
    return $self->{channels}->{$key};
}

sub getWrapper {
    my $self = @_;
    return $self->{wrapper};
}

sub setPassword {
    my ( $self, $password ) = @_;
    $self->{password} = $password;
    $self->_update();
}

sub getUsers {
    my $self = @_;
    return @{ values $self->{users} };
}

sub addUser {
    my ( $self, $user ) = @_;
    return unless not defined $self->{users}->{ $user->getUsername() };
    $self->{users}->{ $user->getUsername() } = $user;
    return 1;
}

sub removeUser {
    my ( $self, $username ) = @_;
    return unless defined $self->{users}->{$username};
    $self->{users}->{$username} = undef;
    return 1;
}

sub isActive {
    my $self = shift;
    return $self->{active};
}

sub _setActive {
    my ( $self, $active ) = @_;
    $self->{active} = ( $active > 0 );
}

sub _getServerId {
    my $self = @_;
    return $self->{id};
}

sub _getChannelId {
    my ( $self, $channelName ) = @_;
    foreach $key ( keys %{ $self->{channels} } ) {
        if ( $self->{channels}->{$key}->{name} eq $channelName ) {
            return $key;
        }
    }
    return undef;
}

1;

package Saphira::API::Channel;

use base 'Saphira::API::DBExt';

our $__queries = {
    insert => {
        query => 'insert into channels (
                server, name, log, password
            ) values (
                ?, ?, ?, ?
            )',
        fields => ( 'server', 'name', 'logging', 'password' )
    },
    update => {
        query => 'update channels set
                      server = ?,
                      log = ?,
                      password = ?
                  where id = ?',
        fields => ( 'server', 'logging', 'password', 'id' )
    }
  }

  sub new {
    my $class = shift;
    my $self  = bless {
        server     => shift,
        id         => shift,
        name       => shift,
        password   => shift,
        state      => shift,
        persistent => shift,
        logging    => shift
    }, $class;

    $self->init();

    return $self;
}

sub getServer {
    my $self = @_;
    return $self->{server};
}

sub getId {
    my $self = @_;
    return $self->{id};
}

sub getName {
    my $self = @_;
    return $self->{name};
}

sub getModes {
    my $self = @_;

    #TODO: finish
}

sub setModes {
    my ( $self, $newModes ) = @_;

    #TODO: finish
}

sub getTitle {
    my $self = @_;

    #TODO: finish
}

sub setTitle {
    my ( $self, $newTitle ) = @_;

    #TODO: finish
}

sub isPersistent {
    my $self = @_;
    return $self->{persistent};
}

sub setPersistency {
    my ( $self, $persistency ) = @_;
    $persistency = int($persistency);
    $persistency = ( $persistency > 0 ) ? 1 : 0;
    return unless $self->{persistent} ne $persistency;
    if ( $persistency and $self->{state} eq 0 ) {
        $self->_enalbe();
    }
    else if ( $persistency and $self->{state} eq -1 ) {
        $self->_insert();
    }
    else {
        $self->_disable();
    }
}

sub _insert {
    my $self = @_;
    $self->{state} = 1;
}

sub _disable {
    my $self = @_;
    $self->{state} = 0;
}

sub _enable {
    my $self = @_;
    $self->{state} = 1;
}

1;

package Saphira::API::User;

use base 'Saphira::API::DBExt';
use Digest::SHA 'sha512_hex';

our $__queries = {
    insert => {
        query => 'insert into users (
                server, name, log, password
            ) values (
                ?, ?, ?, ?
            )',
        fields => ( 'server', 'name', 'logging', 'password' )
    },
    update_pass => {
        query => 'update users set
                password = ?
            where
                id = ?',
        fields => ( 'password', 'id' )
    },
    update_lastlogin => {
        query => 'update users set
                      lastlogin = now()
                  where id = ?',
        fields => ('id')
    },
    select_permissions => {
        query => 'select
                channelid, level
            from
                permissios
            where
                userid = ?',
        fields => ('id')
    }
  }

  sub new {
    my $class = shift;
    my $self  = bless {
        wrapper     => shift,
        server      => shift,
        id          => shift,
        username    => shift,
        identity    => shift,
        host        => shift,
        lastlogin   => shift,
        permissions => {}
    }, $class;

    $self->init();

    return $self;
}

sub getUser {
    my $self = @_;
    return $self->{name};
}

sub getIdentity {
    my $self = @_;
    return $self->{identity};
}

sub getHost {
    my $self = @_;
    return $self->{host};
}

sub getPermission {
    my ( $self, $chan ) = @_;
    my $chanId = undef;
    if ( $chan ~= /^\d+$/ ) {
        $chanId = int($chan);
    }
    else if ( $chan ~= /^#\w+$/ ) {
        $chanId = $self->{server}->getChannel($chan);
    }
    else if ( ref $chan eq 'Saphira::API::Channel' ) {
        $chanId = $chan->getId();
    }
    return unless defined $chanId;
    return unless defined $self->{permissions}->{$chanId};
    return $self->{permissions}->{$chanId};
}

sub setPermission {
    my ( $self, $chan, $permissionLevel ) = @_;
    my ( $self, $chan ) = @_;
    my $chanId = undef;
    if ( $chan ~= /^\d+$/ ) {
        $chanId = int($chan);
    }
    else if ( $chan ~= /^#\w+$/ ) {
        $chanId = $self->{server}->getChannel($chan);
    }
    else if ( ref $chan eq 'Saphira::API::Channel' ) {
        $chanId = $chan->getId();
    }
    return 0 unless defined $chanId;
    $self->{permissions}->{$chanId} = int($permissionLevel);
    $self->_storePermission( $self->{id}, $chanId, $permissionLevel );
    return 1;
}

sub _reloadPermissions {
    my $self = @_;
    $ps = $self->handleQuery('select_permissions');
    while ( $fields = $ps->fetchrow_hashref() ) {
        $self->{permissions}->{ $fields->{chanid} } = int $fields->{level};
    }
}

sub _storePermission {
    my ( $self, $userId, $chanId, $level ) = @_;
    my $ps = $self->{wrapper}->{dbh}->prepare(
        'insert into permissions(
            userid,
            channelid,
            level
        )
        values(
            ?,
            ?,
            ?
        )
        on duplicate key update level=?'
    );
    $ps->execute( $userId, $chanId, $level, $level );
    if ( $ps->err ) {
        print "[E] Error accessing the MySQL database...\n\t$ps->errstr)";
    }
    else {
        #TODO!
    }
}

sub setUsername {
    my ( $self, $new ) = @_;
    $self->{user} = $new;
}

sub getLastLogin {
    my $self = @_;
    return $self->{lastlogin};
}

sub login {
    my ( $wrapper, $server, $username, $identity, $host, $password ) = @_;
    $password = sha512_hex($password);
    my $ps = $wrapper->{dbd}->prepare(
        'select
            lastlogin, id
        from
            users
        where
            username = ? AND password = ?'
    );
    my $result = $ps->execute( $username, $password );
    if ( $ps->err ) {
        print "[E] Error accessing the MySQL database...\n\t$ps->errstr)";
    }
    else {
        my $result = $ps->fetchrow_hashref();
        return 0 unless defined $result;
        $wrapper->post( $result->{lastlogin}, "Some more shit here" );
        my $user =
          new Saphira::API::User( $wrapper, $server, $result->{id}, $username,
            $identity, $host, $result->{lastlogin} );

        #TODO: Search for permissions and put them in the object
        $server->addUser($user);
        return $user;
    }
}

sub logout {
    my $self = @_;
    return $self->{server}->removeUser($self);
}

1;
