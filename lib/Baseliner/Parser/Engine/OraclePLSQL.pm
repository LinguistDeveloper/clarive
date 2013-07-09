package Baseliner::Parser::Engine::OraclePLSQL;
use Baseliner::Moose;

sub parse {
    my ($self,%p) =@_;
    
    my $source = $p{source} // die "Missing parameter source";
    my @lines = split /\r?\n/, $source ;
    
    my $fc, @select_list, @update_list, @insert_list, @delete_list;
    my ( $sc, $uc, $ic, $dc, $tc, $tl ) = ( 0, 0, 0, 0, 0, 0 );

    #Parse the file, remove line feed and store it in variable fc
    while ( @lines ) {
        chomp;
        s/(.*?)(--)(.*)/\1/;      # Strip -- sql comments
        s/((\/\*).+?(\*\/))//;    # Strip /* */ comments
        s/^\s+//;                 # Strip leading spaces
        $fc .= " " . $_;
        $tl++;
    }
    
    #print "\n", "Processing file : $ARGV[0]", "\n";
    print "Total lines : $tl", "\n";
    $_ = $fc;
    s/([\d\D]*)/\U\1/;            #make uppercase
    $fc = $_;

    # SELECT LIST #
    while (1) {
        if (/(\bSELECT\b\s+(.+?)\bFROM\b\s+(.+?)((\bWHERE\b)(.+?);|;))/i)    #regular expression mask for select statement
        {
            if ( $1 =~ /^\bSELECT\b\s.+?\bSELECT\b.*/i
                )    # to skip inline select query as this can be many levels, but this code will fetch from innermost sql
            {
                $_ = substr( $_, 7 );    #skip few characters to continue the loop with the next match;
                next;
            }
            my @temp_select_list = split /,/, $3;    # to get the multiple tables in the right way
            push @select_list, @temp_select_list;
            $sc++;                                   # count for number of select statements
        } else {
            last;                                    # no match, exit loop to continue
        }
        my $ind = index( $_, $1 ) + length($1);      #skip the matched sql to find the next select
        $_ = substr( $_, $ind );
    }

    # ------------ Comments for select would suffice to explain the subsequent codes for update, insert and delete
    # UPDATE LIST #
    $_ = $fc;
    while (1) {
        if (/(\bUPDATE\b\s+(\w+?)\s+\bSET\b\s+.+?;)/i) {
            push @update_list, $2;
            $uc++;
        } else {
            last;
        }
        my $ind = index( $_, $1 ) + length($1);
        $_ = substr( $_, $ind );
    }

    # INSERT LIST #
    $_ = $fc;
    while (1) {
        if (/(\bINSERT\b\s+\bINTO\b\s+(\w+)\s*?(\bVALUES\b.+?;|.+?;))/i) {
            push @insert_list, $2;
            $ic++;
        } else {
            last;
        }
        my $ind = index( $_, $1 ) + length($1);
        $_ = substr( $_, $ind );
    }

    # DELETE LIST #
    $_ = $fc;
    while (1) {
        if (/(\bDELETE\b\s+(\bFROM\b\s+(\w+?)|(\w+?))\s+.+?;)/i) {
            push @delete_list, $3;
            $dc++;
        } else {
            last;
        }
        my $ind = index( $_, $1 ) + length($1);
        $_ = substr( $_, $ind );
    }
    $tc = $sc + $uc + $ic + $dc;

    #Process select lists to strip alias name for the table
    foreach (@select_list) {
        s/(\w+?)\s+(\w+)/\1/;

        #print $_,"\n"; this line was very useful in debugging, I like it.
        s/\s//g;
        push @final_select_list, $_ if $_;
    }

    #Refining the collected information
    @sort_nodup_insert_list       = sort grep { !$isaw1{$_}++ } @insert_list;
    @sort_nodup_update_list       = sort grep { !$isaw2{$_}++ } @update_list;
    @sort_nodup_delete_list       = sort grep { !$isaw3{$_}++ } @delete_list;
    @sort_nodup_final_select_list = sort grep { !$isaw4{$_}++ } @final_select_list;
    @sort_nodup_insert_list       = ("There is no insert operation") if !@sort_nodup_insert_list;
    @sort_nodup_update_list       = ("There is no update operation") if !@sort_nodup_update_list;
    @sort_nodup_delete_list       = ("There is no delete operation") if !@sort_nodup_delete_list;
    @sort_nodup_final_select_list = ("There is no select operation") if !@sort_nodup_final_select_list;

    #if ( $tc gt 0 ) {
    #    print "\n";
    #    print "SELECT is done on the following tables : ($sc) operations \n";
    #    print join ", ", @sort_nodup_final_select_list;
    #    print "\n\n";

    #    print "UPDATE is done on the following tables : ($uc) operations \n";
    #    print join ", ", @sort_nodup_update_list;
    #    print "\n\n";

    #    print "INSERT is done on the following tables : ($ic) operations \n";
    #    print join ", ", @sort_nodup_insert_list;
    #    print "\n\n";
    #    print "DELETE is done on the following tables : ($dc) operations \n";
    #    print join ", ", @sort_nodup_delete_list;
    #    print "\n\n";
    #} else {
    #    print "The file ($ARGV[0]) is not an SQL file";
    #}
}


1;


