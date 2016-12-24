export let noTransition = (elements, cb) => {
  elements.forEach((element) => {
    element.style.transitionProperty = "none";
  });
  window.requestAnimationFrame(() => {
    cb();
    window.requestAnimationFrame(() => {
      elements.forEach((element) => {
        element.style.transitionProperty = "";
      });
    });
  });
}
