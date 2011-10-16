use rig bang;
use strict;
use XML::Simple;
use Data::Printer;

my $mm = XMLin( join '',<DATA> );
say yy $mm;
$mm = {
    node => {
        TEXT => 'Baseliner',
        node => {
            TEXT => 'TEST',
            node => {
                TEXT => 'pkg1'
            }
        }
    }
};

say q{<?xml version="1.0" encoding="UTF-8" standalone="no"?>};
say XMLout { map=>{ version=>'0.8.1', %$mm } };

__DATA__
<?xml version="1.0" encoding="UTF-8" standalone="no"?>
<map version="0.8.1">
    <node CREATED="1317123514918" ID="7p7b7k5jlb4a1jivkpkklqebqv" MODIFIED="1317123514918" TEXT="todo&#x9;">
        <node CREATED="1317123514918" ID="2gpgh03t8qlak4ivlr557uf3sh" MODIFIED="1317123514918" POSITION="right" TEXT="menus">
            <node CREATED="1317123514918" ID="5jdllvqdarrg5f55cjvuc2drp2" MODIFIED="1317123514918" TEXT="git menus">
                <node CREATED="1317123514919" ID="5o58k56a9u188eesbgk989g70j" MODIFIED="1317123514919" TEXT="promote" />
                <node CREATED="1317123514919" ID="1gd106f7bijq2tven65h4tvhus" MODIFIED="1317123514919" TEXT="demote" />
                <node CREATED="1317123514919" ID="5c2k7gcsovoo7m1jfermkbp3b7" MODIFIED="1317123514919" TEXT="deploy" />
                <node CREATED="1317123514919" ID="0tvo6qmhc2vtsi04ei1mgkm5pj" MODIFIED="1317123514919" TEXT="create tag" />
                <node CREATED="1317123514919" ID="4lsag2p5vbjsacae6pobr60ov2" MODIFIED="1317123514919" TEXT="rename" />
            </node>
        </node>
        <node CREATED="1317123514919" ID="0g2aak3h4m50dqrelstb88oibn" MODIFIED="1317123514919" POSITION="right" TEXT="html git">
            <node CREATED="1317123514920" ID="21vibo4kaja6ermcpjd12anpfc" MODIFIED="1317123514920" TEXT="view element" />
            <node CREATED="1317123514920" ID="20f9jko6k5n25lljsg3hi4r3o5" MODIFIED="1317123514920" TEXT="commit details" />
        </node>
        <node CREATED="1317123514920" ID="3q14rt68ptjhralh79rf5hrvsi" MODIFIED="1317123514920" POSITION="right" TEXT="tasks">
            <node CREATED="1317123514920" ID="2u03a2cu8hb85cqm2uq3sai9er" MODIFIED="1317123514920" TEXT="create a new task" />
            <node CREATED="1317123514920" ID="1gin0q8trtu3rdrsqtvsnocvk3" MODIFIED="1317123514920" TEXT="assoc task to tag" />
        </node>
        <node CREATED="1317123514920" ID="4kobq7ee0aqki9h98amvbm0m2p" MODIFIED="1317123514920" POSITION="right" TEXT="git">
            <node CREATED="1317123514920" ID="53212eke22vbmtdu263p0ncvv3" MODIFIED="1317123514920" TEXT="differences unassigned with previous tag" />
        </node>
        <node CREATED="1317123514920" ID="7gntv4iimlt4vm2sivir2fmuk9" MODIFIED="1317123514920" POSITION="left" TEXT="despliegues">
            <node CREATED="1317123514920" ID="3sd2isnr9ptqvc1657f7gbfqq4" MODIFIED="1317123514920" TEXT="crear app java" />
        </node>
        <node CREATED="1317123514920" ID="7inj0pfrfep9dc3o13c492e0ea" MODIFIED="1317123514920" POSITION="left" TEXT="putaditas">
            <node CREATED="1317123514920" ID="1dc594tru26kj6p2qbs9gfbi2s" MODIFIED="1317123514920" TEXT="acentos en log" />
        </node>
        <node CREATED="1317123514920" ID="3ss730bgsa52cla3le51kibq0b" MODIFIED="1317123514920" POSITION="left" TEXT="imprescindible">
            <node CREATED="1317123514921" ID="31rer185okp0hecb12frmqom8t" MODIFIED="1317123514921" TEXT="pantalla de login Baseliner" />
            <node CREATED="1317123514921" ID="5taojmgdp55nh7135r6jhili5r" MODIFIED="1317123514921" TEXT="creación de tags" />
            <node CREATED="1317123514921" ID="4jofdlqt9f1a0slqj356u0ota2" MODIFIED="1317123514921" TEXT="ppt" />
        </node>
    </node>
</map>

