// Initiate a websocket connection to the server
var host = window.location.hostname; 
var port = window.location.port;
var protocol = window.location.protocol;
var socket = io.connect(protocol + '//' + host + ':' + port, {});

// On connect render the main page
$(document).ready(function(){rendermain()})

//// Main Page rendering ////
function rendermain(){
  $('#pagecontent').empty();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getmain');
}
socket.on('sendmain', function(rules){
  $('#pagecontent').empty();
  var editor = [];
  $(rules.commands).each(function(i,data){
    var name = data.name;
    var extension = data.extension;
    var command = data.command;
    $('#pagecontent').append('\
      <div class="card" id="' + name + '">\
        <div class="card-body">\
          <form>\
            <div class="form-row align-items-center">\
              <div class="col-auto">\
                <input type="text" class="form-control" value="' + name + '" placeholder="File Extension">\
              </div>\
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
              <div class="col float-right">\
                <button class="btn btn-success mb-2 float-right">Run Single</button>\
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
        editor[i].setValue(command, -1);
    });
  }).promise().done(function(){
      $('#pagecontent').append('<center><button type="button" class="btn btn-secondary btn-lg">+</button></center>');
  });
});

//// Command Page rendering ////
function rendercommands(){
  $('#pagecontent').empty();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getcommands');
}
socket.on('sendcommands', function(categories){
  console.log(categories);
  $('#pagecontent').empty();
  var editor = [];
  $('#pagecontent').append('<div id="cats"></div>')
  $(categories).each(function(i,data){
    var cat = data.category;
  });
});
