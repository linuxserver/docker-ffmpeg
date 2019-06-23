// Initiate a websocket connection to the server
var host = window.location.hostname; 
var port = window.location.port;
var protocol = window.location.protocol;
var socket = io.connect(protocol + '//' + host + ':' + port, {});

// On connect render the main page
$(document).ready(function(){rendermain()})

//// Main Page rendering ////
function rendermain(){
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getmain');
}
socket.on('sendmain', function(rules){
  $('#pagecontent').empty();
  var editor = [];
  $(JSON.parse(rules)).each(function(i,data){
    var name = data.name;
    var extension = data.extension;
    var command = data.command;
    $('#pagecontent').append('\
      <div class="card">\
        <div class="card-header">\
          Process Rule ' + name + '\
        </div>\
        <div class="card-body">\
          <form>\
            <div class="form-row align-items-center">\
              <div class="col-auto">\
                <input type="text" class="form-control" value="' + extension + '" placeholder="File Extension">\
              </div>\
              <div class="col-auto">\
                <div class="form-check mb-2">\
                  <input class="form-check-input" type="checkbox" id="deletesource">\
                  <label class="form-check-label" for="deletesource">\
                    Delete Source\
                  </label>\
                </div>\
              </div>\
              <div class="col-auto">\
                <button class="btn btn-primary mb-2">Save</button>\
              </div>\
              <div class="col float-right">\
                <button class="btn btn-success mb-2 float-right">Run Now</button>\
              </div>\
            </div>\
          </form>\
          <br>\
          <div id="editor' + i + '" style="height: 250px; width: 100%"></div>\
        </div>\
      </div>\
      <br>\
    ').promise().done(function(){
        editor[i] = ace.edit("editor" + i);
        editor[i].setTheme("ace/theme/chrome");
        editor[i].session.setMode("ace/mode/sh");
        editor[i].$blockScrolling = Infinity;
        editor[i].setOptions({
          readOnly: false,
        });
        editor[i].setValue(data.command, -1);
    });
  }).promise().done(function(){
      $('#pagecontent').append('<center><button type="button" class="btn btn-secondary btn-lg">+</button></center>');
  });
});



