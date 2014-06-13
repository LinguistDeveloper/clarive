package Girl::Commit;
use Any::Moose;

has sha       => qw(is rw required 1);
has parent    => qw(is rw);
has repo      => qw(is rw required 1 weak_ref 1);
has message   => qw(is rw isa Maybe[Str]);
has author    => qw(is rw isa Str);
has committer => qw(is rw isa Str);
has date      => qw(is rw isa Num);
has tz        => qw(is rw isa Str);

sub BUILD {
    my ($self) = @_;
    my $info = $self->rev_list;
    $self->message( $info->{message_str} );
    $self->author( $info->{author} );
    $self->committer( $info->{committer} );
    $self->parent( $info->{parent} );
    $self->date( $info->{date} );
    $self->tz( $info->{tz} );
}

sub create {
    my $self = shift;
    my $repo = shift;
    $self->new( repo=>$repo, @_ );
}

sub show {
    my ($self)=@_;
    #my @ret = $self->repo->git->exec( qw/show/, 'pretty="fuller"', $self->sha );
    $self->repo->git->exec( qw/show/, $self->sha );
}

sub rev_list {
    my ($self)=@_;
    my @show = $self->repo->git->exec(qw/rev-list --parents --header --max-count=1/, $self->sha );
    my $d={};
    my $first = 1;
    for(@show){
       my ($f,$v) = /^(\w+) (.*)$/;
       if( $f ) {
          if( $f eq 'committer' ) { # get the commit date
             my ($email,$date,$tz) = $v=~ /^(.+>) (\d+) (.+)$/; 
             $v = $email; 
             $d->{date} = $date;
             $d->{tz} = $tz;
          }
          $d->{ $f } = $v;
       } else {
          my $lin = $_;
          $lin =~ s{^\s+}{}g;
          next if ( $first && ! length $lin ) || $lin eq "\0";
          push @{ $d->{message} }, $lin;
          $first=0;
       }
    }
    $d->{message_str} = join "\n", @{ $d->{message} || [] };
    $d;
}

1;
