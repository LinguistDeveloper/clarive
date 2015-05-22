Ext.namespace('Ext.ux.panel');

/**
 * @class Ext.ux.panel.DDTabPanel
 * @extends Ext.TabPanel
 * @author
 *     Original by
 *         <a href="http://extjs.com/forum/member.php?u=22731">thommy</a> and
 *         <a href="http://extjs.com/forum/member.php?u=37284">rizjoj</a><br />
 *     Published and polished by: Mattias Buelens (<a href="http://extjs.com/forum/member.php?u=41421">Matti</a>)<br />
 *     With help from: <a href="http://extjs.com/forum/member.php?u=1459">mystix</a>
 *     Polished and debugged by: Tobias Uhlig (info@internetsachen.com) 04-25-2009
 *     Ported to Ext-3.1.1 by: Tobias Uhlig (info@internetsachen.com) 02-14-2010
 *     Updated by <a href="http://www.sencha.com/forum/member.php?56442-brombs">brombs</a>
 *     to include reorder event
 *     Modified by <a href="http://www.onenaught.com">Anup Shah</a> to work as a plugin
 *     instead of subclass of TabPanel
 * @license Licensed under the terms of the Open Source <a href="http://www.gnu.org/licenses/lgpl.html">LGPL 3.0 license</a>.
 * Commercial use is permitted to the extent that the code/component(s) do NOT
 * become part of another Open Source or Commercially licensed development library
 * or toolkit without explicit permission.
 * @version 2.0.1 (Jan 11, 2013)
 */
Ext.ux.panel.DraggableTabs = Ext.extend(Object, {
    block_first_tab: false,
    constructor: function (config) {
        if (config) {
            Ext.apply(this, config);
        }
    },
        
    init: function(tp) {
        if ((tp instanceof Ext.TabPanel) === false)
            return;

        // make these available onto the TabPanel as per original plugin, where used externally
        tp.arrowOffsetX = this.arrowOffsetX;
        tp.arrowOffsetY = this.arrowOffsetY;

        tp.addEvents('reorder');
            
        // TODO: check if ddGroupId can be left as a property of this plugin rather than on the TabPanel
        if (!tp.ddGroupId) {
            tp.ddGroupId = 'dd-tabpanel-group-' + tp.getId();
        }
            
        // New Event fired after drop tab. Is there a cleaner way to do this?
        tp.reorder = this.reorder;
        tp.oldinitTab = tp.initTab;
        tp.initTab = this.initTab;
        tp.onRemove = this.onRemove;

        tp.on('afterrender', this.afterRender, this);

        this.tabPanel = tp;
    },

    destroy: function () {
        tp.un('afterrender', this.afterRender, this);
        delete this.tabPanel;
        Ext.destroy(this.dd, this.arrow);
    },

    /**
    * @cfg {Number} arrowOffsetX The horizontal offset for the drop arrow indicator, in pixels (defaults to -9).
    */
    arrowOffsetX: -9,
    /**
    * @cfg {Number} arrowOffsetY The vertical offset for the drop arrow indicator, in pixels (defaults to -8).
    */
    arrowOffsetY: -8,

    reorder: function(tab) {
        this.fireEvent('reorder', this, tab);
    },
            
    // Declare the tab panel as a drop target
    /** @private */
    afterRender: function () {
        // Create a drop arrow indicator
        this.tabPanel.arrow = Ext.DomHelper.append(
            Ext.getBody(),
            '<div class="dd-arrow-down"></div>',
            true
        );
        this.tabPanel.arrow.hide();
        // Create a drop target for this tab panel
        var tabsDDGroup = this.tabPanel.ddGroupId;

        this.dd = new Ext.ux.panel.DraggableTabs.DropTarget(this, {
            ddGroup: tabsDDGroup, block_first_tab: this.block_first_tab
        });

        // needed for the onRemove-Listener
        this.move = false;
    },

    // Init the drag source after (!) rendering the tab
    /** @private */
    initTab: function (tab, index) {
        this.oldinitTab(tab, index);
        var id = this.id + '__' + tab.id;
        // Hotfix 3.2.0
        Ext.fly(id).on('click', function () { tab.ownerCt.setActiveTab(tab.id); });
        // Enable dragging on all tabs by default
        Ext.applyIf(tab, { allowDrag: true });

        // Extend the tab
        Ext.apply(tab, {
            // Make this tab a drag source
            ds: new Ext.dd.DragSource(id, {
                ddGroup: this.ddGroupId
                , dropEl: tab
                , dropElHeader: Ext.get(id, true)
                , scroll: false

                // Update the drag proxy ghost element
                , onStartDrag: function () {
                  // if (this.dropEl.iconCls) 
                    if (this.dropEl) {

                        var el = this.getProxy().getGhost().select(".x-tab-strip-text");
                       el.addClass('x-panel-inline-icon');
                        console.log(el);
                        var proxyText = el.elements[0].innerHTML;
                        proxyText = Ext.util.Format.stripTags(proxyText);
                        el.elements[0].innerHTML = proxyText;

                        el.applyStyles({
                            paddingLeft: "20px"
                        });
                    }
                }
     

                // Activate this tab on mouse up
                // (Fixes bug which prevents a tab from being activated by clicking it)
                , onMouseUp: function (event) {
                    if (this.dropEl.ownerCt.move) {
                        if (!this.dropEl.disabled && this.dropEl.ownerCt.activeTab == null) {
                            this.dropEl.ownerCt.setActiveTab(this.dropEl);
                        }
                        this.dropEl.ownerCt.move = false;
                        return;
                    }
                    if (!this.dropEl.isVisible() && !this.dropEl.disabled) {
                        this.dropEl.show();
                    }
                }
            })
            // Method to enable dragging
            , enableTabDrag: function () {
                this.allowDrag = true;
                return this.ds.unlock();
            }   
            // Method to disable dragging
            , disableTabDrag: function () {
                this.allowDrag = false;
                return this.ds.lock();
            }
        });

       
        //disable dragging in tab1:
       if( this.block_first_tab &&  index == 0){
            tab.disableTabDrag();

        }

        // Initial dragging state
        if (tab.allowDrag) {
            tab.enableTabDrag();
        } else {
            tab.disableTabDrag();
        }
    }

    /** @private */
    , onRemove: function (c) {
        var te = Ext.get(c.tabEl);
        // check if the tabEl exists, it won't if the tab isn't rendered
        if (te) {
            // DragSource cleanup on removed tabs
            //Ext.destroy(c.ds.proxy, c.ds);
            te.select('a').removeAllListeners();
            Ext.destroy(te);
        }

        // ignore the remove-function of the TabPanel
        Ext.TabPanel.superclass.onRemove.call(this, c);

        this.stack.remove(c);
        delete c.tabEl;
        c.un('disable', this.onItemDisabled, this);
        c.un('enable', this.onItemEnabled, this);
        c.un('titlechange', this.onItemTitleChanged, this);
        c.un('iconchange', this.onItemIconChanged, this);
        c.un('beforeshow', this.onBeforeShowItem, this);

        // if this.move, the active tab stays the active one
        if (c == this.activeTab) {
            if (!this.move) {
                var next = this.stack.next();
                if (next) {
                    this.setActiveTab(next);
                } else if (this.items.getCount() > 0) {
                    this.setActiveTab(0);
                } else {
                    this.activeTab = null;
                }
            }
            else {
                this.activeTab = null;
            }
        }
        if (!this.destroying) {
            this.delegateUpdates();
        }
    }
});

