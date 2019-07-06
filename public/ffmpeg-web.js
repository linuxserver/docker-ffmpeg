// Initiate a websocket connection to the server
var host = window.location.hostname; 
var port = window.location.port;
var protocol = window.location.protocol;
var socket = io.connect(protocol + '//' + host + ':' + port, {});


// On connect render the main page
$(document).ready(function(){rendermain()})

//// Main Page rendering ////
function rendermain(){
  pagepurge();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getmain');
}
socket.on('sendmain', function(data){
  pagepurge();
  $('#pagecontent').append('<center>Processed jobs here and current status</center>');
});

//// Config Page rendering ////
function renderconfig(){
  pagepurge();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getconfig');
}
socket.on('sendconfig', function(rules){
  pagepurge();
  var interval = rules.interval;
  $('#headerform').append('\
    <select class="custom-select form-control mr-sm-2" id="interval">\
      <option selected value="' + interval + '">' + interval + '</option>\
      <option value"Never">Never</option>\
      <option value="30">30 seconds</option>\
      <option value="60">60 seconds</option>\
      <option value="300">5 minutes</option>\
    </select>\
    <button style="cursor:pointer;" onclick="saveall()" class="btn btn-primary my-2 my-sm-0" type="submit">Save Config</button>\
  ');
  var editor = [];
  $(rules.commands).each(function(i,data){
    var name = data.name;
    var extension = data.extension;
    var command = data.command;
    var cleanup = data.delete;
    if (cleanup == true){
      var checkbox = '<input class="form-check-input" type="checkbox" id="delete' + i + '" checked>'
    }
    else{
      var checkbox = '<input class="form-check-input" type="checkbox" id="delete' + i + '">'
    }
    $('#pagecontent').append('\
      <div class="card rule" id="' + i + '">\
        <div class="card-body">\
          <div class="form-row align-items-center">\
            <div class="col-auto">\
              <input type="text" class="form-control" value="' + name + '" placeholder="Rule Name" id="name' + i + '">\
            </div>\
            <div class="col-auto">\
              <input type="text" class="form-control" value="' + extension + '" placeholder="File Extension" id="extension' + i + '">\
            </div>\
            <div class="col-auto">\
              <div class="form-check mb-2">\
                '+ checkbox +'\
                <label class="form-check-label" for="delete' + i + '">\
                  Delete Source\
                </label>\
              </div>\
            </div>\
          </div>\
          <br>\
          <div id="editor' + i + '" style="height: 250px; width: 100%"></div>\
        </div>\
      </div>\
      <br>\
    ').promise().done(function(){
        editor[i] = ace.edit('editor' + i);
        editor[i].setTheme('ace/theme/chrome');
        editor[i].session.setMode('ace/mode/sh');
        editor[i].$blockScrolling = Infinity;
        editor[i].setOptions({
          readOnly: false,
        });
        editor[i].setValue(command, -1);
    });
  });
  $('#pagefooter').append('<center><button type="button" class="btn btn-secondary btn-lg" onclick="addconfig()">+</button></center>');
});
// Add config rule slots to the page
function addconfig(){
  var rand = Math.random().toString(36).replace('0.', '');
  $('#pagecontent').append('\
    <div class="card rule" id="' + rand + '">\
      <div class="card-body">\
        <div class="form-row align-items-center">\
          <div class="col-auto">\
            <input type="text" class="form-control" placeholder="Rule Name" id="name' + rand + '">\
          </div>\
          <div class="col-auto">\
            <input type="text" class="form-control" placeholder="File Extension" id="extension' + rand + '">\
          </div>\
          <div class="col-auto">\
            <div class="form-check mb-2">\
              <input class="form-check-input" type="checkbox" id="delete' + rand + '">\
              <label class="form-check-label" for="delete' + rand + '">\
                Delete Source\
              </label>\
            </div>\
          </div>\
        </div>\
        <br>\
        <div id="editor' + rand + '" style="height: 250px; width: 100%"></div>\
      </div>\
    </div>\
    <br>\
  ').promise().done(function(){
      editor = ace.edit('editor' + rand);
      editor.setTheme('ace/theme/chrome');
      editor.session.setMode('ace/mode/sh');
      editor.$blockScrolling = Infinity;
      editor.setOptions({
        readOnly: false,
      });
  });
}
// Save all config data
function saveall(){
  var interval = $('#interval').val();
  var dataset = {'interval':interval,'commands':[]};
  var ids = $('.rule').map(function(){
      return this.id;
  }).get();
  $(ids).each(function(i,id){
    var name = $('#name' + id).val();
    var extension = $('#extension' + id).val();
    var cleanup = $('#delete' + id).prop('checked');
    var editor = ace.edit("editor" + id);
    var command = editor.getValue();
    var single_command = {'name':name,'extension':extension,'delete':cleanup,'command':command};
    dataset.commands.push(single_command);
  }).promise().done(function(){
    socket.emit('saveconfig',dataset);
  });
}


