package Clarive::Cmd;
use Mouse;

has app => qw(is ro required 1), 
            handles=>[qw/
                lang 
                env 
                home 
                debug 
                verbose 
                args 
                argv
            /];

# command opts have the app opts + especific command opts from config
has opts   => qw(is ro isa HashRef required 1);

1;
