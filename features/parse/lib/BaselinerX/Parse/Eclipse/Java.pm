package BaselinerX::Parse::Eclipse::Java;
use strict;
use warnings;
use 5.010;
# use base 'Baseliner::Parse::Eclipse';
use Baseliner::Utils;

use XML::Smart;
use Carp;
use YAML::Tiny;
use Try::Tiny;
use vars qw($VERSION @EXPORT @EXPORT_OK);

## inheritance
$VERSION = '1.0';

sub getProjects {
	my $self = shift();
	my %RET;
	@RET{ keys %{$self->{root}} } = ();
	return keys %RET;
}

sub output {
	my $self = shift();
	return @{ $self->{output} } if ref $self->{output};
}

sub parse {
	my $self=shift;
	if( ! ref $self ) {
		my $class = $self;
		$self=$class->new( @_ );
		$self = bless ($self, 'Baseliner::Parse::Eclipse::Java'); 
		$self->parse();
		return $self;
	}
	my $w = $self->{root};

	# first pass
	for my $prj ( sort keys %$w ) {
		for my $nat ( ${$w->{$prj}{".project"}{xml}}->{projectDescription}{natures}{nature}('@') ) {
			$w->{$prj}{JAVA}=$nat if( $nat =~ /javanature/);
			$w->{$prj}{WEB}=$nat if( $nat =~ /WebNature/);  ##solo RAD6
			$w->{$prj}{EAR}=$nat if( $nat =~ /\.EAR.*Nature/);  ##solo RAD6
			$w->{$prj}{EJB}=$nat if( $nat =~ /\.EJB.*Nature/);  ##solo RAD6?
			$w->{$prj}{EMF}=$nat if( $nat =~ /\.JavaEMFNature/);  ## RAD6 y 7
			##TODO: EJBClient? no specific nature
			##TODO: here's a  good place to throw away projects that arent javanature (perl, sql, etc.)
		}
		if( exists $w->{$prj}{".classpath"}->{xml} ) {  
			## classpath list
			for( ${$w->{$prj}{".classpath"}{xml}}->{classpath}{classpathentry}('kind','eq','lib') ) {
				push @{ $w->{$prj}{classpath}{lib} }, ( $_->{path} =~ m{^/(.*)} 
							? $1 
							: $prj."/".$_->{path} );     
			}
			# srcs 
			for (  ${$w->{$prj}{".classpath"}{xml}}->{classpath}{classpathentry}('kind','eq','src') ) {  
				next if( exists $_->{exported} );  ## RAD6 externals
				next if( exists $_->{combineaccessrules} ); ## RAD7 external projects; processed later
				push @{ $w->{$prj}{SRC} }, $_->{path};
			}
			# output
			for (  ${$w->{$prj}{".classpath"}{xml}}->{classpath}{classpathentry}('kind','eq','output') ) {  
				push @{ $w->{$prj}{OUTPUT} }, $_->{path};
			}
			## also tells me if I'm a WEB project
			for( ${ $w->{$prj}{".classpath"}{xml} }->{classpath}{classpathentry}('kind','eq','con') ) {
				if( $_->{path} eq 'org.eclipse.jst.j2ee.internal.web.container' ) {
					$w->{$prj}{WEB}='org.eclipse.jst.j2ee.internal.web.container';
					last;
				}
			}				
		}
		$w->{$prj}{JAR}=1; ## es un proyecto JAR
	}
	# second pass
	for my $prj ( sort keys %$w ) {
			next unless exists $w->{$prj}{".classpath"}->{xml};
			# external projects to compile
			for my $entry (  ${$w->{$prj}{".classpath"}{xml}}->{classpath}{classpathentry}('kind','eq','src') ) {  
				if( ( exists( $entry->{combineaccessrules} ) || $entry->{exported} eq 'true' ) &&  $entry->{path} ) {  ## RAD6 & 7 external projects
					my $extprj = substr($entry->{path},1);
					if( $extprj ) {
						push @{ $w->{$prj}{classpath}{import_jar} }, $extprj;  ## to be packed into the final jar
						my @mapped = _unique map {$extprj."/".$_} @{ $w->{$extprj}{OUTPUT}};
						push @{ $w->{$prj}{classpath}{lib} }, @mapped;
					}
				}
			}
	}
	for my $prj ( sort keys %$w ) {
		## RAD7: facet discovery
		if( exists $w->{$prj}{"org.eclipse.wst.common.project.facet.core.xml"}{xml} ) {
			for ( ${$w->{$prj}{"org.eclipse.wst.common.project.facet.core.xml"}{xml}}->{"faceted-project"}{"fixed"}('@') ) {
				my $facet = $_->{"facet"};
				$w->{$prj}{facet}=$facet if ($facet);
				$w->{$prj}{EAR}=$facet if ($facet && $facet =~ m/\.ear/i);
				$w->{$prj}{WEB}=$facet if ($facet && $facet =~ m/\.web/i);
				$w->{$prj}{UTILITY}=$facet if ($facet && $facet =~ m/\.utility/i);
				$w->{$prj}{EJB}=$facet if ($facet && $facet =~ m/\.ejb/i);
				$w->{$prj}{JAR}=$facet if ($facet && $facet =~ m/\.java/i);
			}
		}
		delete $w->{$prj}{JAR} if exists $w->{$prj}{WEB};  ## web prjs are JAR, but do not generate JARs
	}
}

