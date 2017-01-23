function buildPermGroupCard(model) {
  var card = document.createElement("div"); card.className = "card mb-4";
  var header = document.createElement("div"); header.className = "card-header";
  var nav = document.createElement("ul"); nav.className = "nav nav-tabs card-header-tabs";
  var body = document.createElement("div"); body.className = "card-block";
  var footer = document.createElement("div"); footer.className = "card-footer text-muted";

  footer.textContent = "All changes have been committed.";
  
  card.appendChild(header);
  header.appendChild(nav);
  card.appendChild(body);
  card.appendChild(footer);

  var changeCounter = 0;

  model.ack = function() {
    changeCounter--;
    if(changeCounter <= 0) {
      footer.textContent = "All changes have been committed.";
      changeCounter = 0;
    }
  };
  
  function genContent(permNodes) {
    var form = document.createElement("form");
    permNodes.forEach(function(permNode) {
      var div = document.createElement("div"); div.className = "form-check";
      var label = document.createElement("label"); label.className = "form-check-label";
      var input = document.createElement("input"); input.className = "form-check-input";
      input.type = "checkbox";
      input.checked = model.nodeValues[permNode.id];
      input.onchange = function() {
        footer.textContent = "Committing changes...";
        changeCounter++;
        model.updateNode(permNode.id, input.checked);
      }
      
      var text = document.createTextNode(permNode.name);
      label.appendChild(input);
      label.appendChild(text);
      div.appendChild(label);
      form.appendChild(div);
    });
    return form;
  }
  
  var tabs = [{
    title: "Image Hosting Permissions",
    permNodes: [
      {"id": "host.upload", "name": "Can upload photos"},
      {"id": "host.hotlink", "name": "Can hotlink photos"},
      {"id": "host.imgur", "name": "Can import photos from imgur"},
      {"id": "host.gphotos", "name": "Can import photos from google photos"}
    ]
  }, {
    title: "Privacy Permissions",
    permNodes: [
      {"id": "privacy.photos.read.other", "name": "Can view other people's photos without consent"},
      {"id": "privacy.photos.update.other", "name": "Can manipulate other people's photos without consent"}
    ]
  }, {
    title: "Administrative Permissions",
    permNodes: [
      {"id": "admin.groups.update", "name": "Can manipulate permission groups"},
      {"id": "admin.groups.assign", "name": "Can reassign users to different groups"},
      {"id": "admin.user.delete", "name": "Can delete users"}
    ]
  }];

  var activeTab = tabs[0];
  
  tabs.forEach(function(tab) {
    var li = document.createElement("li"); li.className = "nav-item";
    var aTag = document.createElement("a"); aTag.className = "nav-link"; aTag.href = "#";
    li.appendChild(aTag);
    nav.appendChild(li);
    
    tab.aTag = aTag;
    aTag.textContent = tab.title;
    tab.content = genContent(tab.permNodes);
    
    aTag.onclick = function() {
      activeTab.aTag.className = "nav-link";
      aTag.className = "nav-link active";

      while(body.hasChildNodes()) {
        body.removeChild(body.childNodes[0]);
      }

      var h4 = document.createElement("h4"); h4.className = "card-title";
      h4.textContent = model.name;
      body.appendChild(h4);
      body.appendChild(tab.content);
      
      activeTab = tab;
    };
  });

  tabs[0].aTag.onclick(); // activate first tab

  return card;
}

window.onload = function() {
  var byId = document.getElementById.bind(document);
  
  var currentStep = byId("begin");
  function activateStep(name) {
    currentStep.className = "step inactive";
    currentStep = byId(name);
    currentStep.className = "step active";
  }

  var steps = ["step1", "wsclose", "locked", "begin", "dbsetup", "permgroup"];
  steps.forEach(function(name) {
    var step = byId(name);
    step.addEventListener("animationend", function(e) {
      step.className = step.className.replace("shake", "");
    });
  });

  var permgroupModels = [];
  
  window.attemptBegin = function() {
    console.log("Connecting websocket...");
    window.ws = new WebSocket("ws://" + window.location.host + window.location.pathname);
    ws.onopen = function() {
      var btn = byId("dbConnect");
      btn.disabled = false;
      btn.textContent = "Connect";
      btn = byId("dbSetupBtn");
      btn.disabled = false;
      btn.textContent = "Begin";
      btn = byId("permGroupSubmitBtn");
      btn.disabled = false;
      btn.textContent = "Submit";
      
      byId("dbsetupLog").textContent = "";
    }
    ws.onclose = function(e) {
      activateStep("wsclose");
      wsclose.className = "step active shake";
      console.log("websocket closed: " + e.reason + e.code);
    }
    ws.onmessage = function(msg) {
      var cmd = JSON.parse(msg.data);
      switch(cmd.type) {
      case "switch_step":
        activateStep(cmd.step);
        break;
      case "step_data":
        switch(cmd.step) {
        case "step1":
          byId("dbErrorLog").textContent = cmd.error;
          byId("step1").className = "step active shake";
          var btn = byId("dbConnect");
          btn.disabled = false;
          btn.textContent = "Connect";
          break;
        case "dbsetup":
          if(cmd.error) {
            byId("dbsetup").className = "step active shake";
            byId("dbsetupLog").textContent+= cmd.error;
            var btn = byId("dbSetupBtn");
            btn.textContent = "Errored!";
          } else {
            byId("dbsetupLog").textContent+= cmd.content;
          }
          if(cmd.finished) {
            var btn = byId("dbSetupBtn");
            btn.disabled = false;
            btn.textContent = "Next";
            btn.onclick = function() {
              activateStep("permgroup");
            }
          }
          break;
        case "permgroup":
          console.log("got permission groups");
          let pgContainer = byId("perm-groups-container");
          while(pgContainer.hasChildNodes()) {
            pgContainer.removeChild(pgContainer.childNodes[0]);
          }
          cmd.content.forEach(function(pg) {
            permgroupModels.push(pg);
            pg.updateNode = function(nodeId, value) {
              console.log("sending node update");
              ws.send(JSON.stringify({
                step: "permgroup",
                action: "update_node",
                id: pg.id,
                node: nodeId,
                permitted: value
              }));
            };
            pgContainer.appendChild(buildPermGroupCard(pg));
          });
          break;
        case "createadmin":
          console.log("got redirect: " + cmd.oauth_redirect);
          window.location = cmd.oauth_redirect;
          break;
        }
        break;
      case "permgroup_ack":
        permgroupModels.find((pg) => {
          return pg.id == cmd.pg;
        }).ack();
        break;
      }
    }
  };

  byId("dbConnect").disabled = false;
  byId("dbConnect").onclick = function() {
    console.log("Trying to connect to database...");
    var btn = byId("dbConnect");
    btn.disabled = true;
    btn.textContent = "Connecting...";
    ws.send(JSON.stringify({
      step: "step1",
      url: byId("dbUrl").value
    }));
  };

  byId("dbSetupBtn").onclick = function() {
    console.log("Running db setup...");
    var btn = byId("dbSetupBtn");
    btn.disabled = true;
    btn.textContent = "Running...";
    ws.send(JSON.stringify({
      step: "dbsetup"
    }));
  };

  byId("permGroupSubmitBtn").onclick = function() {
    var btn = byId("permGroupSubmitBtn");
    btn.disabled = true;
    ws.send(JSON.stringify({
      step: "permgroup",
      action: "submit"
    }));
  };

  byId("createAdminAuthBtn").onclick = function() {
    ws.send(JSON.stringify({
      step: "createadmin"
    }));
  };
}
