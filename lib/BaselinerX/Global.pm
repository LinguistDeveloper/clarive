package BaselinerX::Global;
use Baseliner::Plug;
use Baseliner::Utils;
BEGIN { extends 'Catalyst::Controller' };

register 'menu.tools' => { label => 'Tools', index=>20 };

register 'config.global' => {
	metadata => [
       { id=>'password_patterns', label=>'List of patterns to be hidden in user outputs', default => '' }
    ]
};

1;


