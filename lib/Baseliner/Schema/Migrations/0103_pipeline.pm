package Baseliner::Schema::Migrations::0103_pipeline;
use Moose;

sub upgrade {
    mdb->rule->update({ rule_type=>'chain' },{ '$set'=>{ rule_type=>'pipeline' } },{ multiple=>1 });
    mdb->rule_version->update({ rule_type=>'chain' },{ '$set'=>{ rule_type=>'pipeline' } },{ multiple=>1 });
}

sub downgrade {
    mdb->rule->update({ rule_type=>'pipeline' },{ '$set'=>{ rule_type=>'chain' } },{ multiple=>1 });
    mdb->rule_version->update({ rule_type=>'pipeline' },{ '$set'=>{ rule_type=>'chain' } },{ multiple=>1 });
}

1;


