package BaselinerX::CA::Harvest::Controller::Form;
use Baseliner::Plug;
use Baseliner::Utils;
use Try::Tiny;

=head1 NAME

BaselinerX::CA::Harvest::Controller::Form - Generates a Harvest r12 Form from parsing its xml.

=cut

# http://localhost:3000/scm/servlet/harweb.Form?CMD=GetInfo&ID=37&PACKAGE_ID=39&PROJECT_ID=50&PACKAGE_NAME=GBP.328.N-000009%20prueba

BEGIN { extends 'Catalyst::Controller' };

register 'config.harvest.form' => {
	metadata => [
		{  id=>'width' },
	]
};

=head1 METHODS

=head2 form_data

Given a formobjid => first row hash

=cut

sub begin : Private {
	my ($self,$c) = @_;
	$c->stash->{auth_skip} = 1;
	$c->forward('/begin');
}

sub form_data : Private {
	my ($self,$c, $fid )=@_;
	my $form = $c->model('Harvest::Harform')->search({ formobjid => $fid })->first;
	my $table = $form->formtypeobjid->formtablename;
	# get current data
	$table =~ s/(_|^)(.)/\U$2/g;
	my $row = $c->model( 'Harvest::' . $table )->search({ formobjid=>$fid })->first;
	return $row->get_columns;
}

use XML::Smart;
sub parse_form_xml : Private {
	my ($self,$c)=@_;
	my $xml;
	my $id = $c->req->params->{ID} || $c->stash->{formobjid};
	my $cache_id = 'Harform-' . $id;
    try {
        my $xml_cache = $c->cache->get($cache_id) or die;
        $xml = new XML::Smart( $xml_cache );
    } catch {
		my $rs = $c->model( 'Harvest::Harform' )->search({ formobjid=> $id });
		_throw _loc("Formobjid %1 not found", $id) unless ref $rs->first;
		my $ft = $rs->first->formtypeobjid->formtypename;
		my $file = $c->path_to( 'root', 'harform', $ft . ".xml" )	;
        die _loc('Missing Harvest Form XML file %1', $file ) unless -e $file;
		$xml = new XML::Smart( $file ) or die $!;
		#$c->cache->set($cache_id, $xml->data);
	};
	return $xml;
}


=head2 xml_to_grid_columns

	# metadata
	$c->stash->{formobjid} = $fid;
	my ($fields, $cols ) = $c->forward( 'BaselinerX::CA::HarvestForm', 'xml_to_grid_columns' );
	# columns
    $c->stash->{columns} = js_dumper $cols;
	# fields 
    $c->stash->{fields} = js_dumper $fields;

=cut
sub xml_to_grid_columns : Private {
	my ($self,$c)=@_;
	my $xml = $c->forward( 'parse_form_xml' );
	my @meta;
	my @fields;
	my %kkey;
	for my $key ( $xml->{harvest_form}->order ) {
		my $f = $xml->{harvest_form}->{$key}[ $kkey{$key}++ ];
		next if "$f->{dbfield}" eq 'formname';
		next unless "$f->{label}" ;
		push @fields, {
			name => "$f->{dbfield}"
		};
		push @meta, 
          {
            header    => "$f->{label}",
            width     => ( $f->{width} || 80 ),
            dataIndex => "$f->{dbfield}",
            sortable  => ( "$f->{sortable}" || \1 ),
            hidden    => ( "$f->{hidden}" || \0 )
          };
	}
	return (\@fields, \@meta) ;
}