sub is_j2ee {
	my( $self,$prj ) =@_;
	return grep /EJB|WEB|EAR/, keys %{ $self->{root}{$prj} };
}
sub is_server {
	my( $self,$prj ) =@_;
	return ${ $self->{root}{$prj}{".project"}{xml} }->{projectDescription}{natures}{nature} =~ /server/;
}
# This one for applications containing _TEST. We don't want its libs.
sub is_test {
	my( $self,$prj ) =@_;
	return grep /_TEST/, keys %{ $self->{root}{$prj} };
}

sub getJavacXML {
	my $self=shift;
	my %W=%{$self->{root}};
	my %P = %{ shift() };
	
	my $group = ( $P{group} or 'common');

	## only unique projects
	for my $prj ( $self->orderWorkspace( _unique( @_ ) ) ) {
		next if $self->is_j2ee( $prj );
		next if $self->is_server( $prj );
		next if $self->is_test( $prj );

		if ( ! ref $W{$prj}{OUTPUT} ) {
			confess _loc( qq{Error while trying to define the compile strategy for project %1:\nMissing .classpath 'output' entry, such as:\n\t<classpathentry kind="output" path="WebContent/WEB-INF/classes"/>\n}, $prj);
		}
		my ($outputhome) = @{ $W{$prj}{OUTPUT} } or next;
		$self->{build}{target}{build}{$group}.= qq{
				$P{divide}
				<echo>Compiling $prj</echo>
		};
		$self->{build}{target}{build}{$group}.= qq{
			<mkdir dir="$prj/$_"/>  
		} foreach ( @{$W{$prj}{SRC}});

		$self->{build}{target}{build}{$group}.= qq{
			<mkdir dir="$prj/$outputhome"/> 
			<javac destdir="$prj/$outputhome" $P{javac_opts} >
				<classpath refid="classpath_$group"/>
		};

		$self->{build}{classpathlibs}{"$prj/$outputhome"}=();

		## .classpath libs
		if( ref $W{$prj}{classpath}{lib} ) {   
			foreach ( @{ $W{$prj}{classpath}{lib} } ) {				
				$self->{build}{classpathlibs}{$group}{$_}=();
			}
		}
		## MANIFEST.MF Class-Path libs
		if( ref $W{$prj}{classpath}{manifestlib} && $P{prj} ) {   
			foreach ( @{ $W{$prj}{classpath}{manifestlib} } ) {				
				$self->{build}{classpathlibs}{$group}{"$P{prj}/$_"}=();
			}
		}

		$self->{build}{target}{build}{$group} .= qq{
				<src path="$prj/$_" />
		} foreach ( @{$W{$prj}{SRC}});

		$self->{build}{target}{build}{$group} .= qq{
			</javac>
		};
		## also take property files, etc
		$self->{build}{target}{build}{$group}.= qq{
			<copy todir="$prj/$outputhome">
		};
		$self->{build}{target}{build}{$group}.= qq{
				<fileset dir="$prj/$_">
					<exclude name="**/*.java"/>
				</fileset>
		} foreach(@{$W{$prj}{SRC}}) ;
		$self->{build}{target}{build}{$group}.= qq{
			</copy>	
		};
		## clean		
		$self->{build}{target}{clean}{$group} .= qq{	
			<delete $P{delete_opts} >
				<fileset dir="$prj/$outputhome" includes="**/*.class" />
			</delete>
		} if( $P{cleanall} );
	}
	
}

