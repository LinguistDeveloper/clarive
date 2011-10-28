package BaselinerX::Ktecho::Inf::Resolver;
use 5.010;
use Moose;
use Baseliner::Utils;
use Baseliner::Core::DBI;
use Compress::Zlib;
use Try::Tiny;
BEGIN { extends 'BaselinerX::Ktecho::Inf::DB' }

has 'infvar'        => (is => 'rw', isa => 'ArrayRef', lazy_build => 1);
has 'infvar_solved' => (is => 'rw', isa => 'ArrayRef', lazy_build => 1);
has 'entorno'       => (is => 'rw', isa => 'Str');
has 'cam'           => (is => 'rw', isa => 'Str');
has 'sub_apl'       => (is => 'rw', isa => 'Str', default => 'smoople');

sub _build_infvar {
  my $self  = shift;
  my @array = $self->db->array_hash("SELECT * FROM infvar");
  \@array;
}

sub _build_infvar_solved {
  my $self = shift;
  my $entorno = $self->entorno;
  my $cam     = $self->cam;
  my $sub_apl = $self->sub_apl;
  my @array   = @{ $self->infvar };

  # Inicializo la variable que substituirá al valor inicial
  my $resultado;

  # Recorro la tabla a modificar
  for my $ref (@array) {

    # Mientras exista $[x] o ${x}
    while ( $ref->{valor} =~ m/([\$\[|\$\{].*?[\]|\}])/x ) {

      # Obtengo la variable para mirar en la 'otra' tabla
      $ref->{valor} =~ m/([\$\[|\$\{].*?[\]|\}])/x;
      my $value = $1;

      # Excepciones:
      $resultado = lc($entorno) if $value eq '${e}';
      $resultado = uc($entorno) if $value eq '${E}';
      $resultado = lc($cam)     if $value eq '${cam}';
      $resultado = uc($cam)     if $value eq '${CAM}';
      $resultado = lc($sub_apl) if $value eq '${subapl}';
      $resultado = uc($sub_apl) if $value eq '${SUBAPL}';

      if ( $entorno =~ m/\[T\|A\|P\]/ix ) {
        $resultado = lc('[T|A|]')  if $value eq '${eaix}';
        $resultado = uc('[T|A|]')  if $value eq '${EAIX}';
        $resultado = lc('[P|A|E]') if $value eq '${emq}';
        $resultado = uc('[P|A|E]') if $value eq '${EMQ}';
      }
      elsif ( $entorno =~ m/T/ix ) {
        $resultado = 't' if $value eq '${eaix}';
        $resultado = 'T' if $value eq '${EAIX}';
        $resultado = 'p' if $value eq '${emq}';
        $resultado = 'P' if $value eq '${EMQ}';
      }
      elsif ( $entorno =~ m/A/ix ) {
        $resultado = 'a' if $value eq '${eaix}';
        $resultado = 'A' if $value eq '${EAIX}';
        $resultado = 'a' if $value eq '${emq}';
        $resultado = 'A' if $value eq '${EMQ}';
      }
      elsif ( $entorno =~ m/P/ix ) {
        $resultado = q// if $value eq '${eaix}';
        $resultado = q// if $value eq '${EAIX}';
        $resultado = 'e' if $value eq '${emq}';
        $resultado = 'E' if $value eq '${EMQ}';
      }
      if ( !$resultado ) {                        # Si no tengo ninguna excepción...
        while ( !$resultado ) {                   # Mientras no tenga resultado...
          for my $ref2 (@array) {                 # Recorro de nuevo la tabla para buscar el valor
            if ( $ref2->{variable} eq $value ) {  # En cuanto encuentre una fila cuyo valor coincida con el que estoy buscando...
              $resultado = $ref2->{valor};        # ... modifico el valor...
            }
          }
        }
      }
      $ref->{valor} =~ s/([\$\[|\$\{].*?[\]|\}])/$resultado/x;  # ... y finalmente substituyo
    }
  }
  # wantarray ? @array : \@array;
  \@array;
}

sub get_solved_value {
  my ($self, $value) = @_;
  my @ls = map { $_->{variable} } @{$self->infvar_solved};
  while ($value =~ m/([\$\[|\$\{].*?[\]|\}])/x) {
    my $valor = $1;
    return q{} unless $valor ~~ @ls;
    for my $ref (@{$self->infvar_solved}) {
      if ($ref->{variable} eq $valor) {
        $value =~ s/([\$\[|\$\{].*?[\]|\}])/$ref->{valor}/;
      }
    }
  }
  $value;
}

1
