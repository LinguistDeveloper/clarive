package Baseliner::I18N;
use strict;
use warnings;

use I18N::LangTags::List;

our ($PATH)                = __FILE__ =~ m/^(.*)\.pm$/;
our $INSTALLED_LANGUAGES = {};
our $LANGUAGES           = ['en'];
our $CLASS;

sub setup {
    my ($class, %options) = @_;

    require Locale::Maketext::Simple;
    Locale::Maketext::Simple->import(
        Style    => 'gettext',
        Path     => $PATH,
        Decode   => 1,
        Class    => $class,
        Subclass => 'Auto',
        %options
    );

    $CLASS = "$class\::Auto";
}

sub installed_languages {
    my $class = shift;

    $class->setup unless $CLASS;

    return $INSTALLED_LANGUAGES if %$INSTALLED_LANGUAGES;

    my $languages_list = {};
    if (opendir my $langdir, $PATH) {
        foreach my $entry (readdir $langdir) {
            next unless $entry =~ m/\A (\w+)\.(?:pm|po|mo) \z/xms;
            my $langtag = $1;
            next if $langtag eq "i_default";
            my $language_tag = $langtag;
            $language_tag =~ s/_/-/g;
            $languages_list->{$langtag} =
              I18N::LangTags::List::name($language_tag);
        }
        closedir $langdir;
    }

    return $INSTALLED_LANGUAGES = $languages_list;
}

sub languages {
    my $class = shift;
    my ($languages) = @_;

    $class->setup unless $CLASS;

    if ($languages) {
        $LANGUAGES = $languages;
        loc_lang(@$languages);

        return $class;
    }

    return $LANGUAGES;
}

sub language {
    my $class = shift;

    $class->setup unless $CLASS;

    my $lang = $CLASS->get_handle(@{$class->languages});
    $lang =~ s/.*:://;
    $lang =~ s/=.*//;

    return $lang;
}

sub localize {
    my $class = shift;

    $class->setup unless $CLASS;

    return loc(@_);
}

sub parse_po {
    my $class = shift;
    my ($file, $offset) = @_;

    open my $fh, '<:encoding(UTF-8)', $file or return '';

    my $state = 'meta';

    my @po;
    while (<$fh>) {
        s{\r|\n}{}g;

        unless (length $_) {
            $state = 'meta';
            next;
        }
        next if /^#/;

        if (/^msgid /) {
            push @po, {key => '', val => ''};

            $state = 'id';
        }
        elsif (/^msgstr /) {
            $state = 'str';
        }

        if (@po && /"(.*)"$/) {
            if ($state eq 'id') {
                $po[-1]->{key} .= $1;
            }
            elsif ($state eq 'str') {
                $po[-1]->{val} .= $1;
            }
        }
    }
    close $fh;

    $offset = '' unless $offset;
    return join(",\n", map {qq/$offset"$_->{key}" : "$_->{val}"/} @po);
}

1;
