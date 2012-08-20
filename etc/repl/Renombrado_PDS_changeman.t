my $config = Baseliner->model('ConfigStore')->get( 'config.changeman.connection' );
my $jobConfig = Baseliner->model('ConfigStore')->get( 'config.job' );
my $bx = BaselinerX::Comm::Balix->new(os=>"mvs", host=>$config->{host}, port=>$config->{port}, key=>$config->{key});
my ($RC, $RET) = (undef,undef);
($RC, $RET)=$bx->execute(qq{tsocmd "LISTCAT LEVEL('CHM.PSCM.P')" | /bin/grep NONVSAM | /bin/cut -d' ' -f3});
foreach my $pds (split /\n/,$RET) {
next if $pds =~m{LISTCAT};
my $pdsProcessed=$pds;
$pdsProcessed=~s{\.P\.}{\.T\.}g;
_log "Procesando $pds";
# _log "borrar $pds" if $pds !~ m{F111010|A00000};
# _log "se queda $pds" if $pds =~ m{F111010|A00000};
# ($RC, $RET)=$bx->execute(qq{tsocmd "RENAME $pds $pdsProcessed"}) if $pds !~ m{F111010|A00000};
}

__END__
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SCTT.N000090.A00000.A00794.FORM
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SCTT.N000118.A00000.A00112.PREP
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SCTT.N000127.F111010.H162316.PREP
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SCTT.N000127.F111010.H162511.ALFA
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SCTT.N000127.F111010.H162511.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SEDT.N000014.F111010.H162503.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.SEDT.N000015.F111010.H163619.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000533.F111010.H131303.ALFA
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000533.F111010.H131303.CINF
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000533.F111010.H131303.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000533.F111010.H131303.PRUE
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000534.F111010.H154928.CINF
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000534.F111010.H154928.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000534.F111010.H154928.PRUE
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000535.F111010.H162956.ALFA
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000535.F111010.H162956.CINF
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000535.F111010.H162956.EXPL
2011-10-11 09:33:07[6770870] [B::Controller::REPL:12] se queda CHM.PSCM.P.XXXT.N000535.F111010.H162956.PRUE

--- ''

