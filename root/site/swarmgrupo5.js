Cla.Swarmgrupo5 = Ext.extend( Ext.Panel, {
    initComponent : function(){
        var self = this;
        self.i = 0;
        self.cuenta = 0;

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

        Cla.Swarmgrupo5.superclass.initComponent.call(this);
         
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

        //var color = d3.scale.category10();

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
        { t:'9000', ev:'add', who:'diego', node: '#44348', parent:'Changeset' },
        { t:'10000', ev:'add', who:'marco', node: '#44349', parent:'Changeset' },
        { t:'11000', ev:'del', who:'marco', node: '#44349', parent:'Changeset' },
        { t:'12000', ev:'add', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'13000', ev:'del', who:'alex', node: '#44350', parent:'Changeset' },
        { t:'14000', ev:'add', who:'fran', node: '#44351', parent:'Changeset' },
        { t:'15000', ev:'add', who:'pedro', node: '#44352', parent:'Release' },
        { t:'16000', ev:'add', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'17000', ev:'del', who:'alex', node: '#44350', parent:'Emergency' },
        { t:'18000', ev:'add', who:'fran', node: '#44351', parent:'Emergency' },
        { t:'19000', ev:'add', who:'pedro', node: '#44352', parent:'Emergency' },
        { t:'20000', ev:'add', who:'pedro', node: '#44353', parent:'Changeset' },
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
        for(cnt = 0 ; cnt < self.array.length; cnt++){
            self.array[cnt].t = 10*(cnt+1);
        }

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

        self.vis = d3.select("#"+ id ).append("svg:svg").attr("width", '100%').attr("height", '100%').style("background-color", "black").attr("preserveAspectRatio", "xMinYMin meet");
        self.svg = self.vis.append("svg:g").call(d3.behavior.zoom().on("zoom", function(){self.rescale()})).on("dblclick.zoom", null).append('svg:g');
        
        //CREAMOS UN RECTANGULO EN BLANCO DONDE SE VA A PINTAR TODO Y ES EL QUE HACE EL ZOOM
        self.svg.append('svg:rect')
            .attr('width', '100%')
            .attr('height', '100%')
            .attr('fill', 'black')
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
        self.node9 = self.svg.selectAll(".path");
        self.texto = self.svg.selectAll("text");
  




        //COLORES DE LOS NODOS  

        var Color_Nodos_Raiz = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_Nodos_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#90B4D2").attr("stop-opacity", 0).attr("brighter",1); // Color steelblue aclarado + 4

        var Color_texto_Raiz = self.svg.append("defs").append("linearGradient").attr("id", "Color_texto_Raiz").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_texto_Raiz.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_texto_Raiz.append("stop").attr("offset", "60%").attr("stop-color", "#4682B4").attr("stop-opacity", 0.5); // Color steelblue
        Color_texto_Raiz.append("stop").attr("offset", "100%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1).attr("brighter",1); // Color blanco


        var Color_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Nodos.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Nodos.append("stop").attr("offset", "100%").attr("stop-color", "#FF6666").attr("stop-opacity", 0).attr("brighter",1); // Color red aclarado + 4


        var Color_Texto_Nodos = self.svg.append("defs").append("radialGradient").attr("id", "Color_Texto_Nodos").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Color_Texto_Nodos.append("stop").attr("offset", "0%").attr("stop-color", "#FF1919").attr("stop-opacity", 1); //Luminosidad color blanco
        Color_Texto_Nodos.append("stop").attr("offset", "60%").attr("stop-color", "#FF0000").attr("stop-opacity", 0.5); // Color red
        Color_Texto_Nodos.append("stop").attr("offset", "100%").attr("stop-color", "#FF1919").attr("stop-opacity", 1).attr("brighter",1); // Color blanco

        var Amarillo = self.svg.append("defs").append("radialGradient").attr("id", "Amarillo").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Amarillo.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Amarillo.append("stop").attr("offset", "60%").attr("stop-color", "#FFFF00").attr("stop-opacity", 0.5); // Color amarillo
        Amarillo.append("stop").attr("offset", "100%").attr("stop-color", "#FFFF66").attr("stop-opacity", 0).attr("brighter",1); // Color amarillo aclarado + 4

        var Verde = self.svg.append("defs").append("radialGradient").attr("id", "Verde").attr("cx", "50%").attr("cy", "50%").attr("r", "50%").attr("fx", "50%").attr("fy", "50%");
        //De donde podemos coger los rangos de colores http://www.w3schools.com/tags/ref_colorpicker.asp
        Verde.append("stop").attr("offset", "0%").attr("stop-color", "#FFFFFF").attr("stop-opacity", 1); //Luminosidad color blanco
        Verde.append("stop").attr("offset", "60%").attr("stop-color", "#00FF00").attr("stop-opacity", 0.5); // Color verde
        Verde.append("stop").attr("offset", "100%").attr("stop-color", "#66FF66").attr("stop-opacity", 0).attr("brighter",1); // Color verde aclarado + 4


    },
    start_anim : function(){

        var self = this;

        self.anim_running = true;
        setTimeout(function(){ self.anim() },self.timer*1.1);
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
        setTimeout(function(){ self.anim() },self.timer*1.1);
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

        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        //Nos pasa igual que con el circulo. Si hacemos visible el .text vemos el texto del nodo raiz.
        self.node5.enter().append("text");//.text(a.node);
        self.node5.exit().remove();



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


        self.texto = self.texto.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });   
        self.texto.enter().append('text').attr("fill","url(#Color_Nodos_Raiz)").text(function(d) { return d.source.node;});   

        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Color_Nodos_Raiz)").on("zoom", function(){self.rescale()});
        self.node.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(function(d) { return d.node;}).attr("fill","url(#Color_texto_Raiz)");
        self.node4.exit().remove();


        self.node5 = self.node5.data(self.force.nodes(), function(d) { return d.id;});
        self.node5.enter().append("text").text(function(d) { return d.node;}).attr("fill","url(#Color_texto_Raiz)");
        self.node5.exit().remove();



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
        //self.borrar_nodo(self.timer);
    },
    add : function(){

        var self = this;
        var a = self.nodes[0];
        var d = {id: self.i, node: self.array[self.i].parent};

        //CONTADOR DE APLICACION
       if((self.i-1) <0){
            self.timer = self.array[self.i].t;
        }else{
            self.timer = self.array[self.i].t-self.array[self.i-1].t;

        }

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
        //self.link2.push({source: d, target: d});
        self.userstart();
    },
    //ESTE METODO DE MOMENTO NO SE USA...
    userdel : function(){

        var self = this;        

        self.nodes2.splice(self.nodes2.length-1); // borra el ultimo nodo creado
        //self.link2.pop();
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
        self.node5.enter().append("text").text(self.array[self.i].node).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "hidden");
        self.node5.exit().remove();
       
        self.node6 = self.node6.data(self.force.nodes(), function(d) { return d.id;});
        self.node6.enter().append("text").style("visibility", "hidden");
        self.node6.exit().remove();
        self.node7 = self.node7.data(self.force.nodes(), function(d) { return d.id;});
        self.node7.enter().append("text").style("visibility", "hidden");
        self.node7.exit().remove();
        self.node8 = self.node8.data(self.force.nodes(), function(d) { return d.id;});
        self.node8.enter().append("text").style("visibility", "hidden");
        self.node8.exit().remove();
        self.node9 = self.node9.data(self.force.nodes(), function(d) { return d.id;});
        self.node9.enter().append("text").style("visibility", "hidden");
        self.node9.exit().remove();
        

        self.link = self.link.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link.enter().insert("line", ".node").attr("class", "link");//.attr("stroke","green");
        self.link.exit().remove();

        self.node4 = self.node4.data(self.force.nodes(), function(d) { return d.id;});
        self.node4.enter().append("text").text(self.array[self.i].node).attr("fill","url(#Verde)").transition().duration(self.timer).attr("fill","url(#Color_Texto_Nodos)").remove();
        self.node4.exit().remove();
      
        self.node = self.node.data(self.force.nodes(), function(d) { return d.id;});
        self.node.enter().append("circle").attr("class", function(d) { return "node " + d.id; }).attr("r", 10).attr("fill","url(#Verde)").attr("fill-opacity",0.6)
                         .on('mouseover', function(d)
                         {
                            d3.select(this).transition()
                            .duration(750)
                            .attr("r", 55)
                            .attr("fill","url(#Amarillo)")
                            //.attr("fill-opacity",0.6);
                            self.node9.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].t).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+3).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node6.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].ev).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+16).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node7.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].who).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+29).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            self.node8.enter().append("text").attr("x", d.x-10).attr("y",d.y-10).text(self.array[d.id].parent).transition().duration(3000).attr("x", d.x-10).attr("y", d.y+42).attr("fill","url(#Color_Texto_Nodos)").attr("fill-opacity",0.6).style("visibility", "visible");
                            return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "visible");
                         })
                         .on("mouseout", function()
                         {
                         d3.select(this).transition()
                         .duration(750)
                         .attr("r", 10)
                         .attr("fill","url(#Color_Nodos)")
                         .attr("fill-opacity",0.6);
                         self.node6.style("visibility", "hidden");
                         self.node7.style("visibility", "hidden");
                         self.node8.style("visibility", "hidden");
                         self.node9.style("visibility", "hidden");
                         return self.node5.attr("fill","url(#Color_Texto_Nodos)").style("visibility", "hidden");//})
                         })
                         .call(self.force.drag)
                         .transition().duration(self.timer).attr("fill","url(#Color_Nodos)").attr("fill-opacity",0.6);
        self.node.exit().remove();

        self.force.start();

        self.pintar_usuario();
    },
    userstart : function(){
        
        var self = this;

        var randomValuex = Math.random()*200;
        var randomValuey = Math.random()*200;

        //quitamos esto para quitar la linea de link2
        self.link2 = self.link2.data(self.force.links(), function(d) { return d.source.id + "-" + d.target.id; });
        self.link2.enter().insert("line", ".node").attr("stroke","orange").attr("stroke-opacity",0.6).attr("class", "link");       
        self.link2.exit().remove();

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

        self.node5.attr("x", function(d) { return d.x-10; })
            .attr("y", function(d) { return d.y-10; })

        self.texto.attr('x',function(d){ return (d.source.x+d.target.x)/2;})
        .attr('y',function(d){ return (d.source.y+d.target.y)/2;});

        self.link.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x; })
          .attr("y2", function(d) { return d.target.y; });



        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.source.x+50; })
          .attr("y2", function(d) { return d.source.y+50; });

        self.node2.attr("x", function(d) { return d.x+50; })
          .attr("y", function(d) { return d.y+50; });


      self.node3.attr("x", function(d) { return d.x+50; })
          .attr("y", function(d) { return d.y+50; });


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
    pintar_usuario : function(){


        //console.log(self.timer);
        var self = this;

        var aleatorio_x = Math.random();
        var aleatorio_y = Math.random();

//if (self.node[self.i].who)

//alert("nodo actual" + self.nodes[self.i].node + "nodo anterior" + self.nodes[self.i-1].node);
//console.log(self.nodes);


        self.node2.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); })
            .transition().duration(self.timer)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*80); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*80);})
            .ease("elastic")
            .remove();
        self.node2.exit().remove();

      self.node3.attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*60); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*60); })
            .transition().duration(self.timer)
            .attr("x", function(d) { return d.x-(self.calculo_direcciones_x(d.x)*aleatorio_x*80); })
            .attr("y", function(d) { return d.y-(self.calculo_direcciones_y(d.y)*aleatorio_y*80); })
            .ease("elastic")
            .remove();
         self.node3.exit().remove();


        self.link2.attr("x1", function(d) { return d.source.x; })
          .attr("y1", function(d) { return d.source.y; })
          .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*60); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*60); })
            .transition().duration(self.timer)
            .attr("x2", function(d) { return d.target.x-(self.calculo_direcciones_x(d.target.x)*aleatorio_x*80); })
            .attr("y2", function(d) { return d.target.y-(self.calculo_direcciones_y(d.target.y)*aleatorio_y*80);})
            .ease("elastic") 
            .remove();
        self.link2.exit().remove();


    }
});