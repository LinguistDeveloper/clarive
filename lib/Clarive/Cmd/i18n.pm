package Clarive::Cmd::i18n;

use Mouse;
BEGIN { extends 'Clarive::Cmd' }

our $CAPTION = 'Run i18n utilities';

use File::Find ();

sub run { &run_update }

sub run_update {
    my $self = shift;
    my (%opts) = @_;

    my @root = ( 'ci', 'comp', 'dashlets', 'email', 'fields', 'forms', 'reports', 'site', );

    my @dirs = ( 'lib', map { "root/$_" } @root );

    warn "Generating i18n files. This can take awhile...\n";

    open my $fh, '>', 'messages.po';

    print $fh qq{msgid ""},                                     "\n";
    print $fh qq{msgstr ""},                                    "\n";
    print $fh qq{"Project-Id-Version: clarive\\n"},             "\n";
    print $fh qq{"Last-Translator: clarive\\n"},                "\n";
    print $fh qq{"Language-Team: clarive\\n"},                  "\n";
    print $fh qq{"MIME-Version: 1.0\\n"},                       "\n";
    print $fh qq{"Content-Type: text/plain; charset=utf-8\\n"}, "\n";
    print $fh qq{"Content-Transfer-Encoding: 8bit\\n"},         "\n";

    my @files;
    File::Find::find(
        {
            wanted => sub {
                return if -d;

                return unless m/\.(?:pm|pl|js|html|mas)$/;

                push @files, $File::Find::name;
            },
            no_chdir => 1
        },
        @dirs
    );

    foreach my $file (sort @files) {
        _process( $fh, $file );
    }

    close $fh;

    warn "Making sure translations are unique...\n";
    system("msguniq messages.po > messages.po.uniq");

    $self->_remove_header('messages.po.uniq');

    warn "Merging translations...\n";
    my @i18n_files = glob "lib/Baseliner/I18N/*.po";
    for my $file (@i18n_files) {
        File::Copy::move( $file, "$file.bak" );
        system("msgmerge --no-fuzzy-matching $file.bak messages.po.uniq | msguniq > $file");
        unlink "$file.bak";
    }

    warn "Done\n";

    unlink 'messages.po';
    unlink 'messages.po.uniq';
    unlink 'messages.mo';

    return 1;
}

sub _remove_header {
    my $self = shift;
    my ($file) = @_;

    my $messages = do { local $/; open my $fh, '<', $file or die $!; <$fh> };
    $messages =~ s{^.*?\n\n}{}ms;
    open my $fh, '>', $file or die $!;
    print $fh $messages;
    close $fh;
}

sub _process {
    my ( $out_fh, $file ) = @_;

    open my $fh, '<', $file or die "Can't open '$file': $!";
    while (<$fh>) {
        my $id;

        while (/_(?:locl?)?\(\s*(?:'(.*?)'|"(.*?)")\s*(?:\)|,)/g) {
            $id = $1 || $2;

            if ( defined $id && $id ne '' ) {
                $id =~ s{\\}{\\\\}g;
                $id =~ s{"}{\\"}g;

                print $out_fh "#: $file\n";
                print $out_fh qq{msgid "$id"\n};
                print $out_fh qq{msgstr ""\n};
                print $out_fh "\n";
            }
        }
    }
    close $fh;
}

1;
__END__

=head1 Run i18n utilities

=head1 i18n- subcommands:

=head2 update

Update i18n files

=cut
