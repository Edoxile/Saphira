#!/usr/bin/env perl

package Saphira::Module::Manage;
use base 'Saphira::Module';
use Digest::SHA 'sha512_hex';

sub init {
    my ($self, $message, $args) = @_;
    
    $self->registerHook('said', \&handleSaidListModules);
    $self->registerHook('said', \&handleSaidListAvailable);
    $self->registerHook('said', \&handleSaidListLoaded);
    $self->registerHook('said', \&handleSaidListActive);
    $self->registerHook('said', \&handleSaidLoadModule);
    $self->registerHook('said', \&handleSaidUnloadModule);
    $self->registerHook('said', \&handleSaidReloadModule);
    $self->registerHook('said', \&handleSaidEnableModule);
    $self->registerHook('said', \&handleSaidDisableModule);
    $self->registerHook('said', \&handleSaidModuleLoaded);
    $self->registerHook('said', \&handleSaidModuleActive);
    $self->registerHook('said', \&handleSaidInfo);
    $self->registerHook('said', \&handleSaidUpdate);
    $self->registerHook('said', \&handleSaidCmd);
    $self->registerHook('said', \&handleSaidLogin);
    $self->registerHook('said', \&handleSaidLogout);
    $self->registerHook('said', \&handleSaidChanJoin);
    $self->registerHook('said', \&handleSaidChanPart);
    $self->registerHook('invited', \&handleInvited);
}

sub getAuthLevel {
    my ($server, $message) = @_;
    my $user = $server->getUser($message->{raw_nick});
    return 0 unless defined $user;
    return 9 if $user->isOperator();
    return $user->getPermission($message->{channel});
}

sub handleInvited {
    my ($wrapper, $server, $message) = @_;
    
    $server->joinChannel($message->{channel});
}

sub handleSaidChanJoin {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ m/^!join\s(.+?)(?:\s(.+?))?$/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $channel = $1;
    my $key = $2 || '';
    
    $server->joinChannel($channel, $key);    
}

sub handleSaidChanPart {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ m/^!part\s(.+?)(?: (.+?))?$/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $channel = $1;
    my $message = $2;
    
    $server->partChannel($channel, $message);
}

sub handleSaidLogin {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ m/^!login ([^ ]+) (.*)/);
    
    print '[I] Logging in: <'.$message->{raw_nick}.'>, using username: ' . $1 . "\n";
    
    if ( Saphira::API::User::login($wrapper, $server, $message->{who}, $1, $message->{raw_nick}, $2) ) {
        $server->{bot}->reply("\x02Logged in succesful!\x0F",$message);
    } else {
        $server->{bot}->reply("\x02Logging in failed!\x0F Perhaps you used the wrong password?", $message);
    }
}

sub handleSaidLogout {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ m/^!logout/);
    
    $server->getUser($message->{raw_nick})->logout();
}

sub handleSaidListModules {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!list(?: all)? modules$/);
    
    my @availableModules = $wrapper->getAvailableModules();
    my @activeModules = $wrapper->getActiveModules();
    my @loadedModules = $wrapper->getLoadedModules();
    
    my %activeModulesHash = map{$_ => 1} @activeModules;
    my %loadedModulesHash = map{$_ => 1} @loadedModules;
    
    my @loadedButDisabledModules = grep(!defined($activeModulesHash{$_}), @loadedModules);
    my @availableButNotLoadedModules = grep(!defined($loadedModulesHash{$_}), @availableModules);
    
    my $reply = ("\x02Active:\x0F " . join(', ', sort(@activeModules)) . '.');
    $reply   .= (" \x02Disabled:\x0F " . join(', ', sort(@loadedButDisabledModules)) . '.') if (scalar(@loadedButDisabledModules) > 0);
    $reply   .= (" \x02Available:\x0F " . join(', ', sort(@availableButNotLoadedModules)) . '.') if (scalar(@availableButNotLoadedModules) > 0);
    
    $server->{bot}->reply($reply, $message);
}

