package Baseliner::Schema::Migrations::0128_fix_update_rule_report_icons;
use Baseliner::Schema::Migrations::0126_update_rule_report_icons;
use Moose;

sub upgrade {
    Baseliner::Schema::Migrations::0126_update_rule_report_icons->update_reports_icons;
}

sub downgrade {
}

1;
