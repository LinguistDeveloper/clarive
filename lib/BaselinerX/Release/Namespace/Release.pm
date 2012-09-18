package BaselinerX::Release::Namespace::Release;
use Moose;
use Baseliner::Utils;
use Try::Tiny;
use Catalyst::Exception;
use Moose::Autobox;
use Baseliner::Core::URL;
use Baseliner::Core::Namespace;

has 'locked_reason'  => ( is=>'rw', isa=>'Str', default=>'' ); 

with 'Baseliner::Role::Namespace::Release';
with 'Baseliner::Role::JobItem';
with 'Baseliner::Role::Transition';
with 'Baseliner::Role::Approvable';

has 'ns_type' => ( is=>'ro', isa=>'Str', default=>_loc('Release') );


sub BUILDARGS {
    my $class = shift;

    if( defined ( my $r = $_[0]->{row} ) ) {
        my @contents = try {
            my $rs = $r->bali_release_items;
            rs_hashref( $rs );
            $rs->all;
        } catch { () };
        return {
                ns      => 'release/' . $r->id,
                ns_name => $r->name,
                ns_info => $r->description || $r->name,
                user    => $r->username || '',
                date    => $r->get_column('ts'),
                icon_on => '/static/images/icons/release.gif',
                icon_off=> '/static/images/icons/release.gif',
                service => 'service.runner.release',
                provider=> 'namespace.release',
                inspector  => Baseliner::Core::URL->new(
                type  => 'page',
                title => $r->name,
                url   => '/release/edit?id_rel=' . $r->id
            ),
                related => [ $r->ns ],
                ns_id   => $r->id,
                ns_data => { $r->get_columns, contents=>\@contents },
        };
    } else {
        return $class->SUPER::BUILDARGS(@_);
    }
}

sub row {
    my $self = shift;
    return Baseliner->model('Baseliner::BaliRelease')->find( $self->ns_id );
}

sub can_job {
    my ( $self, %p ) = @_;
    my $bl = $p{bl};
    my $job_type = $p{job_type};

    # check if it's active
    unless( $self->ns_data->{active} ) {
        $self->why_not( 'Release not active' );
        return $self->_can_job( 0 );
    }

     # check if it's pending to approve  
    # warn "RELEASE NS: " . $self->ns;
    unless ( $bl ne 'PROD'
        || Baseliner->model('Request')->approvals_active
        || Baseliner->model('Request')->list (ns=>$self->ns, pending=>1)->{count} eq 0 ) {
        $self->why_not( _loc('Release %1 is pending to approve.', $self->ns_name) );
        # $self->why_not( 'Release is pending to approve.' );
        return $self->_can_job( 0 );
    }
    
    # check can_job of contents
    my $can_job = 1;
    my @why;
    for my $item ( $self->contents ) {
        #use Data::Dumper;warn $self->ns_name . "\n" . Dumper $item;
        next unless ref $item;
        next if $item->isa( 'Baseliner::Core::Namespace' );
        unless( $item->can_job( bl=>$bl, job_type=>$job_type, ns=>$self->ns ) ) {
            push @why, $item->why_not;
            $can_job = 0;
        }
    }
    $self->why_not( join ', ', @why ) unless $can_job;
    return $self->_can_job( $can_job );
}

sub user_can_edit {
    my ( $self, $username ) = @_;
    if( $username && ! Baseliner->model('Permissions')->is_root( $username ) ) {
        my @ns = Baseliner->model('Permissions')->user_namespaces( $username ); 
        return 0 unless @ns;
        return 0 unless @ns->any eq $self->related->any;
    }
    return 1;
}

sub contents {
    my $self = shift;
    my @items;

    # load contents data
    unless( ref $self->ns_data->{contents} ) { 
        my $rs = Baseliner->model('Baseliner::BaliReleaseItems')->search({ id_rel=> $self->ns_data->{id} });
        rs_hashref( $rs );
        $self->ns_data->{contents} = [ $rs->all ];
    }

    # map it to namespaces
    if( ref $self->ns_data->{contents} ) { # from constructor?
        @items = map {
            my $ns = $_;
            $ns = try {
                my $n = Baseliner->model('Namespaces')->get( $ns->{ns} );
                die unless ref $n;
                return $n;
            } catch {  # invalid namespace
                Baseliner::Core::Namespace->new(
                    ns      => $ns->{ns},
                    ns_name => $ns->{item},
                    ns_type => $ns->{provider}, valid=>0  );
            };
            $ns
        } _array( $self->ns_data->{contents} );
    } 
    return @items;
}

sub bl {
    my $self = shift;
    my $rel = $self->row;
    return ref $rel ? $rel->bl : $self->bl_from_contents || '*';
}

sub bl_from_contents {
    my $self = shift;
    my @contents = $self->contents;
    return $self->bl unless @contents;	
    my $bl = '*';
    my @bl;
    for my $item ( @contents ) {
        next unless ref $item;
        next if $item->isa( 'Baseliner::Core::Namespace' );
        push @bl, $item->bl;
    }
    @bl = _unique @bl;
    return @bl==1 ? $bl[0] : '*';
}

sub locked {
    my $self = shift;
    if( $self->bl eq 'PROD' ) {
        $self->locked_reason( 'Release in production' );
        return 1;
    } else {
        return 0;
    }
}

sub created_on {
    my $self = shift;
    return $self->ns_data->{ts};
}

sub created_by {
    my $self = shift;
    my $rel = $self->find;
    return ref $rel ? $rel->username : '';
}

sub checkout { }

sub transition {
    my $self = shift;
    my $p = _parameters( @_);
    #TODO transition content
}

sub promote {
    my $self = shift;
    $self->transition( 'promote', @_ );
}

sub demote {
    my $self = shift;
    $self->transition( 'demote', @_ );
}

sub nature {
    my $self = shift;
    #TODO package natures
    #return map { 'nature/' . uc } grep { length > 0 } @folders;
}

sub state {
    #TODO what is this for? it's in 2 roles at least
}

sub path {
    my $self = shift;
}

sub parents {
    my $self = shift;
    return $self->application;
}

sub application {
    my $self = shift;
    return () unless ref $self->ns_data;
    return ( $self->ns_data->{ns} );
}

sub rfc {
    my $self = shift;
    my @p = split /\./, $self->ns_name;
    return $p[2];	
}

sub text {
    my $self = shift;
    my @p = split /\./, $self->ns_name;
    return $p[3];	
}

sub active {
    my ($self,$active) = @_;
    my $id = $self->ns_data->{id};
    return unless $id;
    my $row = Baseliner->model('Baseliner::BaliRelease')->find( $id );
    return unless ref $row;
    $row->active( $active );
    $row->update;
    return $active;
}

1;

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2010 The Authors of baseliner.org

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

