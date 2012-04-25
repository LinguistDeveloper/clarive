<%perl>
    use Baseliner::Utils;
    my @comentarios = $c->stash->{comments};
    my $title = $c->stash->{title};
    my $description = $c->stash->{description};  

</%perl>

    <style type="text/css">
        .comment{
            margin-top: 40px;
            margin-bottom: 40px;
        }
        
        .rectangle-border {
            position:relative;
            padding:15px;
            margin:1em 0 3em;
            border:5px solid #ccc;
            color:#333;
            background:#fff;
            /* css3 */
            -webkit-border-radius:10px;
            -moz-border-radius:10px;
            border-radius:10px;
        }
    
        .triangle-border {
            position:relative;
            padding:15px;
            margin:1em 0 3em;
            border:2px solid #ccc;
            color:#333;
            background:#fff;
            /* css3 */
            -webkit-border-radius:10px;
            -moz-border-radius:10px;
            border-radius:10px;
        }
        
        .triangle-border:before {
            content:"";
            position:absolute;
            bottom:-16px; /* value = - border-top-width - border-bottom-width */
            left:45px; /* controls horizontal position */
            border-width:15px 15px 0;
            border-style:solid;
            border-color:#ccc transparent;
            /* reduce the damage in FF3.0 */
            display:block;
            width:0;
        }
    
    
        /* creates the smaller  triangle */
        .triangle-border:after {
            content:"";
            position:absolute;
            bottom:-13px; /* value = - border-top-width - border-bottom-width */
            left:47px; /* value = (:before left) + (:before border-left) - (:after border-left) */
            border-width:13px 13px 0;
            border-style:solid;
            border-color:#fff transparent;
            /* reduce the damage in FF3.0 */
            display:block; 
            width:0;
        }    
    </style>

    <!--<div style="background-color: #ccc;">-->
        <div id="topico" style="height:20%;padding:0px 50px 0px 50px;">
            <div class="rectangle-border">
                <h1><%$title%></h1>
                <p><%$description%></p>
            </div>
        </div>
        <div id="comments" name="comments" style="overflow:auto;height:80%;padding:0px 100px 0px 100px;">
%   foreach my $comentario (_array @comentarios){
            <div class="comment">
                <p class="triangle-border"><%$comentario->{text}%></p>
            </div>
%}
        </div>
    <!--</div>-->