<%perl>
  use Baseliner::Utils;
  my $idjob = $c->stash->{id_job};
  my $namejob = $c->stash->{name_job};
</%perl>

<div id="project" style="padding: 10px 10px 10px 10px;">   
<div id="project" style="width: 98%; padding: 2px 2px 2px 2px;">
  <div class="container body">
    <div id="bodyjob" class="span-24" width="100%">
      <span>Job: <%$namejob%> (<a href="javascript:Baseliner.addNewTabComp('/job/log/list?id_job=<%$idjob%>', _('Log details <%$namejob%>'), { tab_icon: '/static/images/icons/moredata.gif' } );"> log completo </a>)</span>
    </div>
  </div>
</div>
</div>
</body>
