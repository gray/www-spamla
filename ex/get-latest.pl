#!/usr/bin/env perl
use strict;
use warnings;
use WWW::Spamla;

my $address = shift;
my $interval = 180;

my $la = WWW::Spamla->new;

my ($max_id, $last_id) = (0) x 2;

while (1) {
    my @list = $la->list(address => $address, start_id => $last_id);
    next if not @list or $la->error;

    # Same list as from last iteration.
    next if $max_id and $list[0]->id == $max_id;

    for my $item (@list) {
        last if $item->id == $max_id;
        printf "%d: %s | %s | %s\n", $item->id, $item->to, $item->from,
            $item->subject;
    }

    # Find any extra messages that occurred within the poll interval and are
    # already off the front page.
    if ($max_id and $list[-1]->id > ($last_id || $max_id) + 1) {
        $last_id = $list[-1]->id;
        sleep 1;
        redo;
    }
    else {
        $max_id = $list[0]->id;
    }
}
continue {
    $last_id = 0;
    sleep $interval;
}
