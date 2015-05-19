<%perl>
my $iid = Util->_md5;
</%perl>
(function(params){ 
    var id = params.id_div;
    var rows = params.data.rows;
    var days = params.data.days || 1000;
    var bls = params.data.bls || 'ALL';
    var style_tpl = function(){/*
    <style>
        .progress {
          overflow: hidden;
          height: 20px;
          margin-bottom: 20px;
          background-color: #f5f5f5;
          border-radius: 4px;
          -webkit-box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.1);
          box-shadow: inset 0 1px 2px rgba(0, 0, 0, 0.1);
        }
        .progress-bar {
          float: left;
          width: 0%;
          height: 100%;
          font-size: 12px;
          line-height: 20px;
          color: #ffffff;
          text-align: center;
          background-color: #428bca;
          -webkit-box-shadow: inset 0 -1px 0 rgba(0, 0, 0, 0.15);
          box-shadow: inset 0 -1px 0 rgba(0, 0, 0, 0.15);
          -webkit-transition: width 0.6s ease;
          transition: width 0.6s ease;
        }
        .progress-striped .progress-bar {
          background-image: -webkit-gradient(linear, 0 100%, 100% 0, color-stop(0.25, rgba(255, 255, 255, 0.15)), color-stop(0.25, transparent), color-stop(0.5, transparent), color-stop(0.5, rgba(255, 255, 255, 0.15)), color-stop(0.75, rgba(255, 255, 255, 0.15)), color-stop(0.75, transparent), to(transparent));
          background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: -moz-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-size: 40px 40px;
        }
        .progress.active .progress-bar {
          -webkit-animation: progress-bar-stripes 2s linear infinite;
          animation: progress-bar-stripes 2s linear infinite;
        }
        .progress-bar-success {
          background-color: #5cb85c;
        }
        .progress-striped .progress-bar-success {
          background-image: -webkit-gradient(linear, 0 100%, 100% 0, color-stop(0.25, rgba(255, 255, 255, 0.15)), color-stop(0.25, transparent), color-stop(0.5, transparent), color-stop(0.5, rgba(255, 255, 255, 0.15)), color-stop(0.75, rgba(255, 255, 255, 0.15)), color-stop(0.75, transparent), to(transparent));
          background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: -moz-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
        }
        .progress-bar-info {
          background-color: #5bc0de;
        }
        .progress-striped .progress-bar-info {
          background-image: -webkit-gradient(linear, 0 100%, 100% 0, color-stop(0.25, rgba(255, 255, 255, 0.15)), color-stop(0.25, transparent), color-stop(0.5, transparent), color-stop(0.5, rgba(255, 255, 255, 0.15)), color-stop(0.75, rgba(255, 255, 255, 0.15)), color-stop(0.75, transparent), to(transparent));
          background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: -moz-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
        }
        .progress-bar-warning {
          background-color: #f0ad4e;
        }
        .progress-striped .progress-bar-warning {
          background-image: -webkit-gradient(linear, 0 100%, 100% 0, color-stop(0.25, rgba(255, 255, 255, 0.15)), color-stop(0.25, transparent), color-stop(0.5, transparent), color-stop(0.5, rgba(255, 255, 255, 0.15)), color-stop(0.75, rgba(255, 255, 255, 0.15)), color-stop(0.75, transparent), to(transparent));
          background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: -moz-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
        }
        .progress-bar-danger {
          background-color: #d9534f;
        }
        .progress-striped .progress-bar-danger {
          background-image: -webkit-gradient(linear, 0 100%, 100% 0, color-stop(0.25, rgba(255, 255, 255, 0.15)), color-stop(0.25, transparent), color-stop(0.5, transparent), color-stop(0.5, rgba(255, 255, 255, 0.15)), color-stop(0.75, rgba(255, 255, 255, 0.15)), color-stop(0.75, transparent), to(transparent));
          background-image: -webkit-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: -moz-linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
          background-image: linear-gradient(45deg, rgba(255, 255, 255, 0.15) 25%, transparent 25%, transparent 50%, rgba(255, 255, 255, 0.15) 50%, rgba(255, 255, 255, 0.15) 75%, transparent 75%, transparent);
        }
    </style>
    */};
    var html = style_tpl.tmpl({});
    var div = document.getElementById(id);
    div.style.clear = "left";

    var bl_tpl = function(){/*
        <span style="text-align:left;"><h4>[%=bl%]</h4></span>
        <div class="progress">
          <div class="progress-bar progress-bar-success" style="width: [%=porcentOk%]%" onmouseover="this.style.cursor='pointer'" onClick="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs/[%=days%]/ok/[%=bl%]', _('[%=bl%] - [%=totOk%]/[%=total%] OK'));">
            <span class="sr-only">[%=totOk%]</span>
          </div>
          <div class="progress-bar progress-bar-danger" style="width: [%=porcentError%]%" onmouseover="this.style.cursor='pointer'" onClick="javascript:Baseliner.addNewTabComp('/dashboard/viewjobs/[%=days%]/nook/[%=bl%]', _('[%=bl%] - [%=totError%]/[%=total%] ERROR'));">
            <span class="sr-only" >[%=totError%]</span>
          </div>
        </div>        
    */};
    Cla.ajax_json('/dashboard/list_baseline', {days: days, bls: bls}, function(res){
      Ext.each(res.data, function(bl) {
        html = html + bl_tpl.tmpl({total: bl.total, bl: bl.bl, porcentOk: bl.porcentOk, totOk: bl.totOk, porcentError: bl.porcentError, totError: bl.totError, days:days});
      });

      div.innerHTML = html;
    });
});