//// Terminal Page rendering ////
function renderterminal(){
  pagepurge();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getterminal');
}
socket.on('sendterminal', function(data){
  pagepurge();
  $('#pagecontent').append('<center>Raw bash terminal here for users to test commands</center>');
});

///////////////////////// test function client side //////////////////////////////////////
socket.on('testout', function(out){
  console.log(out);
});
///////////////////////// REMOVE FROM RELEASE ////////////////////////////////////////////

//// Command Page rendering ////
function rendercommands(){
  pagepurge();
  $('#pagecontent').append('<center><div class="spinner-border" style="width: 6rem; height: 6rem;"></div></center>');
  socket.emit('getcommands');
}
socket.on('sendcommands', function(categories){
  pagepurge();
  var editor = [];
  $('#pagecontent').append('<div id="cats"></div>')
  $(categories).each(function(i,data){
    var commands = data.commands;
    var cat = data.category;
    var catid = cat.replace(/ |\./g,'');
    $('#cats').append('\
      <div class="card">\
        <div class="card-header" id="' + catid + '" data-toggle="collapse" data-target="#' + catid + '_list" aria-expanded="true" aria-controls="' + catid + '_list">\
          ' + cat + '\
        </div>\
      </div>');
    $('#cats').append('\
      <div id="' + catid + '_list" class="collapse" aria-labelledby="' + catid + '" data-parent="#cats">\
        <div class="card-body btn-toolbar" id="' + catid + '_commands">\
        </div>\
      </div>').promise().done(
        function(){
        $(commands).each(function(i,data){
          var name = data.name;
          var nameid = name.replace(/ |\./g,'');
          var description = btoa(data.description);
          var command = btoa(data.command);
          $('#' + catid + '_commands').append('\
            <button type="button" \
              id="' + nameid + '_button" \
              data-toggle="modal" \
              data-target="#modal" \
              style="cursor:pointer;" \
              onclick="commandmodal(\'' + nameid + '\')"\
              class="btn btn-secondary btn-lg mx-auto" \
              data-name="' + name + '"\
              data-description="' + description + '"\
              data-command="' + command + '"\
              >' + name + '\
            </button>');
        });
      });
  });
});
function commandmodal(nameid){
  modalpurge();
  var name = $('#' + nameid + '_button').data('name')
  var description = atob($('#' + nameid + '_button').data('description'));
  var command = atob($('#' + nameid + '_button').data('command'));
  $('#modaltitle').append(name);
  $('#modalbody').append('<p>' + description + '</p>');
  $('#modalbody').append('<div id="editor" style="height: 250px; width: 100%"></div>'
    ).promise().done(function(){
        editor = ace.edit("editor");
        editor.setTheme("ace/theme/chrome");
        editor.session.setMode("ace/mode/sh");
        editor.$blockScrolling = Infinity;
        editor.setOptions({
          readOnly: true,
        });
        editor.setValue(command, -1);
    });
}



function modalpurge(){
  $('#modaltitle').empty();
  $('#modalbody').empty();
}
function pagepurge(){
  $('#headerform').empty();
  $('#pagecontent').empty();
  $('#pagefooter').empty();
}