// Drawio
document$.subscribe(({ body }) => {
    GraphViewer.processElements()
})

// Wavedrom
window.addEventListener("load", function () {
    WaveDrom.ProcessAll();
});

// Mathjax
window.MathJax = {
    tex: {
        inlineMath: [["\\(", "\\)"]],
        displayMath: [["\\[", "\\]"]],
        processEscapes: true,
        processEnvironments: true
    },
    options: {
        ignoreHtmlClass: ".*|",
        processHtmlClass: "arithmatex"
    }
};