Ext.preg('draggabletabs', Ext.ux.panel.DraggableTabs);

// Ext.ux.panel.DraggableTabs.DropTarget
// Implements the drop behavior of the tab panel
/** @private */
Ext.ux.panel.DraggableTabs.DropTarget = Ext.extend(Ext.dd.DropTarget, {
    block_first_tab: false,
    constructor: function (dd, config) {
        this.tabpanel = dd.tabPanel;
        // The drop target is the tab strip wrap
        Ext.ux.panel.DraggableTabs.DropTarget.superclass.constructor.call(this, this.tabpanel.stripWrap, config);
    }

    , notifyOver: function (dd, e, data) {
        var tabs = this.tabpanel.items;
        var last = tabs.length;

        if (!e.within(this.getEl()) || dd.dropEl == this.tabpanel ) {
            return 'x-dd-drop-nodrop';
        }

        var larrow = this.tabpanel.arrow;

        // Getting the absolute Y coordinate of the tabpanel
        var tabPanelTop = this.el.getY();

        var left, prevTab, tab;
        var eventPosX = e.getPageX();

        for (var i = this.block_first_tab?1:0; i < last; i++) {
            prevTab = tab;
            tab = tabs.itemAt(i);
            // Is this tab target of the drop operation?
            var tabEl = tab.ds.dropElHeader;
            // Getting the absolute X coordinate of the tab
            var tabLeft = tabEl.getX();
            // Get the middle of the tab
            var tabMiddle = tabLeft + tabEl.dom.clientWidth / 2;

            if (eventPosX <= tabMiddle) {
                left = tabLeft;
                break;
            }
        }

        if (typeof left == 'undefined') {
            var lastTab = tabs.itemAt(last - 1);
            if (lastTab == dd.dropEl) return 'x-dd-drop-nodrop';
            var dom = lastTab.ds.dropElHeader.dom;
            left = (new Ext.Element(dom).getX() + dom.clientWidth) + 3;
        }

       else if (tab == dd.dropEl && prevTab == tabs.itemAt(1) ) {
            this.tabpanel.arrow.hide();
            return 'x-dd-drop-nodrop';
        }
/*
        else if (tab == dd.dropEl || prevTab == dd.dropEl || prevTab == tabs.itemAt(-1)) {
            this.tabpanel.arrow.hide();
            return 'x-dd-drop-nodrop';
        }*/

        larrow.setTop(tabPanelTop + this.tabpanel.arrowOffsetY).setLeft(left + this.tabpanel.arrowOffsetX).show();

        return 'x-dd-drop-ok';
    }
/**
  , notifyDrop: function (dd, e, data) {
       this.tabpanel.arrow.hide();
        // no parent into child
        if (dd.dropEl == this.tabpanel) {
            return false;
        }
        var tabs = this.tabpanel.items;
        var eventPosX = e.getPageX();


        for (var i = 1; i < tabs.length; i++) {
            var tab = tabs.itemAt(i);
            // Is this tab target of the drop operation?
            var tabEl = tab.ds.dropElHeader;
            // Getting the absolute X coordinate of the tab
            var tabLeft = tabEl.getX();
            // Get the middle of the tab
            var tabMiddle = tabLeft + tabEl.dom.clientWidth / 2;
            if (eventPosX <= tabMiddle) break;
        }

        // do not insert at the same location
        if (tab == dd.dropEl || tabs.itemAt(i - 1) == dd.dropEl) {
            return false;
        }

        dd.proxy.hide();

        // if tab stays in the same tabPanel
        if (dd.dropEl.ownerCt == this.tabpanel) {
            if (i > tabs.indexOf(dd.dropEl)) i--;
        }

        this.tabpanel.move = true;
        var dropEl = dd.dropEl.ownerCt.remove(dd.dropEl, false);

        this.tabpanel.insert(i, dropEl);
        // Event drop
        this.tabpanel.fireEvent('drop', this.tabpanel);
        // Fire event reorder
        this.tabpanel.reorder(tabs.itemAt(i));

        return true;
    }
**/
     ,notifyDrop: function(dd, e, data){
        this.tabpanel.arrow.hide();
        var tabs = this.tabpanel.items;
        var last = tabs.length;
        var eventPosX = e.getPageX();
        var newPos = last;
//        dd.dropEl.position = last * 2 + 1; // default: 'behind the rest'

        var dragLeft=true;

//blocking drag&drop for dashboard tab:
        for(var i = this.block_first_tab?1:0; i < tabs.length; i++){            
            var tab = tabs.itemAt(i);

            if( dd.dropEl.id==tab.id ){
                dragLeft=false;
            }
            
            // Is this tab target of the drop operation?
            var tabEl = tab.ds.dropElHeader;
            // Getting the absolute X coordinate of the tab
            var tabLeft = tabEl.getX();
            // Get the middle of the tab
            var tabMiddle = tabLeft + tabEl.dom.clientWidth / 2;
            
            var tabRight = tabLeft + tabEl.dom.clientWidth*1.5;
            
            if( dragLeft ){
                if(eventPosX <= tabMiddle){
                    break;
                }
            }else{
                if(eventPosX <= tabRight){
                    break;
                }
            }
        }
        
        //reset positions just in case new tabs were added
        tabs.each(function(tab, index){
//            alert(tab.title);
            tab.position = (index + 1) * 2;
        });

        // Insert the tab element at the new position
//        dd.proxy.hide();
        if( i+1==last ){
            dd.el.dom.parentNode.insertBefore(dd.el.dom, dd.el.dom.parentNode.childNodes[i].nextSibling);
            
            dd.dropEl.position=(last*2)+1;
        }else{
            if( dragLeft ){
                dd.el.dom.parentNode.insertBefore(dd.el.dom, dd.el.dom.parentNode.childNodes[i]);
            
                dd.dropEl.position=((i)*2)+1;
            }else{
                dd.el.dom.parentNode.insertBefore(dd.el.dom, dd.el.dom.parentNode.childNodes[i+1]);
            
                dd.dropEl.position=((i+1)*2)+1;
            }
        }
        
        // Sort tabs by their actual position
        tabs.sort('ASC', function(a, b){
            return a.position - b.position;
        });
        // Adjust tab position values
        tabs.each(function(tab, index){
            tab.position = (index + 1) * 2;
        });
        
        //var dropEl = dd.dropEl.ownerCt.remove(dd.dropEl, false);
        //this.tabpanel.insert(i, dropEl);
        //this.tabpanel.activate(dropEl);

        return true;
    }


    , notifyOut: function (dd, e, data) {
        this.tabpanel.arrow.hide();
    }
});