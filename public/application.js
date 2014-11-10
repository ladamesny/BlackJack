$(document).ready(function(){

  // This syntax allows us to not lose the binding with the #hit_form input element each time this element is clicked
  $(document).on('click','#hit_form input', function(){
    $.ajax({
      // Three parts of a request: 1) type/verb 2) url and 3) parameters (none in this case)
      type: 'POST',
      url: '/game/player/hit'
      // msg variable here holds the payload returned from the AJAX request which is the html to be rendered
    }).done(function(msg){ 
      //we replace the portion of html on the view template with the new html code we received from the ajax request
      $('#game').replaceWith(msg);
    });
      //this stops the "hit" form submissionand lets ajax control the event
      return false;
  });

  $(document).on('click','#stay_form input', function(){
    $.ajax({
      type: 'POST',
      url: '/game/player/stay'
    }).done(function(msg){ 
      $('#game').replaceWith(msg);
    });
      return false;
  });

  $(document).on('click','#dealer_cards input', function(){
    $.ajax({
      type: 'GET',
      url: '/game/dealer'
    }).done(function(msg){ 
      $('#game').replaceWith(msg);
    });
      return false;
  });


});