import {noTransition} from "../util.js";

export class SwitcherView {
  constructor(container, initial) {
    this.container = container;
    this.container.appendChild(initial);
    this.current = initial;
    this.container.height = this.current.height;
  }

  switchIn(target, fromDir, toDir, warp) {
    if(warp) {
      while(this.container.hasChildNodes()) {
        this.container.removeChild(this.container.lastChild);
      }
      this.container.appendChild(target);
      this.current = target;
      noTransition([this.container], () => {
        this.container.style.height = getComputedStyle(this.current).height;
      });
      return;
    }
    this.container.appendChild(target);
    let originalClass = target.className;
    noTransition([target], () => {
      target.className+= " switcher-" + fromDir;
    }, () => {
      target.className = originalClass;
      let old = this.current;
      old.addEventListener("transitionend", () => {
        this.container.removeChild(old);
      }, true);
      old.className+= " switcher-" + toDir;
      this.current = target;
      this.container.style.height = getComputedStyle(this.current).height;
    });
  }  
}
