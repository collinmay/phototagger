export class DialogViewManager {
  constructor() {
    this.container = document.getElementById("dialog-container");
    this.transitioner = document.getElementById("dialog-transitioner");
    this.activeDialog = null;
    this.exitingDialog = null;
    
    this.container.addEventListener("click", (e) => {
      if(e.target == this.container) {
        this.deactivate();
      }
    });

    this.container.addEventListener("transitionend", (e) => {
      if(!this.activeDialog) {
        this.container.className = "hidden";
      }
      console.log("A");
      if(this.exitingDialog) {
        console.log("B");
        this.exitingDialog.container.className = "dialog hidden";
        this.exitingDialog = null;
      }
    });
  }

  activate(dialog) {
    if(dialog == null) {
      this.deactivate();
    } else {
      if(this.activeDialog) {
        console.log("already have an active dialog, deactivating that one");
        this.activeDialog.container.className = "dialog";
        this.exitingDialog = this.activeDialog;
      }
      let newlyShowing = !this.activeDialog;
      console.log("newly showing: " + newlyShowing);
      this.activeDialog = dialog;
      if(newlyShowing) {
        this.container.className = "";
      }
      this.activeDialog.container.className = "dialog";
      
      window.setTimeout(() => {
        this.activeDialog.container.className = "dialog active";
        this.container.className = "active";
      }, 20);
    }
  }

  deactivate() {
    if(this.activeDialog) {
      this.activeDialog.container.className = "dialog";
      this.exitingDialog = this.activeDialog;
      this.container.className = "";
    } else {
      this.container.className = "hidden";
    }
    this.activeDialog = null;
  }

  transitionState(state, warp) {
    this.deactivate();
  }
};
