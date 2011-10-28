package BaselinerX::Controller::Form::RsProjects;
use strict;
use warnings;
use Baseliner::Plug;
use Baseliner::Utils;
use 5.010;
use Try::Tiny;
use BaselinerX::BdeUtils; 
BEGIN { extends 'Catalyst::Controller' }


sub rs_projects : Local {
  my ( $self, $c ) = @_;

  my $p        = $c->request->parameters;
  my $username = $c->username;
  my $user     = $p->{user};
  my $fid      = $p->{fid};
  $fid = 328;
  my $accion = $p->{accion};
  my $ruta   = $p->{fullname};
  my $cam;

  if ($accion) {
    try {
      $cam = $p->{cam};
      my $item     = $p->{item};
      my $fullname = $p->{fullname};
      my %args = ( cam      => $cam,
                   item     => $item,
                   fullname => $fullname );

      if ( $accion eq 'A' ) {
        $c->model('Form')->rs_delete_bde_paquete( \%args );
        $c->model('Form')->rs_insert_bde_paquete( \%args ) }
      elsif ( $accion eq 'D' ) {
        $c->model('Form')->rs_delete_bde_paquete( \%args ) } }
    catch {
      print
       "Se ha producido un error al actualizar los recursos de MS Reporting Services.\n" } }

  my $siguiente = 0;

  my @entornos = ();

  if ( !$cam ) {
    try {
      @entornos = $c->model('Form')->rs_get_entornos($fid);

      for my $ref (@entornos) {
        $cam = $ref->{env} } }
    catch {
      print
       "Se ha producido una SQLException al buscar el paquete de cambio. Asegúrese de "
       . "que tiene correctamente seleccionado el directorio de formularios." } }

  my @elementos = $c->model('Form')->rs_get_elementos($cam) if $cam;
  my @envs      = $c->model('Form')->rs_get_envs($cam)      if $cam;

  $c->stash->{cam}       = $cam;
  $c->stash->{fid}       = $fid;
  $c->stash->{elementos} = \@elementos;
  $c->stash->{envs}      = \@envs;
  $c->stash->{ruta}      = $ruta;
  $c->stash->{template}  = '/form/rs_projects.html';
  $c->forward('View::Mason');

  return }


1;