=head2 getClasspathXML

Creates the classpath portion of the final file

=cut
sub getClasspathXML {  
	my $self = shift();	
	my $group = shift();
	my $classpath = shift();

	##OPEN
	$self->{build}{classpath}{$group}.=qq{ <path id="classpath_$group"> };

	if ( $classpath ) {
		for( split /\n|\;/, $classpath ) {
			s/\n|\r|\;//g;
			if( /\.jar$/i ) {
				$self->{build}{classpathlibs}{$group}{$_}=();
			}
			else {
				$self->{build}{classpath}{$group} .= qq{
					<fileset dir="$_">
						<include name="**/*.jar"/>
					</fileset>
				};
			}
		}
	}
	## CLASSPATH - finishup with unique entries
	$self->{build}{classpath}{$group} .= qq{
			<fileset dir="$_">
				<include name="**/*.jar"/>
			</fileset>
	} foreach sort keys %{  $self->{build}{classpathfileset}{$group} };
	$self->{build}{classpath}{$group}.= qq{
		 <pathelement location="$_" />
	} foreach sort keys %{  $self->{build}{classpathlibs}{$group} };
	##CLOSE
	$self->{build}{classpath}{$group}.=qq{ </path> };

}

=head2 getJarXML

Returns the XML snippet for packaging JARs

