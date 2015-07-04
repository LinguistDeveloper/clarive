<%args>
    $sqlcode
</%args>

SET AUTOCOMMIT = 0;
<% $sqlcode %>
COMMIT;