sub handleSaidListAvailable {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!list available(?: modules)?$/);
    
    $server->{bot}->reply(('Available modules: ' . join(', ', sort($wrapper->getAvailableModules()))), $message);
}

sub handleSaidListLoaded {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!list loaded(?: modules)?$/);
    
    $server->{bot}->reply(('Loaded modules: ' . join(', ', sort($wrapper->getLoadedModules()))), $message);
}

sub handleSaidListActive {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!list active(?: modules)?$/);
    
    $server->{bot}->reply(('Active modules: ' . join(', ', sort($wrapper->getActiveModules()))), $message);
}

sub handleSaidLoadModule {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!load(?: module)? ([^ ]+)(?: (.+))?/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $module = $1;
    my $args   = $2;
    
    if ($module =~ /,/) {
        my @modules = split(',', $module);
        foreach (@modules) {
            my $ret = $wrapper->loadModule($_, $message);
            $server->{bot}->reply("$ret->{string} [Status: $ret->{status}, Code: $reply->{code}]", $message);
        }
    } else {
        my $reply = $wrapper->loadModule($module, $message, $args);
        $server->{bot}->reply("$reply->{string} [Status: $reply->{status}, Code: $reply->{code}]", $message);
    }
}

sub handleSaidUnloadModule {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!unload(?: module)? (.+)/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my @modules = split(',', $1);
    
    MODULE: foreach (@modules) {
        if (lc($_) eq 'manage') {
            $server->{bot}->reply("I can't unload the Manage module... How else would you control me?", $message);
            next MODULE;
        }
        my $reply = $wrapper->unloadModule($_);
        $server->{bot}->reply("$reply->{string} [Status: $reply->{status}, Code: $reply->{code}]", $message);
    }
}

sub handleSaidReloadModule {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!reload(?: module)? ([^ ]+)(?: (.+))?/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $module = $1;
    my $args   = $2;
    
    if ($module =~ /,/) {
        my @modules = split(',', $module);
            
        foreach (@modules) {
            my $ret = $wrapper->reloadModule($_, $message);
            $server->{bot}->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
        }
    
    } else {
        my $ret = $wrapper->reloadModule($module, $message, $args);
        $server->{bot}->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
    }
}

sub handleSaidEnableModule {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!enable(?: module)? (.+)/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $ret = $wrapper->enableModule($1);
    
    $server->{bot}->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidDisableModule {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!disable(?: module)? (.+)/);
    return unless (getAuthLevel($server, $message) gt 6);
    
    my $ret = $wrapper->disableModule($1);
    
    $server->{bot}->reply("$ret->{string} [Status: $ret->{status}, Code: $ret->{code}]", $message);
}

sub handleSaidModuleLoaded {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!(?:is )?(?:module )?(.+)(?: loaded)\?$/);
    
    $server->{bot}->reply(($wrapper->moduleLoaded($1) ? 'It\'s loaded alright!' : 'Nope! Module not loaded.'), $message);
}

sub handleSaidModuleActive {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!(?:is )?(?:module )?(.+)(?: active)\?$/);
    
    $server->{bot}->reply(($wrapper->moduleActive($1) ? 'It\'s active alright!' : 'Nope! Module not active.'), $message);
}

sub handleSaidInfo {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^(?:!Saprhia|Saphira\?)$/i);
    
    $server->{bot}->reply($server->{bot}->help(), $message);
}

sub handleSaidUpdate {
    my ($wrapper, $server, $message) = @_;
    
    return unless ($message->{body} =~ /^!update$/);
    
    my @output = `git pull`;
    
    $server->{bot}->reply(join('', @output), $message);
}

sub handleSaidCmd {
    my ($wrapper, $server, $message) = @_;
    return unless ($message->{body} =~ /^!cmd (.+)/);
    
    return unless (getAuthLevel($server, $message) gt 8);
    
    my @output = `$1 2>&1`;
    
    my $prefix = '';
    if ($? != 0) {
        $prefix .= "\x02Error:\x0F ";
    }
    
    $server->{bot}->reply(($prefix . join('', @output)), $message);
}

1;