use inc::Module::Install;
name 'Baseliner';
all_from 'lib/Baseliner.pm';
license 'GPLv3';

requires 'Catalyst::Runtime' => '5.90015';
requires 'Catalyst::Plugin::ConfigLoader';
requires 'Catalyst::Plugin::Static::Simple';
requires 'Catalyst::Action::RenderView';
requires 'Plack';
requires 'Starman';
requires 'Moose';

WriteAll;
