$(function(){
    $(document).keydown(function(e) {
        if(e.altKey && e.which == 37) {
            $('.previous-page').each(function(){
                document.location = $(this).attr('href');
            });
        }
        else if(e.altKey && e.which == 39) {
            $('.next-page').each(function(){
                document.location = $(this).attr('href');
            });
        }
        else {
            return;
        }
        e.preventDefault();
    });
});
