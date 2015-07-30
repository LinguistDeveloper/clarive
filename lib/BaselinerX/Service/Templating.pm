package BaselinerX::Service::Templating;
use Moose;
use Baseliner::Core::Registry ':dsl';
use Baseliner::Utils;
use Try::Tiny;

with 'Baseliner::Role::Service';

our $ICON_DEFAULT = '/static/images/icons/write.gif';

register 'service.templating.transform' => {
    name => 'Transform Template',
    form => '/forms/template_transform.js',
    icon => $ICON_DEFAULT,
    job_service  => 1,
    handler => \&template_transform,
};

sub template_transform {
    my ($self, $c, $config ) = @_;

    my $stash = $c->stash;
    my $job   = $stash->{job};
    my $log   = $job->logger;
    
    my $input_file    = $config->{input_file} // _fail _loc 'Missing input files';
    my $output_file   = $config->{output_file};
    my $encoding      = $config->{encoding};
    my $engine        = $config->{engine} // 'tt';
    my $template_var  = $config->{template_var} // '';
    
    _fail _loc 'Could not find file: %1', $input_file unless -e $input_file;
    
    my $output;

    if( $engine eq 'tt' ) {
        my $body = _file( $input_file )->slurp;
        $output = $self->process_tt( $stash, $template_var, $body ); 
    }
    elsif( $engine eq 'mason' ) {
        my $comp_dir = _file( $input_file )->dir->relative( $job->job_dir );
        my $is_relative = $comp_dir !~ /^\.\./;   # not in job_dir, then use absolute
        my $root_dir;
        if( $is_relative ) {
            $root_dir = $job->job_dir;     
        } else {
            $root_dir = '/';
            $comp_dir = _file( $input_file )->dir;
        }
        _debug _loc 'Mason convert from `%1`, dir `%2`', $input_file, $root_dir;
        $output = Util->_mason( $input_file, comp_root=>$root_dir, %{ $template_var ? $stash->{template_var} : $stash });
    }
    else {
        _fail _loc 'Invalid templating engine type: %1', $engine;
    }
   
    if( $output_file ) {
        my $format = $encoding ? sprintf(':encoding(%s)', $encoding) : ':raw';
        open my $fout, '>'.$format, $output_file
            or _fail _loc 'Could not write to templating output file %1', $output_file;
        print $fout $output;
        close $fout;
        _debug _loc 'Wrote template file %1', $output_file;
    }

    return $output;
}

sub process_tt {
    my ($self,$stash,$template_var,$body)=@_;
    require Template; # aka TT
    my $tt = Template->new();
    my $vars = $template_var ? $stash->{ $template_var } : $stash;
    my $output = '';
    if( ! $tt->process( \$body, $vars, \$output ) ) {
        _fail _loc "Error processing file body with templating %1: %2", 'tt', $tt->error;
    }
    return $output;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;
