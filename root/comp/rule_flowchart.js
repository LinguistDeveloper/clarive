Cla.RuleFlowchart = Ext.extend(Ext.Panel, {
    layout: 'border',
    initComponent: function() {
        var self = this;

        self.canvas = new Ext.Panel({
            region: 'center',
            layout: 'fit'
        });
        self.palette = new Ext.Panel({
            region: 'west',
            hidden: true,
            width: 100,
            layout: 'fit'
        });
        self.overview = new Ext.Panel({
            title: _('Overview'),
            html: 'overview',
            bodyStyle: "z-index:10",
            floating: true,
            height: 200,
            width: 200,
            animCollapse: true,
            collapsible: true
        });
        self.items = [self.canvas, self.palette, self.overview];

        self.btnSvg = new Ext.Button({
            icon: IC('export.svg'),
            text: _('Export as SVG'),
            handler: function() {
                self.makeSVG()
            }
        });
        var btnIncreaseZoom = new Ext.Button({
            icon: IC('plus.svg'),
            tooltip: _('Zoom In'),
            handler: function() {
                self.myDiagram.commandHandler.increaseZoom()
            }
        });
        var btnDecreaseZoom = new Ext.Button({
            icon: IC('minus.svg'),
            tooltip: _('Zoom Out'),
            handler: function() {
                self.myDiagram.commandHandler.decreaseZoom()
            }
        });
        self.tbar = (self.tbar || []).concat(['->', btnIncreaseZoom, btnDecreaseZoom, '-', self.btnSvg]);

        self.goApi = go.GraphObject.make;

        self.overview.on('afterrender', function() {
            var ow = self.goApi(go.Overview, self.overview.body.id, {
                observed: self.myDiagram,
                contentAlignment: go.Spot.Center
            });

            self.canvas.on('resize', function() {
                var left = self.container.getWidth() - 200;
                self.overview.setPosition(left, 0);
            });
        });

        self.canvas.on('afterrender', function() {
            self.myDiagram = self.goApi(go.Diagram, self.canvas.body.id, {
                layout: self.goApi(go.LayeredDigraphLayout, {
                    isInitial: false,
                    isOngoing: false,
                    direction: 90,
                    layerSpacing: 20
                }),
                initialContentAlignment: go.Spot.Center,
                allowDrop: true, // must be true to accept drops from the Palette
                "LinkDrawn": showLinkLabel, // this DiagramEvent listener is defined below
                "LinkRelinked": showLinkLabel,
                "animationManager.duration": 800, // slightly longer than default (600ms) animation
                "undoManager.isEnabled": true // enable undo & redo
            });

            // when the document is modified, add a "*" to the title and enable the "Save" button
            self.myDiagram.addDiagramListener("Modified", function(e) {});

            // Make all ports on a node visible when the mouse is over the node
            function showPorts(node, show) {
                var diagram = node.diagram;
                if (!diagram || diagram.isReadOnly || !diagram.allowLink) return;
                node.ports.each(function(port) {
                    port.stroke = (show ? "white" : null);
                });
            }

            // helper definitions for node templates

            function nodeStyle() {
                return [
                    // The Node.location comes from the "loc" property of the node data,
                    // converted by the Point.parse static method.
                    // If the Node.location is changed, it updates the "loc" property of the node data,
                    // converting back using the Point.stringify static method.
                    new go.Binding("location", "loc", go.Point.parse).makeTwoWay(go.Point.stringify), {
                        // the Node.location is at the center of each node
                        locationSpot: go.Spot.Center,
                        //isShadowed: true,
                        //shadowColor: "#888",
                        // handle mouse enter/leave events to show/hide the ports
                        mouseEnter: function(e, obj) {
                            showPorts(obj.part, true);
                        },
                        mouseLeave: function(e, obj) {
                            showPorts(obj.part, false);
                        }
                    }
                ];
            }

            // Define a function for creating a "port" that is normally transparent.
            // The "name" is used as the GraphObject.portId, the "spot" is used to control how links connect
            // and where the port is positioned on the node, and the boolean "output" and "input" arguments
            // control whether the user can draw links from or to the port.
            function makePort(name, spot, output, input) {
                // the port is basically just a small circle that has a white stroke when it is made visible
                return self.goApi(go.Shape, "Circle", {
                    fill: "transparent",
                    stroke: null, // this is changed to "white" in the showPorts function
                    desiredSize: new go.Size(8, 8),
                    alignment: spot,
                    alignmentFocus: spot, // align the port on the main Shape
                    portId: name, // declare this object to be a "port"
                    fromSpot: spot,
                    toSpot: spot, // declare where links may connect at this port
                    fromLinkable: output,
                    toLinkable: input, // declare whether the user may draw links to/from here
                    cursor: "pointer" // show a different cursor to indicate potential link point
                });
            }

            // define the Node templates for regular nodes

            var lightText = 'whitesmoke';

            self.myDiagram.nodeTemplateMap.add("", // the default category
                self.goApi(go.Node, "Spot", nodeStyle(),
                    // the main object is a Panel that surrounds a TextBlock with a rectangular Shape
                    self.goApi(go.Panel, "Auto",
                        self.goApi(go.Shape, "Rectangle", {
                                fill: "#00A9C9",
                                stroke: null
                            },
                            new go.Binding("figure", "figure")),
                        self.goApi(go.TextBlock, {
                                font: "bold 10pt Helvetica, Arial, sans-serif",
                                stroke: lightText,
                                margin: 8,
                                maxSize: new go.Size(160, NaN),
                                wrap: go.TextBlock.WrapFit,
                                editable: true
                            },
                            new go.Binding("text").makeTwoWay())
                    ),
                    // four named ports, one on each side:
                    makePort("T", go.Spot.Top, false, true),
                    makePort("L", go.Spot.Left, true, true),
                    makePort("R", go.Spot.Right, true, true),
                    makePort("B", go.Spot.Bottom, true, false)
                ));

            self.myDiagram.nodeTemplateMap.add("Start",
                self.goApi(go.Node, "Spot", nodeStyle(),
                    self.goApi(go.Panel, "Auto",
                        self.goApi(go.Shape, "Circle", {
                            minSize: new go.Size(40, 40),
                            fill: "#79C900",
                            stroke: null
                        }),
                        self.goApi(go.TextBlock, "Start", {
                                font: "bold 11pt Helvetica, Arial, sans-serif",
                                stroke: lightText
                            },
                            new go.Binding("text"))
                    ),
                    // three named ports, one on each side except the top, all output only:
                    makePort("L", go.Spot.Left, true, false),
                    makePort("R", go.Spot.Right, true, false),
                    makePort("B", go.Spot.Bottom, true, false)
                ));

            self.myDiagram.nodeTemplateMap.add("End",
                self.goApi(go.Node, "Spot", nodeStyle(),
                    self.goApi(go.Panel, "Auto",
                        self.goApi(go.Shape, "Circle", {
                            minSize: new go.Size(40, 40),
                            fill: "#DC3C00",
                            stroke: null
                        }),
                        self.goApi(go.TextBlock, "End", {
                                font: "bold 11pt Helvetica, Arial, sans-serif",
                                stroke: lightText
                            },
                            new go.Binding("text"))
                    ),
                    // three named ports, one on each side except the bottom, all input only:
                    makePort("T", go.Spot.Top, false, true),
                    makePort("L", go.Spot.Left, false, true),
                    makePort("R", go.Spot.Right, false, true)
                ));

            self.myDiagram.nodeTemplateMap.add("if",
                self.goApi(go.Node, "Spot", nodeStyle(),
                    self.goApi(go.Panel, "Auto",
                        self.goApi(go.Shape, "Diamond", {
                            minSize: new go.Size(80, 80),
                            fill: "#DC3C00",
                            stroke: null
                        }),
                        self.goApi(go.TextBlock, "End", {
                                font: "bold 9pt Helvetica, Arial, sans-serif",
                                stroke: lightText
                            },
                            new go.Binding("text"))
                    ),
                    // three named ports, one on each side except the bottom, all input only:
                    makePort("T", go.Spot.Top, false, true),
                    makePort("L", go.Spot.Left, false, true),
                    makePort("R", go.Spot.Right, false, true),
                    makePort("B", go.Spot.Bottom, false, true)
                ));

            self.myDiagram.nodeTemplateMap.add("Comment",
                self.goApi(go.Node, "Auto", nodeStyle(),
                    self.goApi(go.Shape, "File", {
                        fill: "#EFFAB4",
                        stroke: null
                    }),
                    self.goApi(go.TextBlock, {
                            margin: 5,
                            maxSize: new go.Size(200, NaN),
                            wrap: go.TextBlock.WrapFit,
                            textAlign: "center",
                            editable: true,
                            font: "bold 12pt Helvetica, Arial, sans-serif",
                            stroke: '#454545'
                        },
                        new go.Binding("text").makeTwoWay())
                    // no ports, because no links are allowed to connect with a comment
                ));


            // replace the default Link template in the linkTemplateMap
            self.myDiagram.linkTemplate =
                self.goApi(go.Link, // the whole link panel
                    {
                        routing: go.Link.AvoidsNodes,
                        curve: go.Link.JumpOver,
                        corner: 5,
                        toShortLength: 4,
                        relinkableFrom: true,
                        relinkableTo: true,
                        reshapable: true,
                        resegmentable: true,
                        // mouse-overs subtly highlight links:
                        mouseEnter: function(e, link) {
                            link.findObject("HIGHLIGHT").stroke = "rgba(30,144,255,0.2)";
                        },
                        mouseLeave: function(e, link) {
                            link.findObject("HIGHLIGHT").stroke = "transparent";
                        }
                    },
                    new go.Binding("points").makeTwoWay(),
                    self.goApi(go.Shape, // the highlight shape, normally transparent
                        {
                            isPanelMain: true,
                            strokeWidth: 8,
                            stroke: "transparent",
                            name: "HIGHLIGHT"
                        }),
                    self.goApi(go.Shape, // the link path shape
                        {
                            isPanelMain: true,
                            stroke: "gray",
                            strokeWidth: 2
                        }),
                    self.goApi(go.Shape, // the arrowhead
                        {
                            toArrow: "standard",
                            stroke: null,
                            fill: "gray"
                        }),
                    self.goApi(go.Panel, "Auto", // the link label, normally not visible
                        {
                            visible: false,
                            name: "LABEL",
                            segmentIndex: 2,
                            segmentFraction: 0.5
                        },
                        new go.Binding("visible", "visible").makeTwoWay(),
                        self.goApi(go.Shape, "RoundedRectangle", // the label shape
                            {
                                fill: "#F8F8F8",
                                stroke: null
                            }),
                        self.goApi(go.TextBlock, "Yes", // the label
                            {
                                textAlign: "center",
                                font: "10pt helvetica, arial, sans-serif",
                                stroke: "#333333",
                                editable: true
                            },
                            new go.Binding("text").makeTwoWay())
                    )
                );

            // Make link labels visible if coming out of a "conditional" node.
            // This listener is called by the "LinkDrawn" and "LinkRelinked" DiagramEvents.
            function showLinkLabel(e) {
                var label = e.subject.findObject("LABEL");
                if (label !== null) label.visible = (e.subject.fromNode.data.figure === "Diamond");
            }

            // temporary links used by LinkingTool and RelinkingTool are also orthogonal:
            self.myDiagram.toolManager.linkingTool.temporaryLink.routing = go.Link.Orthogonal;
            self.myDiagram.toolManager.relinkingTool.temporaryLink.routing = go.Link.Orthogonal;

            var loading = Cla.showLoadingMask(self.getEl());

            // create the model data that will be represented by Nodes and Links
            Cla.ajax_json('/rule/flowchart', {
                id_rule: self.id_rule,
                json: self.json
            }, function(res) {
                self.myDiagram.model = new go.GraphLinksModel();
                self.myDiagram.model['class'] = "go.GraphLinksModel";
                self.myDiagram.model.linkFromPortIdProperty = "fromPort";
                self.myDiagram.model.linkToPortIdProperty = "toPort";
                self.myDiagram.model.nodeDataArray = res.nodes;
                self.myDiagram.model.linkDataArray = res.links;
                self.myDiagram.layoutDiagram(true);

                if (loading) Cla.hideLoadingMask(self.getEl());
            }, function(res) {
                Cla.error(_('Flowchart'), res.msg);
                if (loading) Cla.hideLoadingMask(self.getEl());
            });
        });

        self.canvas.on('resize', function() {
            self.myDiagram.layoutDiagram(true);
        });

        // initialize the Palette that is on the left side of the page
        self.palette.on('afterrender', function() {
            self.myPalette =
                self.goApi(go.Palette, self.palette.body.id, // must name or refer to the DIV HTML element
                    {
                        "animationManager.duration": 800, // slightly longer than default (600ms) animation
                        nodeTemplateMap: self.myDiagram.nodeTemplateMap, // share the templates used by myDiagram
                        model: new go.GraphLinksModel([ // specify the contents of the Palette
                            {
                                category: "Start",
                                text: "Start"
                            }, {
                                text: "Step"
                            }, {
                                text: "???",
                                figure: "Diamond"
                            }, {
                                category: "End",
                                text: "End"
                            }, {
                                category: "Comment",
                                text: "Comment"
                            }
                        ])
                    });
        });

        Cla.RuleFlowchart.superclass.initComponent.call(this);
    },
    // add an SVG rendering of the diagram at the end of this page
    makeSVG: function() {
        var self = this;
        var svg = self.myDiagram.makeSvg({
            scale: 0.5
        });
        svg.style.border = "1px solid black";
        var opened = window.open("");
        opened.document.write('<html><body><div id="SVGArea"></div></body></html>');
        obj = opened.document.getElementById("SVGArea");
        obj.appendChild(svg);
        if (obj.children.length > 0) {
            obj.replaceChild(svg, obj.children[0]);
        }
    }
});
