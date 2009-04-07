use 5.006;
use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME          => 'WWW::Spamla',
    AUTHOR        => 'gray <gray@cpan.org>',
    LICENSE       => 'perl',
    VERSION_FROM  => 'lib/WWW/Spamla.pm',
    ABSTRACT_FROM => 'lib/WWW/Spamla.pm',
    PREREQ_PM     => {
        'Class::Accessor::Fast' => 0,
        'HTML::TableExtract'    => 0,
        'HTML::TokeParser'      => 0,
        'LWP::UserAgent'        => 0,
        'Test::More'            => 0,
        'URI'                   => 0,
    },
    (eval { ExtUtils::MakeMaker->VERSION(6.46) } ? (
        META_MERGE => {
            resources => {
                repository => 'http://github.com/gray/www-spamla',
            }
        }
    ) : () ),
    dist          => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean         => { FILES => 'WWW-Spamla-*' },
);
