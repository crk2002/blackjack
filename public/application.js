$(document).ready(function(){
  $(document).on("click","#hit_user_button",function(){
    $.ajax({
      type: "POST",
      url: "/hit_user"
      })
      .done(function(msg){
        $('div#game').html(msg)
      });
    });
  $(document).on("click","#user_stays_button",function(){
    $.ajax({
      type: "POST",
      url: "/user_stays"
      })
      .done(function(msg){
        $('div#game').html(msg)
      });
    });
      
});