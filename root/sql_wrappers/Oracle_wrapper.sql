<%args>
    $sqlcode
</%args>
set autocommit off;
set echo on;
set sqlblanklines on;
whenever SQLERROR EXIT ROLLBACK;
<% $sqlcode %>

