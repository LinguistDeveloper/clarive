package Baseliner::Schema::Migrations::0106_ensure_ci_seq_are_numeric;
use Moose;
use Baseliner::Utils;

sub upgrade {
    my @forms = map{$_->{id}}mdb->rule->find({rule_type=>'form'})->all;
    foreach my $form (@forms){
        my $rule = mdb->rule->find_one({rule_type=>'form', id=>$form});
        my $json= _decode_json($rule->{rule_tree});
        my @numbers_id;
        foreach my $el (@$json) {
            my $attributes = $el->{attributes};
            my $data = $attributes->{data};
            if ($attributes->{key} eq 'fieldlet.number') {
                push (@numbers_id, $data->{id_field});
            }
        }
        my $category = mdb->category->find_one({default_form=>$form});
        if($category){
            my $category_name = $category->{name};
            my @topics = mdb->topic->find({category_name=>$category_name})->all;
            foreach my $topic (@topics){
                my $data;
                foreach my $element ( @numbers_id ){
                    if($topic->{$element} && $topic->{$element} ne '' ){
                        $data->{$element} = $topic->{$element}+0;
                    }
                }
                if($data){
                   mdb->topic->update({ mid=>"$topic->{mid}" },{ '$set'=>$data });
                }
            }
        }
    }
}

sub downgrade {

    # not needed, no harm in having number instead of a string
}

1;

