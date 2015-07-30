package Baseliner::Controller::CISoap;
use Moose;
use Baseliner::Utils;
use Baseliner::Sugar;
use Try::Tiny;
BEGIN { extends 'Catalyst::Controller' }
BEGIN { extends 'Catalyst::Controller::WrapCGI' }

sub ci_soap : Path('/ci-soap') {
    my ($self,$c,$class)=@_;
    
    $class //= 'job';
    my %args = ( 
        class => $class,
        base => sprintf( '%s/', $c->config->{web_url}),
        url  => sprintf( '%s/ci-soap/%s', $c->config->{web_url}, $class ),
    );
    my $wsdl_data = $self->wsdl( %args );
    
    my $f = _file($c->req->body);
    if( -e $f ) {
        _debug( scalar $f->slurp );

        require XML::Compile::SOAP11;
        require XML::Compile::WSDL11;
        require XML::Compile::SOAP::Util;
        require XML::Compile::SOAP::Daemon::CGI;
        
        my $wsdl = XML::Compile::WSDL11->new($wsdl_data);
        my $daemon = XML::Compile::SOAP::Daemon::CGI->new(
            #  preprocess => sub {
            #      my ($req) = @_;
            #      Util->_debug( sprintf "Request\n---\n%s %s %s\n%s\n%s---",
            #          $req->method, $req->request_uri, $req->protocol,
            #          $req->headers->as_string,
            #          $req->content );
            #  },
            #  postprocess => sub {
            #      my ($req, $res) = @_;
            #      Util->_debug( sprintf "Response\n---\n%s %s\n%s\n%s---",
            #          $res->status, HTTP::Status::status_message($res->status),
            #          $res->headers->as_string,
            #          $res->body );
            #  },
        );
        
        
        my %cbs;
        local $Baseliner::CI::_no_record = 1;
        for my $meth ( $self->methods( $class ) ) {
            my $cn = $meth->{cn};
            my $name = $meth->{name};
            my $cb = sub {  
                my ($soap, $data) = @_;
                Util->_debug( $data );
                my $mid = $data->{parameters}->{mid};
                $cn = ci->new( $mid ) if $mid;
                my $json = Util->_from_json( $data->{parameters}->{json} || '{}' );
                my @ret = ($cn->$name(%$json));
                my $ret = @ret == 1 ? $ret[0] : \@ret;
                $ret = Util->_unbless( $ret );
                return +{
                    json => Util->_to_json({ result=>$ret })
                };
            };
            $cbs{ $meth->{name} } = $cb;
        }

        $daemon->operationsFromWSDL(
            $wsdl,
            callbacks => \%cbs,
#            callbacks => {
#                approve => sub {
#                    my ($soap, $data) = @_;
#                    Util->_debug( $soap );
#                    #my $json = Util->_from_json( $data->{parameters}->{json} || '{}' );
#                    return +{
#                        #json => Util->_to_json({ result=>$json->{x} + $json->{y} })
#                        json => '{}'
#                    };
#                },
#                divide => sub {
#                    my ($soap, $data) = @_;
#
#                    my $result = eval {
#                        $data->{parameters}->{numerator} / $data->{parameters}->{denominator};
#                    };
#                    if (my $e = $@) {
#                        mistake $e;
#                        while ($e =~ s/\t\.\.\.propagated at (?!.*\bat\b.*).* line \d+( thread \d+)?\.\n$//s) { }
#                        $e =~ s/( at (?!.*\bat\b.*).* line \d+( thread \d+)?\.?)?\n$//s;
#                        return +{
#                            Fault => {
#                                faultcode => pack_type(XML::Compile::SOAP::Util->SOAP11ENV, 'Client'),
#                                faultstring => $e,
#                                faultactor => $soap->role,
#                            }
#                        };
#                    };
#
#                    return +{
#                        Result => $result,
#                    };
#                },
#            },
        );

        $self->cgi_to_response($c, sub {
            my $query = CGI->new;
            $daemon->runCgiRequest(query => $query);
        }); 
    } else {
        $c->res->body( $wsdl_data );
    }
}

