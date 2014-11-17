$(document).ready(function() {
    if( !window.Cla ) window.Cla = {};
    Cla.get_content = function(mid,cb){
        $.ajax({
            type: 'POST',
            url: '/doc/content',
            data: { mid: mid },
            success: function(res){
                cb(res);
            },
            error: function(res){
                alert( _('Error loading doc with mid %1', mid) );
            }
        });
    }
    Cla.show_content = function(doc){
        if( doc==undefined ) {
            $('#content-body').html(_('INVALID CONTENT'));
            $('.main-header .main-title').html(_('INVALID CONTENT'));
            return;
        }
        var type = doc.type; // self.attr('type');
        var mid = doc.mid; // self.attr('mid');
        // setup breadcrubs
        Cla.gen_breadcrumb( doc.path ); 
        // show the content
        if( mid ) {
            Cla.get_content(mid,function(res){
                var body = res.body;
                $('#content-body').html(body);
                $('.main-header .main-title').html(res.title);
                // gen on-page list
                var anchors=[];
                $('.content :header').each(function(ix,el){
                    el.id = Baseliner.name_to_id(el.innerHTML);
                    anchors.push({ text:el.innerHTML, link: el.id });
                });
                var on_page = function(){/*
                      <ul>
                          [% for(var i=0; i<anchors.length;i++){ %]
                              <li><a href="#[%= anchors[i].link %]">[%= anchors[i].text %]</a></li>
                          [% } %]
                      </ul>
                */}.tmpl({ title: res.title, anchors: anchors });
                    
                var doc_info = function(){/*
                    [% for(var i=0;i<info.length;i++) { %]
                        <li class="data-row">
                            <span class="data-name">[%= info[i].text %]</span>
                        </li>
                        <li class="data-row">
                            <span class="data-value">[%= info[i].value %]</span>
                        </li>
                    [% } %]
                */}.tmpl({ info: res.info });
                $('.doc-info').html(doc_info);
                $('.doc-info-box').show();
                $('.on-page').html(on_page);
                $(".on-page-well").show();
                History.pushState({ },_(res.title), doc.moniker );
            });
        } else {
            alert( _('Missing mid for document') );
        }
    };
    var click_content = function(e){
        var self = $(this);
        var moniker = self.attr('moniker');
        var mid = self.attr('mid');
        var type = self.attr('type');
        if( type=='index' ) {
            Cla.show_index();
        } else if( moniker || mid ) {
            Cla.show_content( index_by_moniker[moniker]  || index_by_mid[mid] );
        } else {
            alert( _('No content available for this element') );
        }
    };
    Cla.to_pdf = function(source,cb){
            var pdf = new jsPDF('p', 'pt', 'a4');
            // source can be HTML-formatted string, or a reference
            // to an actual DOM element from which the text will be scraped.

            // we support special element handlers. Register them with jQuery-style 
            // ID selector for either ID or node name. ("#iAmID", "div", "span" etc.)
            // There is no support for any other type of selectors 
            // (class, of compound) at this time.
            specialElementHandlers = {
                // element with id of "bypass" - jQuery style selector
                '#bypassme': function (element, renderer) {
                    // true = "handled elsewhere, bypass text extraction"
                    return true
                }
            };
            margins = {
                top: 80,
                bottom: 60,
                left: 40,
                width: 522
            };
            pdf.setFont('helvetica');
            // all coords and widths are in jsPDF instance's declared units
            // 'inches' in this case
            pdf.fromHTML(
                source, // HTML string or DOM elem ref.
                margins.left, // x coord
                margins.top, { // y coord
                    'width': margins.width, // max width of content on PDF
                    'elementHandlers': specialElementHandlers
                },
                function (dispose) {
                    // dispose: object with X, Y of the last line add to the PDF 
                    //          this allow the insertion of new lines after html
                    pdf.save( Baseliner.name_to_id(Cla.doc_title)+'.pdf' );
                    if( cb ) cb(pdf);
                }, margins
            );
    }
    Cla.prepare_nav = function(){
        $(".main-menu .js-menu-entry").click(click_content);
        $(".main-menu .js-sub-menu-toggle").click(function(e) {
            e.preventDefault(); 
            $li = $(this).parents("li").first();
            $li.hasClass("active") 
                ? ($li.closestChild(".toggle-icon").removeClass("fa-angle-down").addClass("fa-angle-left"), $li.removeClass("active")) 
                : ($li.closestChild(".toggle-icon").removeClass("fa-angle-left").addClass("fa-angle-down"), $li.addClass("active"));
            $li.closestChild(".sub-menu").slideToggle(300);
        }); 

        $(".js-toggle-minified").clickToggle(function() {
            $(".left-sidebar").addClass("minified"), $(".content-wrapper").addClass("expanded"), $(".left-sidebar .sub-menu").css("display", "none").css("overflow", "hidden"), $(".sidebar-minified").find("i.fa-angle-left").toggleClass("fa-angle-right")
        }, function() {
            $(".left-sidebar").removeClass("minified"), $(".content-wrapper").removeClass("expanded"), $(".sidebar-minified").find("i.fa-angle-left").toggleClass("fa-angle-right")
        }); 
        
        $(".main-nav-toggle").clickToggle(function() {
            $(".left-sidebar").slideDown(300)
        }, function() {
            $(".left-sidebar").slideUp(300)
        });
       
        Cla.doc_iframe = function(){
            var ifr = $("#frame-doc")[0].contentWindow.document; // contentWindow works in IE7 and FF
            ifr.open(); ifr.close(); // must open and close document object to start using it!
            $("head", ifr).html(function(){/*
                <link rel="stylesheet" href="/static/docgen/bootstrap.css" type="text/css" />
            */}.heredoc());
            $("body", ifr).html('');
            return ifr;
        };
        $(".pdf-page").click(function(){
            var ifr = Cla.doc_iframe();
            var fd = $('body', ifr);
            fd.html( $('.content').html() );
            Cla.to_pdf( ifr.body );
        });
        $(".pdf-all").click(function(){
            var ifr = Cla.doc_iframe();
            // var fd = $('#full-doc');
            var fd = $('body', ifr);
            fd.html('');
            var lev = [1];
            var curr_lev = 0;
            fd.append(function(){/*
                <h1>[%= title %]</h1>
                <hr />
            */}.tmpl({ title: Cla.doc_title }) );
            var print_when_ready = function(){
                if( k==0 ) {
                    Cla.to_pdf(ifr.body, function(pdf){
                        $(ifr.document).html('');
                    });
                }
            };
            var write_doc = function(ix,doc){
                if( doc.children.length > 0 ) {
                    fd.append(function(){/*
                         <h1 class="main-title">[%= lev %] [%= doc.text %]</h1>
                    */}.tmpl({ lev: lev.join('.'), doc:doc }) ); 
                    lev[curr_lev] ? lev[curr_lev]++ : lev[curr_lev]=1;
                    curr_lev++;
                    k--;
                    k += doc.children.length;
                    $.each(doc.children,write_doc);
                    curr_lev--;
                    print_when_ready();
                } else {
                    Cla.get_content( doc.mid, function(res){
                        fd.append(function(){/*
                             <h1 class="main-title">[%= title %]</h1>
                             <p>[%= body %]</p>
                        */}.tmpl(res) ); 
                        k--;
                        print_when_ready();
                    });
                }
            };
            var k = index_all.length;
            $.each(index_all,write_doc);
        });
    };
    Cla.gen_menu = function(row){
        return function(){/*
              [% if( children.length > 0 ) { %]
                  <li class="[%= active ? 'active' : '' %]"><a href="#" class="js-sub-menu-toggle">
                     <i class="fa [%= icon %] fa-fw"></i><span class="text">[%= text %]</span>
                        <i class="toggle-icon fa fa-angle-left"></i></a>
                        <ul class="sub-menu">
                            [% for( var i=0; i<children.length; i++) { %]
                                [%= Cla.gen_menu(children[i]) %]
                            [% } %]
                        </ul>
                  </li>
              [% } else { %]
                  <li class="[%= active ? 'active' : '' %]"><a href="#" mid="[%= topic_mid %]" type="[%= type %]" moniker="[%= moniker %]" class="js-menu-entry">
                     [% if( icon && icon!='' ) { %]
                         <i class="fa [%= icon %] fa-fw"></i><span class="text">[%= text %]</span></a></li>
                     [% } %]
              [% } %]
         */}.tmpl($.extend({ active: false, id_folder: -1, type:'topic', topic_mid: -1, path:'/', moniker:'',
             icon:( row.id_folder>-1 || (row.children && row.children.length>0) ? 'fa-folder' : 'fa-file-text-o pull-left'), children: [] },row));
    };
    
    Cla.gen_index = function(row){
        return function(){/*
              [% if( children.length > 0 ) { %]
                  <h3>[%= text %]</h3>
                        [% var chi = children.sort(function(a,b){ return a.children.length>0 ?1:-1 }); %]
                        [% for( var i=0; i<chi.length; i++) { %]
                            [% if( chi[i].children.length>0 ) { %]
                                <div style="padding-left: 30px">
                            [% } %]

                            [%= Cla.gen_index(chi[i]) %]

                            [% if( chi[i].children.length>0 ) { %]
                                </div>
                            [% } %]
                        [% } %]
              [% } else { %]
                  <ul class="list-unstyled">
                  <li>
                  <a href="#" mid="[%= topic_mid %]" path="[%=path%]" moniker="[%=moniker%]" class="index-content">
                     [% if( icon && icon!='' ) { %]
                         <i class="fa [%= icon %] fa-fw"></i>
                     [% } %]
                     <span class="text">[%= text %]</span>
                  </a>
                  </li>
                  </ul>
              [% } %]
         */}.tmpl($.extend({ active: false, id_folder: -1, topic_mid: -1, path:'/', moniker:'',
             icon:( row.id_folder>-1 || (row.children && row.children.length>0) ? 'fa-folder' : 'fa-file-text-o pull-left'), children: [] },row));
    };
    Cla.gen_breadcrumb = function(path){
        if( path.constructor !== Array ) path=path.split('/');
        $('.breadcrumb').html(function(){/*
            <li><i class="fa fa-home"></i><a href="#" class="breadcrumb-home">Home</a></li>
            [% for(var i=0; i<path.length && path[i].length>0; i++ ){ %]  
                <li class="active">[%= path[i] %]</li>
            [% } %]
         */}.tmpl({ path: path })
        );
        $(".breadcrumb-home").click(function(){ 
            Cla.show_index();
        });
    };
    
    var index_by_moniker ={};
    var index_by_mid ={};
    var index_all =[];
    var index_html ='';
    Cla.fetch_document = function(cb){
        $.ajax({
            type: 'POST',
            url: '/doc/menu',
            data: { doc_id: Cla.doc_id },
            success: function(res){
                Cla.doc_title = _(res.doc_title);
                document.title = Cla.doc_title;
                var html= Cla.gen_menu({ active: true, text:_('Index'), type:'index', moniker:'index.html', path:'' });
                var reg_index = function(row){  // recursive register index
                    row.mid = row.topic_mid;
                    if( row.moniker ) index_by_moniker[ row.moniker ] = row;
                    if( row.mid ) index_by_mid[ row.mid ] = row;
                    $.each( row.children, function(ix,row2){ reg_index(row2) } );
                };
                $.each(res.menu, function(ix, row) {           
                    html += Cla.gen_menu(row); 
                    index_html += Cla.gen_index(row);
                    reg_index(row);
                });
                index_all = res.menu;
                $('.main-menu').html(html);
                // setup clicks and everythins
                Cla.prepare_nav();
                // callback
                if( cb ) cb();
            },
            error: function(res, textStatus){
                alert( _('Error getting document data') );
                console.log( res );
            }
        });
    }
    Cla.show_index = function(){
        $('.main-header .main-title').html(Cla.doc_title);
        $('#content-body').html('<div class="knowledge">'+index_html+"</div>");
        $("#content-body .index-content").click(click_content);
        $(".on-page-well").hide();
        $(".doc-info-box").hide();
        Cla.gen_breadcrumb(''); 
        History.pushState({}, Cla.doc_title, 'index.html' );
    };
    
    // MAIN =====================================================================
    // what's our url?
    var url = window.location.pathname.split('/'); 
    Cla.home_url = '/'+ url.slice(1,3).join('/') + '/';
    Cla.doc_id = url[2];
    Cla.doc_title = window.document.title;
    // get the structure and load the menu and index
    Cla.fetch_document(function(){
        var moniker = url[3];
        if( moniker && moniker!='index.html' ) {
            Cla.show_content( index_by_moniker[moniker] || index_by_mid[moniker] );
        } else {
            Cla.show_index();
        }
    });
    
    /*
    function e() {
        $(window).width() < 977 ? $(".left-sidebar").hasClass("minified") && ($(".left-sidebar").removeClass("minified"), $(".left-sidebar").addClass("init-minified")) : $(".left-sidebar").hasClass("init-minified") && $(".left-sidebar").removeClass("init-minified").addClass("minified")
    }


    $mainContentCopy = $(".main-content").clone(), $('.searchbox input[type="search"]').keydown(function() {
        var e = $(this);
        setTimeout(function() {
            var t = e.val();
            if (t.length > 2) {
                var o = new RegExp(t, "i"),
                    n = [];
                $(".widget-header h3").each(function() {
                    var e = $(this).text().match(o);
                    "" != e && null != e && n.push($(this).parents(".widget"))
                }), n.length > 0 ? ($(".main-content .widget").hide(), $.each(n, function(e, t) {
                    t.show()
                })) : console.log("widget not found")
            } else $(".main-content .widget").show()
        }, 0)
    });
    
    $(".bs-switch").length > 0 && $(".bs-switch").bootstrapSwitch(), $(".demo-only-page-blank").length > 0 && $(".content-wrapper").css("min-height", $(".wrapper").outerHeight(!0) - $(".top-bar").outerHeight(!0));
    */
    
}), $.fn.clickToggle = function(e, t) {
    return this.each(function() {
        var o = !1;
        $(this).bind("click", function() {
            return o ? (o = !1, t.apply(this, arguments)) : (o = !0, e.apply(this, arguments))
        })
    })
};

/*
 * jquery.closestchild 0.1.1
 *
 * Author: Andrey Mikhaylov aka lolmaus
 * Email: lolmaus@gmail.com
 *
 */
 
 ;(function($){
  $.fn.closestChild = function(selector) {
    var $children, $results;
    
    $children = this.children();
    
    if ($children.length === 0)
      return $();
  
    $results = $children.filter(selector);
    
    if ($results.length > 0)
      return $results;
    else
      return $children.closestChild(selector);
  };
})(window.jQuery);

