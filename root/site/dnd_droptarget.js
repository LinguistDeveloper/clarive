// Ext.ux.panel.DraggableTabs.DropTarget
// Implements the drop behavior of the tab panel
/** @private */
Ext.ux.panel.DraggableTabs.DropTarget = Ext.extend(Ext.dd.DropTarget, {
    constructor: function (dd, config) {
        this.tabpanel = dd.tabPanel;
        // The drop target is the tab strip wrap
        Ext.ux.panel.DraggableTabs.DropTarget.superclass.constructor.call(this, this.tabpanel.stripWrap, config);
    }
 
    , notifyOver: function (dd, e, data) {
        var tabs = this.tabpanel.items;
        var last = tabs.length;
 
        if (!e.within(this.getEl()) || dd.dropEl == this.tabpanel) {
            return 'x-dd-drop-nodrop';
        }
 
        var larrow = this.tabpanel.arrow;
 
        // Getting the absolute Y coordinate of the tabpanel
        var tabPanelTop = this.el.getY();
 
        var left, prevTab, tab;
        var eventPosX = e.getPageX();
 
        for (var i = 0; i < last; i++) {
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
 
        else if (tab == dd.dropEl || prevTab == dd.dropEl) {
            this.tabpanel.arrow.hide();
            return 'x-dd-drop-nodrop';
        }
 
        larrow.setTop(tabPanelTop + this.tabpanel.arrowOffsetY).setLeft(left + this.tabpanel.arrowOffsetX).show();
 
        return 'x-dd-drop-ok';
    }
 
    , notifyDrop: function (dd, e, data) {
        this.tabpanel.arrow.hide();
 
        // no parent into child
        if (dd.dropEl == this.tabpanel) {
            return false;
        }
        var tabs = this.tabpanel.items;
        var eventPosX = e.getPageX();
 
        for (var i = 0; i < tabs.length; i++) {
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
 
    , notifyOut: function (dd, e, data) {
        this.tabpanel.arrow.hide();
    }
});