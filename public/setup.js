window.onload = function() {
  var byId = document.getElementById.bind(document);
  
  var currentStep = byId("begin");
  function activateStep(name) {
    currentStep.className = "step inactive";
    currentStep = byId(name);
    currentStep.className = "step active";
  }

  var steps = ["step1", "wsclose", "locked", "begin", "dbsetup", "step2"];
  steps.forEach(function(name) {
    var step = byId(name);
    step.addEventListener("animationend", function(e) {
      step.className = step.className.replace("shake", "");
    });
  });
  
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
              activateStep("step2");
            }
          }
          break;
        }
        break;
      }
    }
  };

  byId("dbConnect").disabled = false;
  
  window.connectDb = function() {
    console.log("Trying to connect to database...");
    var btn = byId("dbConnect");
    btn.disabled = true;
    btn.textContent = "Connecting...";
    ws.send(JSON.stringify({
      step: "step1",
      url: byId("dbUrl").value
    }));
  };

  window.runDbSetup = function() {
    console.log("Running db setup...");
    var btn = byId("dbSetupBtn");
    btn.disabled = true;
    btn.textContent = "Running...";
    ws.send(JSON.stringify({
      step: "dbsetup"
    }));
  };

  window.submitConfig = function() {
    console.log("submitting config...");
    let config = {
      singleUserMode: byId("config-singleuser").checked,
      photoProviders: {
        hotlink: byId("config-hotlinks").checked,
        upload: byId("config-uploads").checked,
        imgur: byId("config-imgur").checked,
        gphotos: byId("config-gphotos").checked
      },
      defaultPerms: {
        photoProviders: {
          hotlink: byId("config-usp-hotlink").checked,
          upload: byId("config-usp-upload").checked,
          imgur: byId("config-imgur").checked,
          gphotos: byId("config-gphotos").checked
        }
      }
    };
    ws.send(JSON.stringify({
      step: "step2",
      config: config
    }));
  };
  
  byId("config-singleuser").onclick = function(e) {
    if(e.target.checked) {
      byId("config-userperms-container").style.height = 0;
    } else {
      byId("config-userperms-container").style.height = getComputedStyle(byId("config-userperms")).height;
    }
  }
  byId("config-singleuser").checked = false;
  byId("config-userperms-container").style.height = getComputedStyle(byId("config-userperms")).height;
}
