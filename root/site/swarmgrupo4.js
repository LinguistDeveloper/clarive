Cla.Swarmgrupo4 = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;
        self.i = 0;

        self.tbar = [
            { text:_('Start Anim'), handler:function(){ self.start_anim() } },
            { text:_('Stop Anim'), handler:function(){ self.stop_anim() } },
            '-',
            { text:_('First'), handler:function(){ self.first() } },
            '-',
            { text:_('Add'), handler:function(){ self.i++; self.add() } },
            '-',
            { text:_('Del'), handler:function(){ self.i++; self.del() } }
        ];

        Cla.Swarmgrupo4.superclass.initComponent.call(this);
         
        self.on('resize', function(p,w,h){
            if( self.svg ) {
            }
        });
        self.on('afterrender', function(){
            self.init();
        });
    },
    init : function(){
        var self = this;

        var color = d3.scale.category10();

        self.nodes = [];
        self.links = [];
        self.nodes2 = [];
        self.nodes3 = [];

        self.array =  [
        { t:'1000', ev:'add', who:'pedro', node: '#44343', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44343', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44344', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44344', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44345', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44346', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44347', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44347', parent:'Email' },
        { t:'6000', ev:'add', who:'diego', node: '#44348', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44349', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44349', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44358', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44358', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44359', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44360', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44361', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44361', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44362', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44363', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44364', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44364', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44365', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44365', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44366', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44367', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44368', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44368', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44369', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44369', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44370', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44371', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44372', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44372', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'Changeset' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Release' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Release' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Release' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'BD' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'BD' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Email' },
        { t:'1000', ev:'add', who:'pedro', node: '#44353', parent:'BD' },
        { t:'2000', ev:'del', who:'pedro', node: '#44353', parent:'BD' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'BD' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'BD' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'BD' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Email' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Email' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Email' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'BD' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'BD' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'BD' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'BD' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Hostage' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Hostage' },
        { t:'12000', ev:'add', who:'pedro', node: '#44352', parent:'Hostage' },
        { t:'3000', ev:'add', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'4000', ev:'del', who:'tot', node: '#44354', parent:'Changeset' },
        { t:'5000', ev:'add', who:'carlos', node: '#44355', parent:'Changeset' },
        { t:'6000', ev:'add', who:'diego', node: '#44356', parent:'Changeset' },
        { t:'7000', ev:'add', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'8000', ev:'del', who:'marco', node: '#44357', parent:'Changeset' },
        { t:'9000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'10000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'11000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'13000', ev:'add', who:'ana', node: '#52', parent:'BD' }
        ];

        $.injectCSS({
            //".link": { "stroke": "green", 'stroke-width': '2.5px'},
            //".link2": { "stroke": "blue", 'stroke-width': '2.5px'},
            //".node": { "stroke": "#fff", fill:"#000", 'stroke-width': '1.5px' },
            ".node.a": { "fill": "red" },
            ".node.b": { "fill": "green" },
            ".node3": { "fill": "#1f77b4" }
        });

        var id = self.body.id; 
        var selector = '#' + id; 

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').attr("preserveAspectRatio", "xMinYMin meet");
        self.svg = self.vis.append("svg:g").call(d3.behavior.zoom().on("zoom", function(){self.rescale()})).on("dblclick.zoom", null).append('svg:g');
        
        //CREAMOS UN RECTANGULO EN BLANCO DONDE SE VA A PINTAR TODO Y ES EL QUE HACE EL ZOOM
        self.svg.append('svg:rect')
            .attr('width', self.width)
            .attr('height', self.height)
            .attr('fill', 'white')
        //LLAMAMOS AL LAYOUT
        self.force = d3.layout.force()
            .nodes(self.nodes)
            .links(self.links)
            .charge(-80)
            .linkDistance(50)
            .size([self.width, self.height])
            .on("tick", function(){ self.tick() });

        self.node = self.svg.selectAll(".node");
        self.link = self.svg.selectAll(".link");
        self.link2 = self.svg.selectAll(".link");
        self.node2 = self.svg.selectAll(".path");
        self.node3 = self.svg.selectAll(".path");
        self.node4 = self.svg.selectAll(".path");
        self.node5 = self.svg.selectAll(".path");
        self.node6 = self.svg.selectAll(".path");
        self.node7 = self.svg.selectAll(".path");
        self.node8 = self.svg.selectAll(".path");

    },
    start_anim : function(){

        var self = this;

        self.anim_running = true;
        setTimeout(function(){ self.anim() },1500);
    },
    stop_anim : function(){

        var self = this;

        self.anim_running = false;
    },
    anim : function(){

        var self = this;

        if( !self.anim_running ) return;
        
        if(self.array[self.i].ev == 'add') {
            self.useradd();
            self.add();
            self.i++;
        }else {
            self.userdel();
            self.del();
            self.i++;
        }
        setTimeout(function(){ self.anim() },1500);
    },
    first : function(){

        var self = this;

        var a = { id: "9999" , node: "raiz"}
        self.nodes.push(a);

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        //quitamos la parte de el nodo para que no aparezca, solo definimos el elemento circulo
        self.node.enter().append("circle");//.attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr('fill','red').on("zoom", function(){self.rescale()});
        self.node.exit().remove();
        
        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node4.enter().append("text");//.text(a.node);
        self.node4.exit().remove();
        self.nodos_iniciales();
        
    },
    nodos_iniciales : function(){

        var self = this;

        var arrayOriginal = [];  
        var arraySinDuplicados = [];
        var i = 0;
        var h = 0;

        for (i=0; i< self.array.length; i++){
            arrayOriginal[i] = self.array[i].parent;
        }
        
        $.each(arrayOriginal, function(i, el){
        if($.inArray(el, arraySinDuplicados) === -1) arraySinDuplicados.push(el);
        });

        for(j=0; j< arraySinDuplicados.length; j++){
            self.add_inicial(arraySinDuplicados[j]);
        }

    },
    add_inicial : function(array){

        var self = this;
        var a = self.nodes[0];
        var d = {id: "#d"+Math.random(), node: array};

        if (!a){
             self.nodes.push(d)
        }else 
            {
            //var c = self.nodes[1];
            self.nodes.push(d);
            self.links.push({source: d, target: a});
            }
        
        self.start_inicial();
    },
    start_inicial : function(){

        var self = this;

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","steelblue").attr("stroke-opacity",0.4);
        self.link.exit().remove();

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr("fill","steelblue").on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(function(d) { return d.node;}).attr("fill","steelblue");
        self.node4.exit().remove();

        //CREAMOS EL LINK2 Y LOS NODOS 2 Y 3 VACIOS YA QUE EN EL ARBOL INICIAL NO HAY USUARIOS   
        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node");
        self.link2.exit().remove();

        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image");
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text");
        self.node3.exit().remove();

        self.force.start();
        self.borrar_nodo();
    },
    add : function(){

        var self = this;
        var a = self.nodes[0];
        var d = {id: self.i};

        if (!a){
             self.nodes.push(d);
             self.links.push({source: d, target: d});
        }else 
            {
            //var c = self.nodes[1];
            var j = 0;
            while (j < self.nodes.length){

                if (self.nodes[j].node == self.array[self.i].parent){
                        self.nodes.push(d);
                        self.links.push({source: d, target: self.nodes[j]});
                        j=self.nodes.length;
                }   
                j++;
            }
        self.useradd();
        self.start();
        }
    },
    useradd  : function(){

        var self = this;

        //var a = self.nodes2[0];
        var d = {id: self.i, node: "d"+self.array[self.i].node, who: self.array[self.i].who};
        self.nodes2.push(d);
        self.userstart();
    },
    //ESTE METODO DE MOMENTO NO SE USA...
    userdel : function(){

        var self = this;        

        self.nodes2.splice(self.nodes2.length-1); // borra el ultimo nodo creado
        self.userstart();
    },
    //FALTA CAPTURAR FICHERO Y COMPROBAR EL NODO A BORRAR
    del : function(){

        var self = this;

        self.nodes.splice(self.nodes.length-1); // borra el ultimo nodo creado
        self.links.pop(); // remove b-c
        self.userdel();
        self.start();
    },
    start : function(){

        var self = this;

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text");
        self.node5.exit().remove();
        self.node6 = self.node6.data(self.force.nodes(), function(d) { return d.id;});
        self.node6.enter().append("text");
        self.node6.exit().remove();
        self.node7 = self.node7.data(self.force.nodes(), function(d) { return d.id;});
        self.node7.enter().append("text");
        self.node7.exit().remove();
        self.node8 = self.node8.data(self.force.nodes(), function(d) { return d.id;});
        self.node8.enter().append("text");
        self.node8.exit().remove();

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link").attr("stroke","orange");
        self.link.exit().remove();

      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 6).attr("fill","red").attr("fill-opacity",0.6).on("zoom", function(){self.rescale()}) 
        .on('dblclick', function (d){
             if (d3.select(this).attr("fill") != "red")
                {
                    d3.select(this).attr("fill", "red").transition().duration(3000).attr("r",6);
                    self.node5.remove();
                    self.node5.exit().remove();
                    self.node6.remove();
                    self.node6.exit().remove();
                    self.node7.remove();
                    self.node7.exit().remove();
                    self.node8.remove();
                    self.node8.exit().remove();

                }
            else 
                {
                    d3.select(this).attr("fill","yellow").transition().duration(3000).attr("r", 55);    
                    self.node5.remove();
                    self.node5.exit().remove();
                    self.node6.remove();
                    self.node6.exit().remove();
                    self.node7.remove();
                    self.node7.exit().remove();
                    self.node8.remove();
                    self.node8.exit().remove();         
                    self.node5.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","red").attr("fill-opacity",0.6);
                    self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","red").attr("fill-opacity",0.6);
                    self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","red").attr("fill-opacity",0.6);
                    self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","red").attr("fill-opacity",0.6);
                }
        });
        ;
        self.node.exit().remove();

        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node").attr("stroke","green").attr("class", "link");       
        self.link2.exit().remove();


        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(self.array[self.i].node).attr("fill","red").attr("fill-opacity",0.6).transition().duration(1000).attr("fill","red").remove();
        self.node4.exit().remove();

        self.force.start();
        self.borrar_nodo();
    },
    userstart : function(){
        
        var self = this;

        var randomValuex = Math.random()*200;
        var randomValuey = Math.random()*200;

        //quitamos esto para quitar la linea de link2


        self.node2 = self.node2.data(self.force.nodes(), function(d) { return d.id;});
        self.node2.enter().append("png:image").attr("xlink:href", "/static/images/user_min.png").attr("width", 20).attr("height", 20);
        self.node2.exit().remove();

        self.node3 = self.node3.data(self.force.nodes(), function(d) { return d.id;});
        self.node3.enter().append("text").text(self.array[self.i].who).attr("fill","#00CCFF")

    }, 
    tick : function(){



        var self = this;



        self.node.attr("cx", function(d) { return d.x; })
            .attr("cy", function(d) { return d.y; })
            
        self.node4.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });

        //podemos quitar link2 de aqui y ponemos los self completos
        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.source.x+50; })
          .attr("y2", function(d) { return d.source.y+50; });
          /*.attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*50); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*50); })
            .transition().duration(3000)
            .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*aleatorio_x*100); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*aleatorio_y*100);})
            .ease("elastic")
            .transition().duration(3000)
            .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*aleatorio_x*-50); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*aleatorio_y*-50); })
            .ease("elastic");*/
            //.remove();


        //estos se quitan con link2  
        self.node2.attr("x", function(d) { return d.x+50; })
          .attr("y", function(d) { return d.y+50; });

        /*.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*50); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*50); })
            .transition().duration(3000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*100); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*100);})
            .ease("elastic")
            .transition().duration(3000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*-50); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*-50); })
            .ease("elastic");*/
            //.remove();

      self.node3.attr("x", function(d) { return d.x+50; })
          .attr("y", function(d) { return d.y+50; });


      /*.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*50); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*50); })
            .transition().duration(3000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*100); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*100); })
            .ease("elastic")
            .transition().duration(3000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*-50); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*-50); })
            .ease("elastic");*/
            //.remove();



        //estos se ponen sin link2
        //self.node2.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
        //self.node3.attr("transform", function(d) { return "translate(" + d.x + "," + d.y + ")"; });
    },
    rescale : function() {

        var self = this;

        self.svg.attr("transform","translate(" + d3.event.translate + ")" + " scale(" + d3.event.scale + ")");

    },
    calculo_direcciones_x : function(x){

        if(x < 350){
            x=1;
        }else{
            x=-1;
        }
        return x;
    },
    calculo_direcciones_y : function(y){

        if(y < 250){
            y=1;
        }else{
            y=-1;
        }
        return y;
    },
    borrar_nodo : function(){

        var self = this;

        var aleatorio_x = Math.random();
        var aleatorio_y = Math.random();

        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*60); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*60); })
            .transition().duration(1000)
            .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*aleatorio_x*80); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*aleatorio_y*80);})
            .ease("elastic")

            .remove();

        self.node2.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); })
            .transition().duration(1000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*80); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*80);})
            .ease("elastic")

            .remove();

      self.node3.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); })
            .transition().duration(1000)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*80); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*80); })
            .ease("elastic")

            .remove();

    }
});