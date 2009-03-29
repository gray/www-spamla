package WWW::Spamla;

use strict;
use warnings;
use base qw(Class::Accessor::Fast);

use HTML::TableExtract;
use HTML::TokeParser;
use LWP::UserAgent;
use URI;

our $VERSION = '0.04';

use constant DEBUG => $ENV{WWW_SPAMLA_DEBUG} || 0;
use constant BASE_URI => URI->new('http://spam.la/');

__PACKAGE__->mk_ro_accessors(qw(error));

sub new {
    my ($class, %params) = @_;

    unless (ref $params{ua} and $params{ua}->isa(q(LWP::UserAgent))) {
        $params{ua} = LWP::UserAgent->new(agent => __PACKAGE__.'/'.$VERSION);
    }

    return bless \%params, $class;
}

BEGIN {
    package WWW::Spamla::ListItem;
    use base qw(Class::Accessor::Fast);
    __PACKAGE__->mk_ro_accessors(qw(id to from subject));
}

sub list {
    my ($self, %params) = @_;

    my %fields;
    if (my $address = $params{address}) {
        ($fields{f} = $address) =~ s/ \@spam\.la $ //x;
    }
    if (my $start_id = $params{start_id}) {
        $fields{start_id} = $start_id;
    }

    my $uri = BASE_URI;
    if (keys %fields) {
        $uri = BASE_URI->clone;
        $uri->query_form(\%fields);
    }

    my $res = $self->{ua}->get($uri);
    unless ($res->is_success) {
        $self->{error} = $res->status_line;
        return;
    }

    my $te = HTML::TableExtract->new(
        headers => [ 'To', 'From', 'Click Subject To Read Email' ],
        keep_html => 1,
   );
    $te->parse($res->content);

    my $table = $te->first_table_found or do {
        $self->{error} = q(No messages table found);
        return;
    };

    my @list;

    for my $row ($te->rows) {
        my ($to, $from, $subject) = @$row;
        ($to) = $to =~ m[ \?f=([^"]+)" ]x;
        my ($id) = ($subject||'') =~ m[ \?id=(\d+) ]x;

        for ($from, $to, $subject) {
            my $stripper = HTML::TableExtract::StripHTML->new;
            $_ = $stripper->strip($_);
        }

        my %fields = (
            to => $to, from => $from, id => $id, subject => $subject
       );
        push @list, WWW::Spamla::ListItem->new(\%fields);
    }

    # Last row is an emebedded table with the back link.
    pop @list unless $list[-1]->from;

    $self->{error} = undef;
    return @list;
}

sub message {
    my ($self, $id) = @_;

    my $uri = BASE_URI->clone;
    $uri->query_form(id => $id, h => 1, html => 1);

    my $res = $self->{ua}->get($uri, Referer => BASE_URI);
    unless ($res->is_success) {
        $self->{error} = $res->status_line;
        return;
    }

    my $parser = HTML::TokeParser->new($res->content_ref);
    $parser->{textify} = { br => sub {"\n"} };

    my $title;
    if ($parser->get_tag('title')) {
        $title = $parser->get_text('/title');
    }
    unless ($title and $title =~ /^Message #$id/) {
        $self->{error} = q{Error finding message};
        return;
    }

    my $msg = '';

    if ($parser->get_tag('pre')) {
        $msg = $parser->get_text('/pre');
    }
    else {
        $self->{error} = q{Couldn't find headers};
        return;
    }

    if ($parser->get_tag('pre')) {
        $msg .= $parser->get_text('/pre');
    }
    else {
        $self->{error} = q{Couldn't find body};
        return;
    }

    $self->{error} = undef;
    return $msg;
}

1;

__END__

=head1 NAME

WWW::Spamla - interface to Spam.la

=head1 SYNOPSIS

    my $la = WWW::Spamla->new;

    my @list = $la->list(address => 'bubba');

    for my $item (@list) {
        printf "%d: %s - %s\n", $item->id, $item->from, $item->subject;

        if ($item->subject =~ /account/) {
            my $msg = $la->message($item->id);
            my $parsed = Email::MIME->new($msg);
            # ...
        }
    }

=head1 DESCRIPTION

The C<WWW::Spamla> module provides an interface to the Spam.la website.

=head1 METHODS

=over

=item $la = WWW::Spamla->B<new>

=item $la = WWW::Spamla->B<new>(ua => $ua)

Creates a new WWW::Spamla object. The constructor accepts an optional
LWP::UserAgent derived object.

=item @list = $la->B<list>

=item @list = $la->B<list>(address => $address, start_id => $id)

Returns a list of the 20 latest messages. The list can optionally be started
from a specific id, and filtered by address. Returns undef if an error
occurred. The return list consists of objects of type WWW::Spam::ListItem,
which provide accessors to data B<id>, B<to>, B<from>, B<subject>.

=item @message = $la->B<message>($id)

Given a message id, fetches and returns the corresponding MIME message. It can
then be parsed by any MIME handler, like L<Email::MIME> or L<MIME::Parser>.
Returns undef if an error occurred.

=item $error = $la->B<error>

Returns the error, if one occurred.

=back

=head1 SEE ALSO

L<http://spam.la/>

=head1 REQUESTS AND BUGS

Please report any bugs or feature requests to
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=WWW-Spamla>. I will be
notified, and then you'll automatically be notified of progress on your bug as
I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc WWW::Spamla

You can also look for information at:

=over

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/WWW-Spamla>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/WWW-Spamla>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=WWW-Spamla>

=item * Search CPAN

L<http://search.cpan.org/dist/WWW-Spamla>

=back

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 gray <gray at cpan.org>, all rights reserved.

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 AUTHOR

gray, <gray at cpan.org>

=cut
