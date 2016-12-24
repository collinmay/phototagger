export let noTransition = (elements, cb, after) => {
  elements.forEach((element) => {
    element.style.transitionProperty = "none";
  });
  window.requestAnimationFrame(() => {
    cb();
    window.requestAnimationFrame(() => {
      elements.forEach((element) => {
        element.style.transitionProperty = "";
      });
      if(after) {
        window.requestAnimationFrame(() => {
          after();
        });
      }
    });
  });
}
