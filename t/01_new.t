use strict;
use warnings;
use Test::More tests => 3;
use WWW::Spamla;

{
    my $la = WWW::Spamla->new;
    isa_ok($la, 'WWW::Spamla', 'new()');
}

{
    my $la = WWW::Spamla->new(ua => LWP::UserAgent->new));
    isa_ok($la, 'WWW::Spamla', 'new(ua=>$ua)');
}

can_ok('WWW::Spamla', qw(error list message));
