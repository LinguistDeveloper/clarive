package Baseliner::Schema::Migrations::0109_update_fieldletType;
use Moose;
use Baseliner::Utils;

sub upgrade {
    my @ids = map{$_->{id}} mdb->rule->find({rule_type=>'form'})->all;
    foreach my $form_id (@ids){
        my $rule = mdb->rule->find_one({id=>$form_id});
        my $json= eval {_decode_json($rule->{rule_tree})} or do {
            warn "Cannot decode $rule->{id} rule_tree: $!. Skipped";
            next;
        };
        foreach my $el (@$json) {
            my $attributes = $el->{attributes};
            my $data = $attributes->{data};

            if(!exists $data->{fieldletType}){
                $data->{fieldletType} = $attributes->{key};
            }
        }

        my $new_tree_rule = _encode_json($json);
        mdb->rule->update({id=>$form_id}, {'$set' => {rule_tree => $new_tree_rule}});

   }
}

sub downgrade {

}

1;