sub xml_to_extjs : Private {
	my ($self,$c)=@_;
	my $xml = $c->forward( 'parse_form_xml' ) or _throw 'Harvest form xml error';
	my @meta;
	my %ext_map = (  combobox=>'combo', 'date-field'=>'datefield', 'text-area'=>'textarea', 'text-field'=>'textfield' );
	my %kkey;
	# get current data
	( my $table = $xml->{harvest_form}->{dbtable} .'' )=~ s/(_|^)(.)/\U$2/g;
	my $formobjid = $c->req->params->{ID};
	my $row = $c->model( 'Harvest::' . $table )->search({ formobjid=>$formobjid })->first;
	ref $row or Catalyst::Exception->throw( _loc 'Could not find formobjid %1 in table %2', $formobjid, $table );
	# prepare form
	my $form = {};
	$form->{url} = '/scm/form_submit';
	$form->{frame} = \0;
	$form->{method} = 'post';
	push @meta, { xtype=>'hidden', name=>'formobjid', value=>$formobjid };
	for my $key (  $xml->{harvest_form}->order  ) {
		if( grep( /$key/, qw/combobox text-field date-field text-area/ ) ) {
			my $f = $xml->{harvest_form}->{$key}[ $kkey{$key}++ ];
			my $field = "$f->{dbfield}";
			next if $field eq 'formname';
			my $item = { };
			$item->{xtype} = $ext_map{$key};
			$item->{id} = "$f->{dbfield}";
			$item->{name} = "$f->{dbfield}";
			$item->{height} = 150 if $item->{xtype} eq 'textarea';
			$item->{fieldLabel} = "$f->{label}";
			$item->{size} = "$f->{maxsize}" if( $key =~ /text-field/ );
			$item->{anchor} = "80%" if(  $key =~ /text-area/ );
			# assign current date to field
			if(  $key =~ /date-field/ ) {
				my $val = $row->get_column($field); ## avoid column deflation
                $val and $item->{value} = parse_date('dd/mm/yy', $val)->dmy('/');  ## dd/mm/yy => dd/mm/yyyy
				$item->{format} = 'd/m/Y';  ## tell extjs what format to use
			} else {
				$item->{value} = $row->$field();
			}
			# Combo Stuff
			if(  $key =~ /combobox/ ) {
				my $k = 0;
				my @entry;
				for(  $f->{entry}->('@') ) {
					push @entry, [ "id" . $k++ , "$_" ];
				}
				$item->{store} = \(  "new Ext.data.SimpleStore( " . js_dumper( { fields=>["id","text"], data=> [ @entry ] }) . ")" );
				$item->{displayField} = 'text';
				$item->{editable} = \0;
				$item->{forceSelection} = \1;
				$item->{triggerAction} = 'all';
				$item->{mode} = 'local';
			}
			push @meta, $item; 
		} elsif( lc($key) eq 'baseliner-tab' ) {
			foreach my $tab ( _array $xml->{harvest_form}->{$key} ) {
				# not a field, but a new Baseliner tab component
				push @{ $c->stash->{form_tabs} }, { 
					type  => $tab->{type},
					title => $tab->{title},
					url   => $tab->{url},
				};
			}
		} else {
			my $value = $xml->{harvest_form}->{$key} . "";
			push @meta, { xtype=>'hidden', name=>$key, value=>$value  };
		}
	}
	$form->{items} = \@meta;
	#my $extform = js_dumper( $form ); 
	$c->stash->{form} = js_dumper( $form );
	return;
}

use MIME::Base64;
use JavaScript::Dumper;
sub form_meta : Path('/scm/servlet/harweb.Form') {
	my ($self,$c)=@_;
    my $p = $c->req->params;
    my $user;

	#TODO check for referer 'harvest'
	my $username = decode_base64($p->{USER_NAME});
	$c->stash->{username} = $username;
    $c->forward('/auth/login_from_url');

    if( defined $c->user ) {
        $c->forward( 'xml_to_extjs' );
        $c->stash->{title} = $c->req->params->{PACKAGE_NAME} || 'Harvest Form';
        $c->stash->{template} = '/site/formpage.html';
    } else {
        $c->forward('/auth/error', );
    }
	#$c->res->body( '<pre>' . $c->stash->{form} );
}


use DateTime::Format::DateParse;

sub form_submit : Path( '/scm/form_submit' ) {
	my ($self,$c)=@_;
	#my $table = $c->req->params->{db_table};
	#my $formobjid = $c->req->params->{formobjid};
 	#my $form = $c->model( 'Harvest::FormGbp' )->search({ formobjid=>$formobjid })->first;
	#warn Dump $form->formobjid;

	my $p = $c->req->params;
	(  my $table = $p->{dbtable} )=~ s/(_|^)(.)/\U$2/g;
	my $formobjid = $p->{formobjid};
 	my $form = $c->model( 'Harvest::' . $table )->search({ formobjid=>$formobjid })->first;
	delete $p->{$_} for( qw/dbtable formobjid formname id name numtabs/ );
    for(keys %{  $p  }) {
        if( $form->column_info($_)->{data_type} =~ m/date/i ) {
            $p->{$_} = parse_date( 'dd/mm/Y' , $p->{$_} )->ymd; ## y-m-d - to match NLS_DATE
        }
    }
	eval {
		#$c->model( 'Harvest' )->storage->dbh_do( sub { $_[1]->do( "alter session set nls_date_format = 'DD/MM/YYYY' "); });
		$form->update( $p );
	};
	if( $@ ) {
		warn $@;
		$c->res->body( "false" );
	} else {
		$c->res->body( "true" );
	}
}

1;
