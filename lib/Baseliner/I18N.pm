package Baseliner::I18N;
use strict;
use warnings;
use base 'Locale::Maketext';

use Carp qw(croak);
use I18N::LangTags::List;

require Locale::Maketext::Lexicon;

our $INIT;
our $INSTALLED_LANGUAGES = {};
our $LANGUAGES           = ['en'];

sub setup {
    my ( $class, %options ) = @_;

    my $paths = $options{paths};
    $paths = [$paths] unless ref $paths eq 'ARRAY';
    $paths = [ grep { defined && $_ } @$paths ];

    if ( !@$paths ) {
        if (my $features = $options{features}) {
            my @feature_paths =
              grep { -d }
              map  { $_->path . '/lib/Baseliner/I18N' } $features->list;
            push @$paths, @feature_paths;
        }

        my ($path) = __FILE__ =~ m/^(.*)\.pm$/;
        push @$paths, $path;
    }

    foreach my $path (@$paths) {
        $path = "$path/*.po" unless $path =~ m/\.(?:po|mo)$/;
    }

    Locale::Maketext::Lexicon->import(
        {
            '*'      => [ map { ( Gettext => $_ ) } @$paths ],
            _auto    => 1,
            _decode  => 1,
            _preload => 1,
            _style   => 'gettext'
        }
    );

    $INIT++;
}

sub installed_languages {
    my $class = shift;

    return $INSTALLED_LANGUAGES if %$INSTALLED_LANGUAGES;

    my ($path) = __FILE__ =~ m/^(.*)\.pm$/;

    my $languages_list = {};
    if ( opendir my $langdir, $path ) {
        foreach my $entry ( readdir $langdir ) {
            next unless $entry =~ m/\A (\w+)\.(?:pm|po|mo) \z/xms;
            my $langtag = $1;
            next if $langtag eq "i_default";
            my $language_tag = $langtag;
            $language_tag =~ s/_/-/g;
            $languages_list->{$langtag} = I18N::LangTags::List::name($language_tag);
        }
        closedir $langdir;
    }

    return $INSTALLED_LANGUAGES = $languages_list;
}

sub languages {
    my $class = shift;
    my ($languages) = @_;

    if ($languages) {
        $LANGUAGES = $languages;

        return $class;
    }

    return $LANGUAGES;
}

sub language {
    my $class = shift;

    return $LANGUAGES->[0];
}

sub localize {
    my $class = shift;

    my $handle = $class->_get_handle();

    return $handle->maketext(@_);
}

sub parse_po {
    my $class = shift;
    my ( $file, $offset ) = @_;

    open my $fh, '<:encoding(UTF-8)', $file or return '';

    my $state = 'meta';

    my @po;
    while (<$fh>) {
        s{\r|\n}{}g;

        unless ( length $_ ) {
            $state = 'meta';
            next;
        }
        next if /^#/;

        if (/^msgid /) {
            push @po, { key => '', val => '' };

            $state = 'id';
        }
        elsif (/^msgstr /) {
            $state = 'str';
        }

        if ( @po && /"(.*)"$/ ) {
            if ( $state eq 'id' ) {
                $po[-1]->{key} .= $1;
            }
            elsif ( $state eq 'str' ) {
                $po[-1]->{val} .= $1;
            }
        }
    }
    close $fh;

    $offset = '' unless $offset;
    return join( ",\n", map { qq/$offset"$_->{key}" : "$_->{val}"/ } @po );
}

sub _get_handle {
    my $class = shift;

    $class->setup unless $INIT;

    my @langtags = @{ $class->languages };
    my $handle   = $class->get_handle(@langtags);

    croak "Can't get language handle for @langtags" unless $handle;

    return $handle;
}

1;