sub wsdl {
    my ($self, %p ) = @_;
    my ($class, $base, $url ) = @{ \%p }{ qw(class base url) }; 
    my ($bind, $port, $service) = ( "${class}Bind", "${class}Port", "${class}Service" );
    my ($elements,$messages,$opers,$opers2) = $self->opers( $class );
    my $wsdl = qq{<?xml version="1.0" encoding="US-ASCII"?>
<wsdl:definitions name="$class" 
    targetNamespace="$url/" 
    xmlns:http="http://schemas.xmlsoap.org/wsdl/http/" 
    xmlns:mime="http://schemas.xmlsoap.org/wsdl/mime/" xmlns:soap="http://schemas.xmlsoap.org/wsdl/soap/" 
    xmlns:soap12="http://schemas.xmlsoap.org/wsdl/soap12/" xmlns:soapenc="http://schemas.xmlsoap.org/soap/encoding/" 
    xmlns:tns="$url/" 
    xmlns:wsdl="http://schemas.xmlsoap.org/wsdl/" 
    xmlns:xsd="http://www.w3.org/2001/XMLSchema">
    <wsdl:types>
        <xsd:schema elementFormDefault="qualified" targetNamespace="$url/">
        
           $elements 

        </xsd:schema>
    </wsdl:types>
    }. 
    $messages
    .qq{
    <wsdl:portType name="$class">
        $opers
    </wsdl:portType>
    
    <wsdl:binding name="$class" type="tns:$class">
        <soap:binding style="document" transport="http://schemas.xmlsoap.org/soap/http" />
        
        $opers2

    </wsdl:binding>
    <wsdl:service name="$class">
        <wsdl:documentation>instance of class BaselinerX::CI::$class</wsdl:documentation>
        <wsdl:port binding="tns:$class" name="$class">
            <soap:address location="$url" />
        </wsdl:port>
    </wsdl:service>
</wsdl:definitions>
};
    return $wsdl;
}

sub opers {
    my ($self,$class) = @_;
    my @methods = $self->methods( $class );
    my $elements = join "\n", map {
        my $meth = $_->{name};
        qq{<xsd:element name="$meth">
                <xsd:complexType>
                    <xsd:sequence>
                        <xsd:element name="mid" type="xsd:int" />
                        <xsd:element name="json" type="xsd:string" />
                    </xsd:sequence>
                </xsd:complexType>
            </xsd:element>
            
            <xsd:element name="${meth}Response">
                <xsd:complexType>
                    <xsd:sequence>
                        <xsd:element name="json" type="xsd:string" />
                    </xsd:sequence>
                </xsd:complexType>
            </xsd:element>
        };
    } @methods; #" 
            
    my $messages = join "\n", map {
        my $meth = $_->{name};
        qq{
            <wsdl:message name="${meth}jsonIn">
                <wsdl:part element="tns:$meth" name="parameters" />
            </wsdl:message>
            <wsdl:message name="${meth}jsonOut">
                <wsdl:part element="tns:${meth}Response" name="parameters" />
            </wsdl:message>
        };
    } @methods; #"

    my $opers = join "\n", map {
        my $meth = $_->{name};
        qq{
            <wsdl:operation name="$meth" parameterOrder="json">
                <wsdl:input message="tns:${meth}jsonIn" name="${meth}jsonIn" />
                <wsdl:output message="tns:${meth}jsonOut" name="${meth}jsonOut" />
            </wsdl:operation>
        };
    } @methods; #"
    
    my $opers2 = join "\n", map {
        my $meth = $_->{name};
        qq{
            <wsdl:operation name="$meth">
                <soap:operation soapAction="$meth" style="document" />
                <wsdl:input name="${meth}jsonIn">
                    <soap:body use="literal" />
                </wsdl:input>
                <wsdl:output name="${meth}jsonOut">
                    <soap:body use="literal" />
                </wsdl:output>
            </wsdl:operation>
        };
    } @methods; #"

    return ( $elements, $messages, $opers, $opers2 );
} 

sub methods {
    my ($self,$class)=@_;
    my $cn = 'BaselinerX::CI::' . $class;
    my @methods = map { +{ name=>$_, cn=>$cn, class=>$class } } 
        grep !/^_/, 
        sort $cn->meta->get_method_list;
}
no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__


<?xml version="1.0" encoding="utf-8"?>
<soap:Envelope xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:xsd="http://www.w3.org/2001/XMLSchema" xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/">
<soap:Body>
<approve xmlns="http://localhost:3000/ci-soap/job"></approve>
</soap:Body></soap:Envelope>



 

