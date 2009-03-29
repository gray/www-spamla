#!/usr/bin/env perl
use strict;
use warnings;
use WWW::Spamla;
use XML::RSS;

my $address = shift;
my $interval = 180;

my $la = WWW::Spamla->new;
my $rss = XML::RSS->new;

my @list = $la->list(address => $address);
exit if not @list or $la->error;

for my $item (@list) {
    $rss->add_item(
        title       => sprintf("%s | %s", $item->from, $item->subject),
        description => sprintf(
            "From: %s\nTo: %s\nSubject: %s\nMessage: %s\n",
            $item->from, $item->to, $item->subject, $item->id
        ),
        link        => sprintf("http://spam.la/?id=%d", $item->id),
    );
}

print $rss->as_string;