=cut
sub getJarXML {
	my $self=shift;
	my %W=%{$self->{root}};
	my %P = %{ shift() };
	(my $path = ( $P{path} or "." )) =~ s{//}{/}g;  ## where to leave my jar files

	my $group = ( $P{group} or 'common');
	
	for my $jarprj ( @_ ) {
		next if ! exists $W{$jarprj}{JAR};
		if( ! ref $W{$jarprj}{OUTPUT} ) {
			confess _loc( qq{Error while trying to define the compile strategy for project %1:\nMissing .classpath 'output' entry, such as:\n\t<classpathentry kind="output" path="WebContent/WEB-INF/classes"/>\n}, $jarprj);		
		}
		my ($outputhome) = @{ $W{$jarprj}{OUTPUT} } or next;
		my $jarfile= ( exists $W{$jarprj}{EJB} 
				? ( exists $W{$jarprj}{weburi} 
					? $W{$jarprj}{weburi}
					: "$jarprj.jar" )
				: ( exists $W{$jarprj}{uri}
					? $W{$jarprj}{uri}
					: "$jarprj.jar" )
				);
		$self->{build}{clean}{$group} .= qq{	
			<delete file="$path/$jarfile" $P{delete_opts} />
		};

		# bring external jars into this projects lib
		my @utilities;
		for my $jar_import ( @{ $W{$jarprj}{classpath}{import_jar} || [] } ) {
			$jar_import =~ s/\/$//g;
			my $jarfile = lc "$jar_import.jar";
			my $jar_import_output = @{ $W{$jar_import}{OUTPUT} || [] }[0];

			$self->{build}{target}{package}{$group}.= qq{
				<echo>Imported Java Utility Project $jar_import</echo>
			} if $P{doc};

			my $mf_relpath = $W{$jar_import}{"MANIFEST.MF"}{relpath};
			my $manifest = ! $mf_relpath ? "" : qq{ manifest="$mf_relpath" };

			my $destfile = "$path/$jarprj/lib/$jarfile"; 
			my $destfile_rel = "lib/$jarfile"; 
			push @utilities, $destfile_rel;

			$self->{build}{target}{package}{$group}.=qq{
				<jar destfile="$destfile">
					<fileset dir="$jar_import/$jar_import_output" >
						$P{jar_include}

						$P{exclude}
						$P{jar_exclude}

						<exclude name=".*" />
						<exclude name="**/*.java" />
					</fileset>
				</jar>
			};
		}  #"

		my $prjtype = ( exists $W{$jarprj}{EJB} ? "EJB" : "Java Utility" );
		$self->{build}{target}{package}{$group}.= qq{
			<echo>$prjtype Project $jarprj</echo>
		} if $P{doc};
		
		my $mf_relpath = $W{$jarprj}{"MANIFEST.MF"}{relpath};
		my $manifest = ! $mf_relpath ? "" : qq{ manifest="$mf_relpath" };

		my $utilities_include = join "\n", map {
			qq{
				<fileset dir="$jarprj" >
					<include name="$_" />
				</fileset>
			}
		} @utilities;

		my $exclude = join"\n", map { qq{ <exclude name="$_/" /> } } @{$W{$jarprj}{SRC}};
		$self->{build}{target}{package}{$group}.=qq{
			<delete file="$path/$jarfile" />
			<jar destfile="$path/$jarfile" $manifest >
				<fileset dir="$jarprj/$outputhome" >
					$P{jar_include}

					$P{exclude}
					$P{jar_exclude}

					<exclude name="**/.*" />
					<exclude name="**/*.java" />
				</fileset>
				<fileset dir="$jarprj" >
					<exclude name="$outputhome/" />
					$exclude
					$P{jar_include}

					$P{exclude}
					$P{jar_exclude}

					<exclude name="**/.*" />
					<exclude name="**/*.java" />
				</fileset>
				$utilities_include
			</jar>
		}; 
		#"
		push @{  $self->{output} }, { file=>"$path/$jarfile", class=>$jarprj, ext=>'JAR' };
	}
}


sub orderWorkspace {  
	my $self = shift();
	my $w = $self->{root};
	return sort { return $a=~/BATCH$/i ? 1 : -1 } keys %$w;
}

sub buildxml {
	my $self = shift;
	my $tpl = join '',<DATA>;
	return $tpl
}

sub getBuildXML { 
	my $self = shift();
	my %W=%{$self->{root}};
	my %P = @_;

	## PREP
	delete $self->{output};
	delete $self->{build};
	delete $self->{build}{classpath};
	delete $self->{build}{classpathfileset};
	delete $self->{build}{classpathlibs};
	delete $self->{build}{target};

	$P{divide}=qq{<echo>}.('*' x 60).qq{</echo>\n} if ! exists $P{divide};
	$P{doc}=1 if ! exists $P{doc};
	$P{cleanall}=1 if ! exists $P{cleanall};
	$P{defaulttask}='all' if ! exists $P{defaulttask}; ## default task on <project> tag
	$P{static_file_type}||='zip';  ## could be 'tar' also
	
	## ear, jar, war excludes, includes
	$P{exclude}= '' if ! exists $P{exclude};
	$P{jar_exclude}= '' if ! exists $P{jar_exclude};
	$P{jar_include}= '' if ! exists $P{jar_include};
	$P{static_exclude}='';
	$P{static_include}='';
	
	my @PROJECTS = ();

	$P{projects} and $self->opt('error_not_found') and ! $self->isa_project( @{$P{projects}} ) and croak "Project not found $@";
	$P{projects} and @PROJECTS=$self->valid( @{$P{projects}} );

	$P{javac_opts} = "" if !exists $P{javac_opts};
	$P{delete_opts} = 'failonerror="false"' if ! exists $P{delete_opts};
	
	## User provided Classpath
	my $opt_classpath = ( ref $P{classpath} eq 'ARRAY' 
					? join ';', @{$P{classpath}} 
					: $P{classpath} );
	
	$P{group} = "common";
	## JAVAC
	#$self->getJavacXML( { %P }, @PROJECTS, $self->getChildren(@PROJECTS) );
	$self->getJavacXML( \%P, @PROJECTS );

	## JAR MODULES
	$self->getJarXML( { %P },  @PROJECTS );

	## CLASSPATH
	$self->getClasspathXML( $P{group}, $opt_classpath );	

	###############################################
	## BUILD.XML layout
	my $RET.=qq{
		<?xml version="1.0" encoding="utf-8"?>
		<project name="SCM" default="$P{defaulttask}" basedir=".">
	};
	## CLASSPATH"
	$RET.=qq{
			$self->{build}{classpath}{$_}
	} foreach keys %{ $self->{build}{classpath} };
	## TARGETS
	my %ALL;
	my %ALLGROUPS;
	foreach my $target ( 'clean','build','package' ) {       ## could be also sort keys %{ $self->{build}{target} } 
		foreach my $group ( sort keys %{ $self->{build}{target}{$target} }  ) {
			$ALLGROUPS{$group}=();
			my $targetname = "${target}_${group}";
			$ALL{$target}{$targetname}=();
			$RET.=qq{
				<target name="$targetname">
						$self->{build}{target}{$target}{$group}
				</target>
			};
		}
	}
	## CLOSURE"
	my $allclean = join(',',sort keys(%{$ALL{clean}}));
	my $allbuild = join(',',keys(%{$ALL{build}}));
	my $allpackage = join(',',keys(%{$ALL{package}}));
	my $callclean="";  $callclean.=qq{<antcall target="$_" />} foreach sort keys(%{$ALL{clean}});
	my $callbuild="";  $callbuild.=qq{<antcall target="$_" />} foreach sort keys(%{$ALL{build}});
	my $callpackage="";  $callpackage.=qq{<antcall target="$_" />} foreach sort keys(%{$ALL{package}});
	my $callgroups="";
	foreach my $group ( sort keys %ALLGROUPS ) {
		$callgroups.=qq{<antcall target="${_}_$group" />} foreach ( 'clean','build','package');
	}
	$RET.=qq{
			<target name="clean">
				<echo>Running all cleanup targets: $allclean</echo>
				$callclean
			</target>
			<target name="build">
				<echo>Running all build targets: $allbuild</echo>
				$callbuild
			</target>
			<target name="package">
				<echo>Running all package targets: $allpackage</echo>
				$callpackage
			</target>
			<target name="all">
				<echo>Running all targets by group</echo>
				$callgroups
			</target>
			
		</project>
	};

	## TIDY UP XML
	$RET=~ s{\n\n*}{\n}sg;
	$RET=~ s{\n\t*\n}{\n}sg;
	$RET=~ s{//}{/}sg;
	$RET=~ s{^\n\n*}{}s;
	$RET=~ s{^\t*}{}s;
	## this is the real tidying!
	my $buildXML=();
	try {
		$buildXML = XML::Smart->new( $RET ) ;
		$self->{build}{xml}=$buildXML if( $buildXML );
		return $buildXML;
	} catch {
		my $err = shift;
		my $filename = "xml_error_$$.xml";
		open FF, ">", $filename;
		print FF $RET;
		close FF;
		$self->{build}{xmlerror} = $RET;
		confess _loc("Error while parsing generated build.xml (please, check file %1 to see the invalid file):%2", $filename, $err );  
	};
}

1;
__DATA__
<project name="MyProject" default="build" basedir=".">
	<description>
		Fichero ANT para la compilación de aplicaciones Batch
	</description>
</project>
