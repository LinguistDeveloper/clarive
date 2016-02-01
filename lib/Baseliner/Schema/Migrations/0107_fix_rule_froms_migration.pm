package Baseliner::Schema::Migrations::0107_fix_rule_forms_migration;
use Baseliner::Utils;
use Moose;

sub upgrade {
    my @topic_category = mdb->category->find->all;
    foreach my $topic_category (@topic_category){
        my $default_form = $topic_category->{default_form};
        my @fieldlets = _array $topic_category->{fieldlets};
        my @campos = map{[$_->{id_field}, [$_->{params}->{js}, $_->{params}->{bd_field}]]} grep {exists $_->{params}->{html}} grep {$_->{params}->{html} eq "/fields/templates/html/grid_editor.html"} @fieldlets;
        my @key_to_grid_editor;
        if(@campos){
            foreach my $campo (@campos){
                _log($campo->[0]);
                if($campo->[1][0] ne '/fields/templates/js/milestones.js' && $campo->[1][1] ne 'hitos'){
                    push (@key_to_grid_editor, $campo->[0])
                }
            }
        }
        if(@key_to_grid_editor){
            _log(\@key_to_grid_editor);
            my $default_rule = mdb->rule->find_one({rule_type=>'form', id=>$default_form});
            my $json= _decode_json($default_rule->{rule_tree});
            OUTER: foreach my $idchanged (@key_to_grid_editor){
                INNER: foreach my $el (@$json) {
                    my $attributes = $el->{attributes};
                    my $data = $attributes->{data};
                    if ($data->{id_field} eq $idchanged) {
                        $attributes->{key} = 'fieldlet.grid_editor';
                        $attributes->{expanded} = 'true';
                        $data->{fieldletType} = 'fieldlet.grid_editor';
                        last INNER;
                    }
                }
            }
            my $new_rule = _encode_json($json);
            mdb->rule->update({id=>$default_form}, {'$set' => {rule_tree => $new_rule}});
        }
    }

    my @forms = map{$_->{default_form}}mdb->category->find->all;
    foreach my $form (@forms){
        my $default_rule = mdb->rule->find_one({rule_type=>'form', id=>$form});
        my $json= eval {_decode_json($default_rule->{rule_tree})} or do {
            warn "Cannot decode $default_rule->{id} rule_tree: $!. Skipped";
            next;
        };
        foreach my $el (@$json) {
            my $attributes = $el->{attributes};
            my $data = $attributes->{data};
            if ($attributes->{key} eq 'fieldlet.system.cis') {
                if($data->{html} eq '/fields/templates/html/ci_grid.html' && $data->{js} eq '/fields/system/js/list_ci.js'){
                    $attributes->{key} = 'fieldlet.ci_list';
                    $data->{fieldletType} = 'fieldlet.ci_list';
                    $data->{list_type} = '';
                }
            }
        }
        my $new_rule = _encode_json($json);
        mdb->rule->update({id=>$form}, {'$set' => {rule_tree => $new_rule}});
    }
}

sub downgrade {
    # not needed, no harm in having a _seq in there
}

1;


